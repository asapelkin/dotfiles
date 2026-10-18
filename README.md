# dotfiles

## Linux (Debian/Ubuntu)

```bash
sudo apt update
sudo apt install -y curl git ca-certificates bash zsh
curl -sSfL https://artifacts.nixos.org/nix-installer | sh -s -- install --enable-flakes
. /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
nix run --impure --extra-experimental-features 'nix-command flakes' github:asapelkin/dotfiles#apply
exec zsh
```

## macOS

```bash
xcode-select --install
curl -sSfL https://artifacts.nixos.org/nix-installer | sh -s -- install --enable-flakes
. /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
nix run --impure --extra-experimental-features 'nix-command flakes' github:asapelkin/dotfiles#apply
exec zsh
```

## Обновление уже настроенной машины (Linux и macOS)

```bash
nix run --impure --refresh github:asapelkin/dotfiles#apply
exec zsh
```
