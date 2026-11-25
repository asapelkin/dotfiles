export PYTHONPYCACHEPREFIX=/tmp/pycache
export NIXPKGS_ALLOW_UNFREE=1
export VISUAL=vim EDITOR=vim
export LC_ALL=en_US.UTF-8
typeset -U path
path=("$HOME/.local/bin" /home/linuxbrew/.linuxbrew/bin /opt/homebrew/bin /opt/homebrew/sbin $path)

HISTFILE="$HOME/.zsh_history"
HISTSIZE=999999999
SAVEHIST=999999999
setopt extended_history share_history hist_expire_dups_first hist_ignore_dups hist_ignore_space hist_verify

ZSH_DISABLE_COMPFIX=true
ZSH="$HOME/.local/share/dotfiles/oh-my-zsh"
ZSH_THEME=fino-time
plugins=(git)
if (( $+commands[fdfind] )); then
  alias fd=fdfind
fi
source "$HOME/.local/share/dotfiles/zsh-autosuggestions/zsh-autosuggestions.zsh"
source "$ZSH/oh-my-zsh.sh"
source "$HOME/.local/share/dotfiles/fzf-zsh-plugin/fzf-zsh-plugin.plugin.zsh"
source "$HOME/.local/share/dotfiles/you-should-use/you-should-use.plugin.zsh"
source "$HOME/.local/share/dotfiles/zsh-history-substring-search/zsh-history-substring-search.zsh"
source "$HOME/.local/share/dotfiles/command-time/command-time.plugin.zsh"
source "$HOME/.local/share/dotfiles/zsh-just-let-me-edit-my-files/zsh-just-let-me-edit-my-files.plugin.zsh"

alias ai='aichat'
alias p3='type p3; python3'
alias pv='type pv; p3 -m venv .venv && . .venv/bin/activate'
alias space='lsblk -e7 -o NAME,TYPE,SIZE,FSAVAIL,MOUNTPOINTS'
alias upgrade='export KESL_EULA_AGREED=Yes && export KESL_PRIVACY_POLICY_AGREED=Yes && export KESL_USE_KSN=Yes && sudo --preserve-env=KESL_EULA_AGREED,KESL_PRIVACY_POLICY_AGREED,KESL_USE_KSN bash -c "apt update && apt upgrade && apt dist-upgrade && apt autoremove"'

parse_git_dirty() { :; }
path=("$HOME/.local/bin" $path)

mkcd() {
  mkdir -p "$1"
  cd "$1"
}

temp() {
  cd "$(mktemp -d)"
  chmod -R 0700 .
  if [[ $# -eq 1 ]]; then
    mkdir -p "$1"
    cd "$1"
    chmod -R 0700 .
  fi
}

prompt() {
  local include_all_text=false
  local find_args=()
  local first=true

  local ignored_dirs=(
    node_modules .git .venv venv __pycache__ .pytest_cache .mypy_cache
    .ruff_cache .tox .nox .cache .next .nuxt .turbo .gradle .idea
    dist build target coverage
  )

  local prune_args=()
  for dir in "${ignored_dirs[@]}"
  do
    if [ "${#prune_args[@]}" -gt 0 ]; then
      prune_args+=(-o)
    fi
    prune_args+=(-name "$dir")
  done

  shell_quote() {
    printf '%s' "${(qq)1}"
  }

  emit_file() {
    local f="$1"
    local rel="${f#./}"
    local dir
    dir="$(dirname "$rel")"

    local hash
    hash="$(printf "%s" "$rel" | cksum | awk '{print $1}')"
    local delim="__PROMPT_FILE_${hash}__"
    local n=0

    while grep -qxF "$delim" "$f" 2>/dev/null
    do
      n=$((n + 1))
      delim="__PROMPT_FILE_${n}_${hash}__"
    done

    printf 'mkdir -p -- %s\n' "$(shell_quote "$dir")"
    printf "cat > %s <<'%s'\n" "$(shell_quote "$rel")" "$delim"
    cat "$f"
    if [ -s "$f" ]; then
      local last_byte
      last_byte="$(tail -c 1 "$f" | od -An -tx1 | tr -d '[:space:]')"
      if [ "$last_byte" != "0a" ]; then
        printf '\n'
      fi
    fi
    printf '%s\n\n' "$delim"
  }

  emit_prompt_function() {
    typeset -f prompt
    printf '\n\n'
  }

  emit_prompt_function
  if [ "$#" -eq 0 ]; then
    include_all_text=true
  else
    for ext in "$@"
    do
      if [ "$first" = true ]; then
        first=false
      else
        find_args+=(-o)
      fi
      find_args+=(-name "*.${ext}")
    done
  fi

  if [ "$include_all_text" = true ]; then
    local file_mime_opt=-bi
    [[ $OSTYPE == darwin* ]] && file_mime_opt=-bI
    find . -type d \( "${prune_args[@]}" \) -prune -o -type f -print0 |
    while IFS= read -r -d "" f
    do
      if file "$file_mime_opt" "$f" | grep -q '^text/'; then
        emit_file "$f"
      fi
    done
  else
    find . -type d \( "${prune_args[@]}" \) -prune -o -type f \( "${find_args[@]}" \) -print0 |
    while IFS= read -r -d "" f
    do
      emit_file "$f"
    done
  fi
}

bak() {
  cp "$1" "$1".bak
}

bat() {
  if (( $+commands[batcat] )); then
    command batcat --paging=never --style=plain "$@"
  else
    command bat --paging=never --style=plain "$@"
  fi
}

[ -f "$HOME/.zshrc.local" ] && source "$HOME/.zshrc.local"
source "$HOME/.local/share/dotfiles/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
