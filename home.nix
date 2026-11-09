{ config, lib, pkgs, inputs, ... }:
let
  username = builtins.getEnv "USER";
  homedir = builtins.getEnv "HOME";
  requireUser =
    if username == "" || homedir == "" || username == "root"
    then throw "Set USER and HOME and run as the intended non-root user with --impure"
    else null;
in
{
  assertions = [
    {
      assertion = builtins.seq requireUser true;
      message = "HOME and USER must refer to a non-root user";
    }
  ];

  home.username = username;
  home.homeDirectory = homedir;
  home.stateVersion = "26.05";
  home-manager.backupFileExtension = "backup";
  programs.home-manager.enable = true;

  home.packages = with pkgs; [
    git
    fzf
    python3
    nodejs
    vim
  ];

  home.sessionVariables = {
    PYTHONPYCACHEPREFIX = "/tmp/pycache";
    NIXPKGS_ALLOW_UNFREE = "1";
    VISUAL = "vim";
    EDITOR = "vim";
    LC_ALL = "en_US.utf8";
  };

  home.sessionPath = [ "$HOME/.local/bin" "/home/linuxbrew/.linuxbrew/bin" ];

  # Homebrew is not in nixpkgs; install it with the official script if missing.
  home.activation.installBrew = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if [ ! -x /home/linuxbrew/.linuxbrew/bin/brew ] && [ ! -x /opt/homebrew/bin/brew ] && [ ! -x /usr/local/bin/brew ]; then
      PATH="${lib.makeBinPath [ pkgs.curl pkgs.git pkgs.bash pkgs.coreutils ]}:$PATH" \
      NONINTERACTIVE=1 \
        ${pkgs.bash}/bin/bash -c "$(${pkgs.curl}/bin/curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" \
        || echo "Homebrew install failed (needs sudo); install manually." >&2
    fi
  '';

  programs.zsh = {
    enable = true;
    enableCompletion = true;

    oh-my-zsh = {
      enable = true;
      theme = "fino-time";
      plugins = [ "git" ];
    };

    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    history = {
      path = "$HOME/.zsh_hist";
      size = 999999999;
      save = 999999999;
    };

    # Home Manager emits .zshrc sections by order: autosuggestions (700), Oh My
    # Zsh (800), custom plugins (900), initContent (1000), and
    # zsh-syntax-highlighting last (1200).
    plugins = [
      {
        name = "fzf-zsh-plugin";
        src = inputs.fzf-zsh-plugin;
        file = "fzf-zsh-plugin.plugin.zsh";
      }
      {
        name = "you-should-use";
        src = inputs.you-should-use;
        file = "you-should-use.plugin.zsh";
      }
      {
        name = "zsh-history-substring-search";
        src = pkgs.zsh-history-substring-search;
        file = "share/zsh-history-substring-search/zsh-history-substring-search.zsh";
      }
      {
        name = "command-time";
        src = inputs.command-time;
        file = "command-time.plugin.zsh";
      }
    ];

    shellAliases = {
      ai = "aichat";
      p3 = "type p3; python3";
      pv = "type pv; p3 -m venv .venv && . .venv/bin/activate";
      space = "lsblk -e7 -o NAME,TYPE,SIZE,FSAVAIL,MOUNTPOINTS";
      upgrade = ''export KESL_EULA_AGREED=Yes && export KESL_PRIVACY_POLICY_AGREED=Yes && export KESL_USE_KSN=Yes && sudo --preserve-env=KESL_EULA_AGREED,KESL_PRIVACY_POLICY_AGREED,KESL_USE_KSN bash -c "apt update && apt upgrade && apt dist-upgrade && apt autoremove"'';
    };

    initContent = lib.mkMerge [
      # Must run before Oh My Zsh (order 800) calls compinit.
      (lib.mkOrder 550 ''
        ZSH_DISABLE_COMPFIX="true"
      '')
      # `typeset -U path` is set earlier (order 510), so repeated startups
      # cannot duplicate this entry. Kept here because session variables are
      # only sourced once per environment and may be reordered by login shells.
      (lib.mkOrder 1000 ''
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
            node_modules
            .git
            .venv
            venv
            __pycache__
            .pytest_cache
            .mypy_cache
            .ruff_cache
            .tox
            .nox
            .cache
            .next
            .nuxt
            .turbo
            .gradle
            .idea
            dist
            build
            target
            coverage
          )

          local prune_args=()
          for dir in "''${ignored_dirs[@]}"
          do
            if [ "''${#prune_args[@]}" -gt 0 ]; then
              prune_args+=(-o)
            fi
            prune_args+=(-name "$dir")
          done

          shell_quote() {
            printf '%s' "'" && printf "%s" "$1" | sed "s/'/'\\\\''/g" && printf '%s' "'"
          }

          emit_file() {
            local f="$1"
            local rel="''${f#./}"
            local dir
            dir="$(dirname -- "$rel")"

            local hash
            hash="$(printf "%s" "$rel" | cksum | awk '{print $1}')"
            local delim="__PROMPT_FILE_''${hash}__"
            local n=0

            while grep -qxF "$delim" "$f" 2>/dev/null
            do
              n=$((n + 1))
              delim="__PROMPT_FILE_''${n}_''${hash}__"
            done

            printf 'mkdir -p -- %s\n' "$(shell_quote "$dir")"
            printf 'cat > %s <<'\''%s'\''\n' "$(shell_quote "$rel")" "$delim"

            cat "$f"

            if [ -s "$f" ]; then
              local last_byte
              last_byte="$(tail -c 1 -- "$f" | od -An -tx1 | tr -d '[:space:]')"

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

              find_args+=(-name "*.''${ext}")
            done
          fi

          if [ "$include_all_text" = true ]; then
            find . -type d \( "''${prune_args[@]}" \) -prune -o -type f -print0 |
            while IFS= read -r -d "" f
            do
              if file --mime-type -b "$f" | grep -q '^text/'; then
                emit_file "$f"
              fi
            done
          else
            find . -type d \( "''${prune_args[@]}" \) -prune -o -type f \( "''${find_args[@]}" \) -print0 |
            while IFS= read -r -d "" f
            do
              emit_file "$f"
            done
          fi
        }
      '')
    ];
  };
}
