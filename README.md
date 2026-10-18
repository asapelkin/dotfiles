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

## Обновление уже настроенной машины (Linux и macOS)

```bash
cd ~/dotfiles
git pull --ff-only
bash scripts/apply.sh
exec zsh
```

Обновление версий пакетов и плагинов (отдельно, на одной машине):

```bash
cd ~/dotfiles
nix flake update
bash scripts/apply.sh
git add flake.lock
git commit -m 'Update pinned dependencies'
git push
```
