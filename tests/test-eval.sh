#!/usr/bin/env bash
set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
tmp="$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-test.XXXXXXXX")"
trap 'rm -rf -- "$tmp"' EXIT

export HOME="$tmp/home"
mkdir -p "$HOME"
ansible-playbook -i localhost, "$repo_dir/dotfiles.yml" --syntax-check
ansible-playbook -i localhost, "$repo_dir/dotfiles.yml" --tags config
ansible-playbook -i localhost, "$repo_dir/dotfiles.yml" --tags config | grep -q 'changed=0'
ansible-playbook -i localhost, "$repo_dir/dotfiles.yml" --tags packages --check \
  -e use_homebrew=false \
  -e "{\"ansible_facts\":{\"os_family\":\"Darwin\",\"user_id\":\"$(id -un)\"}}" \
  > "$tmp/no-homebrew"
grep -q 'Homebrew disabled; packages skipped:.*yazi' "$tmp/no-homebrew"
zsh -n "$HOME/.zshrc"

plugins="$HOME/.local/share/dotfiles"
mkdir -p "$plugins"/{oh-my-zsh,zsh-autosuggestions,fzf-zsh-plugin,you-should-use,zsh-history-substring-search,command-time,zsh-just-let-me-edit-my-files,zsh-syntax-highlighting}
touch "$plugins/oh-my-zsh/oh-my-zsh.sh" \
  "$plugins/zsh-autosuggestions/zsh-autosuggestions.zsh" \
  "$plugins/fzf-zsh-plugin/fzf-zsh-plugin.plugin.zsh" \
  "$plugins/you-should-use/you-should-use.plugin.zsh" \
  "$plugins/zsh-history-substring-search/zsh-history-substring-search.zsh" \
  "$plugins/command-time/command-time.plugin.zsh" \
  "$plugins/zsh-just-let-me-edit-my-files/zsh-just-let-me-edit-my-files.plugin.zsh" \
  "$plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
echo 'export DOTFILES_LOCAL_TEST=yes' > "$HOME/.zshrc.local"

mkdir -p "$tmp/input/.git" "$tmp/output"
printf 'hello\n' > "$tmp/input/test.txt"
printf 'ignored\n' > "$tmp/input/.git/ignored.txt"
printf '\000\001\002\003' > "$tmp/input/binary"
(
  cd "$tmp/input"
  zsh -ic '[[ $DOTFILES_LOCAL_TEST == yes ]] && alias ai p3 pv space upgrade >/dev/null && (( $+functions[mkcd] && $+functions[temp] && $+functions[bak] && $+functions[bat] )) && prompt txt' > "$tmp/prompt"
  zsh -ic 'prompt' > "$tmp/prompt-all"
)
grep -q 'test.txt' "$tmp/prompt"
! grep -q 'ignored.txt' "$tmp/prompt"
grep -q 'test.txt' "$tmp/prompt-all"
! grep -q 'binary' "$tmp/prompt-all"
! grep -q 'ignored.txt' "$tmp/prompt-all"
(
  cd "$tmp/output"
  zsh "$tmp/prompt"
)
cmp "$tmp/input/test.txt" "$tmp/output/test.txt"
