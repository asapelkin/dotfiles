{
  description = "Portable Zsh configuration for Linux and macOS";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    fzf-zsh-plugin = {
      url = "github:unixorn/fzf-zsh-plugin";
      flake = false;
    };
    you-should-use = {
      url = "github:MichaelAquilina/zsh-you-should-use";
      flake = false;
    };
    command-time = {
      url = "github:popstas/zsh-command-time";
      flake = false;
    };
  };

  outputs = inputs@{ nixpkgs, home-manager, ... }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
        "x86_64-darwin"
      ];
      forAllSystems = f:
        builtins.listToAttrs (map (system: {
          name = system;
          value = f system;
        }) systems);
    in
    rec {
      homeConfigurations = forAllSystems (system:
        home-manager.lib.homeManagerConfiguration {
          pkgs = import nixpkgs { inherit system; };
          extraSpecialArgs = { inherit inputs; };
          modules = [ ./home.nix ];
        });

      # nix run --impure github:asapelkin/dotfiles#apply
      apps = forAllSystems (system:
        let
          pkgs = import nixpkgs { inherit system; };
          apply = pkgs.writeShellScript "apply" ''
            set -euo pipefail
            if [ "$(id -u)" -eq 0 ]; then
              echo 'Do not run as root.' >&2
              exit 1
            fi
            echo "Applying Home Manager configuration (${system}) for $USER in $HOME"
            ${homeConfigurations.${system}.activationPackage}/activate
            echo 'Applied. Start a new Zsh session (exec zsh).'
          '';
        in
        {
          apply = {
            type = "app";
            program = "${apply}";
          };
          default = {
            type = "app";
            program = "${apply}";
          };
        });
    };
}
