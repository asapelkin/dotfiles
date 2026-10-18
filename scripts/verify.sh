#!/usr/bin/env bash
set -euo pipefail

echo 'System:'
uname -sm
echo 'Installed tools:'
command -v nix
command -v zsh
command -v fzf
command -v python3

echo 'Check generated Zsh settings and plugins:'
# No terminal is required; the interactive shell only reads the generated config.
zsh -ic '
  fail() { print -r -- "FAIL: $1" >&2; exit 1; }

  print -r -- "ZSH_THEME=${ZSH_THEME:-unset}"
  print -r -- "PYTHONPYCACHEPREFIX=${PYTHONPYCACHEPREFIX:-unset}"
  print -r -- "ZSH_COMMAND_TIME_MIN_SECONDS=${ZSH_COMMAND_TIME_MIN_SECONDS:-3(default)}"
  alias p3
  alias pv
  whence -w fzf

  [[ "${ZSH_THEME:-}" == fino-time ]] || fail "ZSH_THEME is not fino-time"
  [[ -f "$ZSH/themes/fino-time.zsh-theme" ]] || fail "fino-time theme file missing"
  [[ "${ZSH_DISABLE_COMPFIX:-}" == true ]] || fail "ZSH_DISABLE_COMPFIX not set"
  [[ "${PYTHONPYCACHEPREFIX:-}" == /tmp/pycache ]] || fail "PYTHONPYCACHEPREFIX"
  [[ "$(alias p3)" == *"type p3; python3"* ]] || fail "alias p3"
  [[ "$(alias pv)" == *"type pv; p3 -m venv .venv && . .venv/bin/activate"* ]] || fail "alias pv"

  # PATH: ~/.local/bin is present exactly once
  local -i n=${#${(M)path:#$HOME/.local/bin}}
  (( n == 1 )) || fail "~/.local/bin appears $n times in PATH"

  # fzf comes from Nix, not from a downloaded copy in ~/.fzf
  [[ "$(command -v fzf)" == /nix/store/* || "$(command -v fzf)" == *"/.nix-profile/"* || "$(command -v fzf)" == *"/etc/profiles/"* || "$(command -v fzf)" == *"/profiles/"* ]] || fail "fzf is not Nix-managed: $(command -v fzf)"

  # Plugins
  (( ${+aliases[gst]} )) || fail "oh-my-zsh git plugin not loaded"
  (( ${+functions[_zsh_autosuggest_start]} )) || fail "zsh-autosuggestions not loaded"
  (( ${+functions[_fzf_has]} )) || fail "fzf-zsh-plugin not loaded"
  (( ${+functions[_zsh_highlight]} )) || fail "zsh-syntax-highlighting not loaded"
  (( ${+functions[_check_aliases]} )) || fail "you-should-use not loaded"
  (( ${+functions[history-substring-search-up]} )) || fail "zsh-history-substring-search not loaded"
  (( ${+functions[_command_time_preexec]} )) || fail "command-time not loaded"
  (( ${preexec_functions[(Ie)_command_time_preexec]} )) || fail "command-time hook not registered"
  (( ${preexec_functions[(Ie)_check_aliases]} )) || fail "you-should-use hook not registered"
  [[ ! -e "${ZSH_CUSTOM:-$ZSH/custom}/plugins/autoupdate" ]] || fail "autoupdate must not be installed"
'
echo 'Shell checks passed.'
