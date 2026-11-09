#!/usr/bin/env bash
set -exuo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

docker run --rm -v "$repo_dir:/workspace:ro" -w /workspace \
-e USER=dotfiles-test -e HOME=/tmp/dotfiles-test nixos/nix:latest \
nix eval --impure --extra-experimental-features 'nix-command flakes' --raw \
--expr 'let flake = builtins.getFlake (toString ./.); in flake.apps.${builtins.currentSystem}.apply.program'

printf '\n'