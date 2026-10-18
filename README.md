# dotfiles

## Linux (Debian/Ubuntu)

```bash
sudo apt update
sudo apt install -y curl git ca-certificates bash zsh
curl -sSfL https://artifacts.nixos.org/nix-installer | sh -s -- install --enable-flakes
# открыть новый терминал
git clone https://github.com/OWNER/dotfiles.git ~/dotfiles
cd ~/dotfiles
bash scripts/apply.sh
exec zsh
```

## macOS

```bash
xcode-select --install
curl -sSfL https://artifacts.nixos.org/nix-installer | sh -s -- install --enable-flakes
# открыть новый терминал
git clone https://github.com/OWNER/dotfiles.git ~/dotfiles
cd ~/dotfiles
bash scripts/apply.sh
exec zsh
```
