#!/usr/bin/env bash
set -euo pipefail

if ! command -v nix >/dev/null 2>&1; then
  echo 'Nix is not installed. Install Nix first (see README.md).' >&2
  exit 1
fi

if [[ "$(id -u)" -eq 0 ]]; then
  echo 'Do not run this script as root.' >&2
  exit 1
fi

repo_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_dir"

case "$(uname -s)" in
  Linux)  os=linux ;;
  Darwin) os=darwin ;;
  *) echo "Unsupported OS: $(uname -s)" >&2; exit 1 ;;
esac

case "$(uname -m)" in
  x86_64|amd64) arch=x86_64 ;;
  aarch64|arm64) arch=aarch64 ;;
  *) echo "Unsupported architecture: $(uname -m)" >&2; exit 1 ;;
esac

system="${arch}-${os}"
echo "Applying locked Home Manager configuration: $system for ${USER:-unknown} in $HOME"

# Impure evaluation is only for USER/HOME. Package versions stay pinned.
nix build --impure --extra-experimental-features 'nix-command flakes' \
  ".#homeConfigurations.${system}.activationPackage"

"$repo_dir/result/activate"

echo 'Applied. Start a new Zsh session (exec zsh).'
