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
  programs.home-manager.enable = true;

  home.packages = with pkgs; [
    git
    fzf
    python3
  ];

  home.sessionPath = [ "$HOME/.local/bin" ];
  home.sessionVariables = {
    PYTHONPYCACHEPREFIX = "/tmp/pycache";
  };

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
      p3 = "type p3; python3";
      pv = "type pv; p3 -m venv .venv && . .venv/bin/activate";
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
      '')
    ];
  };
}
