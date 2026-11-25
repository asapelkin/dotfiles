# dotfiles

## Linux (Debian/Ubuntu)

```bash
sudo apt update
sudo apt install -y ansible git curl ca-certificates file unzip
ansible-pull -U https://github.com/asapelkin/dotfiles.git -K dotfiles.yml
exec zsh
```

Пакеты устанавливаются из apt; отсутствующие в репозитории apt - из Homebrew.
Homebrew устанавливается автоматически, если его нет.

Чтобы не устанавливать и не использовать Homebrew в playbook:

```bash
ansible-pull -U https://github.com/asapelkin/dotfiles.git -K -e use_homebrew=false dotfiles.yml
```

Недоступные в apt пакеты будут перечислены и пропущены. Флаг не удаляет уже
установленный Homebrew и не меняет `PATH`. Его нужно передавать при каждом запуске.

## macOS

```bash
xcode-select --install
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
eval "$(/opt/homebrew/bin/brew shellenv)" # Intel: /usr/local/bin/brew
brew install ansible git
ansible-pull -U https://github.com/asapelkin/dotfiles.git dotfiles.yml
exec zsh
```

Пропустите установку Homebrew, если он уже установлен.
При `-e use_homebrew=false` playbook не устанавливает пакеты и на macOS.

## GitHub mirror

По умолчанию Zsh-плагины устанавливаются и обновляются через Git.

Если задана переменная окружения `GITHUB_MIRROR`, плагины скачиваются
в виде ZIP-архивов с указанного зеркала.

```bash
export GITHUB_MIRROR=https://mirror.example.com/github
ansible-playbook -K dotfiles.yml
exec zsh
```

## Переход с Home Manager

До запуска Ansible найдите ссылки Home Manager в домашнем каталоге:

```bash
find "$HOME" -type l -exec sh -c '
  for f do
    target=$(readlink "$f") || continue
    case "$target" in
      /nix/store/*-home-manager-files/*) printf "%s -> %s\n" "$f" "$target" ;;
    esac
  done
' sh {} +
```

Проверьте список и удалите **только ссылки от старой конфигурации**,
например `~/.zshrc`, `~/.zshenv`, `~/.zprofile`, по одной:

```bash
rm -i "$HOME/.zshrc"
```

Если Ansible уже запущен, не удаляйте созданный им обычный `.zshrc`.
Не удаляйте `.zshrc.local` и `.zsh_history`. Старые файлы, сохранённые Home
Manager с расширением `.backup`, можно проверить и восстановить вручную.

Пакеты старой конфигурации могут оставаться в профиле Nix и опережать системные
в `PATH`. Проверьте `nix profile list` (либо `nix-env -q` для старого профиля).
Если `home-manager-path` относится именно к этой конфигурации и больше не нужен,
удалите его через `nix profile remove home-manager-path` или, для старого
профиля, `nix-env -e home-manager-path`. Затем начните новый сеанс оболочки.
Это не удаляет сам Nix; старые поколения и файлы в Nix store остаются.

## Обновление уже настроенной машины

```bash
ansible-pull -U https://github.com/asapelkin/dotfiles.git -K dotfiles.yml
exec zsh
```

На macOS `-K` не требуется.

Для локального репозитория:

```bash
ansible-playbook -K dotfiles.yml
exec zsh
```

Для машины с GitHub-зеркалом:

```bash
GITHUB_MIRROR=https://mirror.example.com/github \
  ansible-playbook -K -e use_homebrew=false dotfiles.yml
```

Существующий `.zshrc` сохраняется в резервной копии; локальные настройки
можно поместить в `~/.zshrc.local`.

## Проверка

```bash
ansible-playbook --syntax-check dotfiles.yml
tests/test-eval.sh
```
