# dotfiles - Zsh через Nix + Home Manager

Одна конфигурация Zsh для Debian, Ubuntu и macOS. Установка и обновление выполняются только вручную. Менеджеры плагинов Antidote и Oh My Zsh Installer не нужны: Home Manager устанавливает Oh My Zsh и все плагины из Nix-конфигурации.

## Что входит

- Oh My Zsh с темой `fino-time` и плагином `git`.
- `zsh-autosuggestions`, `fzf-zsh-plugin`, `zsh-syntax-highlighting`, `you-should-use`, `zsh-history-substring-search`, `command-time`.
- Nix-пакеты `fzf`, `git`, `python3`.
- Алиасы `p3`, `pv`, `PYTHONPYCACHEPREFIX=/tmp/pycache` и `~/.local/bin` в PATH (без дублей при повторных запусках).
- Плагин `autoupdate` из старой конфигурации не используется. Все версии фиксируются через `flake.lock`.

## Первый запуск на Linux (Debian/Ubuntu)

```bash
sudo apt update
sudo apt install -y curl git ca-certificates bash zsh
```

Установить Nix согласно [официальной инструкции](https://github.com/NixOS/nix-installer), включив flakes. Для поддерживаемых версий официальный установщик может выглядеть так:

```bash
curl -sSfL https://artifacts.nixos.org/nix-installer | sh -s -- install --enable-flakes
```

Перед запуском проверь адрес, содержимое и актуальность установщика. Если Nix уже установлен (в том числе Determinate Nix или существующий Nix daemon), пропусти этот шаг и не переустанавливай его. После установки открой новый терминал.

```bash
git clone https://github.com/OWNER/dotfiles.git ~/dotfiles
cd ~/dotfiles
bash scripts/apply.sh
exec zsh
```

`OWNER` заменяется на владельца созданного репозитория. Проверь настройки командой `bash ~/dotfiles/scripts/verify.sh`.

## Первый запуск на macOS

Если Git не установлен, выполни `xcode-select --install`. Установи Nix с включёнными flakes согласно [официальному руководству](https://github.com/NixOS/nix-installer); macOS может потребовать создания отдельного APFS-тома, которое выполняет установщик. Если Nix уже установлен, повторно его устанавливать не нужно. Открой новое окно Terminal.

```bash
git clone https://github.com/OWNER/dotfiles.git ~/dotfiles
cd ~/dotfiles
bash scripts/apply.sh
exec zsh
bash scripts/verify.sh
```

Поддерживаются Apple Silicon и Intel при наличии пакетов соответствующей платформы. Nix управляет домашними конфигурациями и не меняет системные настройки macOS: nix-darwin не требуется.

## Ручная синхронизация

На машине, где менялись файлы:

```bash
cd ~/dotfiles
# отредактировать home.nix
bash scripts/apply.sh
bash scripts/verify.sh
git add -A
git commit -m 'Update Zsh config'
git push
```

На любой другой машине по запросу пользователя:

```bash
cd ~/dotfiles
git pull --ff-only
bash scripts/apply.sh
exec zsh
```

Добавление Nix-плагина в `programs.zsh.plugins` или `programs.zsh.oh-my-zsh.plugins` автоматически устанавливает и подключает его при следующем `apply.sh`. Не нужно вручную клонировать плагины. Для внешнего плагина, объявленного новым flake input, обнови и закоммить `flake.lock`.

## Обновление версий программ и плагинов

Это отдельное действие, не выполняется при обычной синхронизации:

```bash
cd ~/dotfiles
nix flake update
bash scripts/apply.sh
bash scripts/verify.sh
git add flake.lock
git commit -m 'Update pinned dependencies'
git push
```

## Миграция с Oh My Zsh

Если есть старый `~/.zshrc`, сохрани его: `cp -p ~/.zshrc ~/.zshrc.pre-nix-backup`. Аналогично, если нужно, `cp -p ~/.zprofile ~/.zprofile.pre-nix-backup`. При конфликте активации Home Manager сначала переименуй старый файл, например `mv ~/.zshrc ~/.zshrc.pre-nix-backup`, затем повтори `bash scripts/apply.sh`. Не удаляй `~/.oh-my-zsh`: новая конфигурация от неё не зависит, и старую установку можно удалить позже. Если конфликтует другой существующий конфигурационный файл, сохрани его отдельно.

По умолчанию `apply.sh` не меняет login shell и `/etc/shells`. Для текущего терминала достаточно `exec zsh`; на новой Linux-машине по-прежнему может запускаться Bash. На macOS Zsh уже является login shell. На Linux изменение login shell через `chsh` делается отдельно, после проверки пути к Zsh и его наличия в `/etc/shells` (Zsh из Nix там автоматически не регистрируется).

## Проверка и диагностика

```bash
bash ~/dotfiles/scripts/verify.sh
zsh -lic 'echo $ZSH_THEME; command -v fzf; command -v python3'
```

`verify.sh` не требует терминала и не меняет данные: он проверяет тему, все плагины, их хуки, алиасы, переменные и PATH.

`command-time` сохраняет стандартный порог 3 секунды. Если нужен 1-минутный порог, добавь в `programs.zsh.initContent`:

```zsh
ZSH_COMMAND_TIME_MIN_SECONDS=60
```

`zsh-history-substring-search` подключён без назначения клавиш, как и в старом `.zshrc`. По желанию добавь в `programs.zsh.initContent`:

```zsh
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down
```

### Откат

Для возврата к старому `.zshrc` сначала сохрани текущую сгенерированную конфигурацию, затем удаляй лишь управляемую Home Manager ссылку (`rm ~/.zshrc` удаляет только симлинк) и восстанавливай `mv ~/.zshrc.pre-nix-backup ~/.zshrc`. По возможности используй rollback предыдущей генерации Home Manager: `nix profile` / `home-manager generations` покажут пути, затем запусти `<путь-генерации>/activate`. Не удаляй Nix Store и не очищай домашний каталог ради отката Zsh.

## Технические подробности

- `flake.lock` фиксирует версии Nixpkgs, Home Manager и внешних плагинов.
- `apply.sh` выбирает платформу по `uname`, а имя пользователя и HOME берёт из окружения текущего пользователя. Поэтому для Nix требуется `--impure`, но зафиксированные зависимости остаются неизменными.
- Порядок в сгенерированном `.zshrc` (по значениям `mkOrder` Home Manager release-26.05): `ZSH_DISABLE_COMPFIX` (550, до Oh My Zsh, иначе он не повлиял бы на `compinit`), autosuggestions (700), Oh My Zsh (800), плагины из `programs.zsh.plugins` (900), алиасы, PATH (1000), `zsh-syntax-highlighting` последним (1200). Менять порядок не потребовалось.
- `~/.local/bin` добавляется и через `home.sessionPath`, и в `.zshrc` при `typeset -U path`, поэтому дубликатов нет и каталог остаётся первым даже если login-shell переупорядочил PATH.
- `fzf` берётся из Nix и находится в PATH до загрузки `fzf-zsh-plugin`, поэтому плагин ничего не скачивает. При первом запуске плагин по-прежнему сам создаёт файл настроек `~/.fzf.zsh` (копия `fzf-settings.zsh`); это не загрузка и не конфликтует с Home Manager.
- Не включены фоновая синхронизация, cron, systemd timers или launchd jobs.
- Репозиторий не хранит токены, SSH-ключи и пароли.

## Статус тестирования

Честно о том, что проверено:

- Опции Home Manager `release-26.05` (`programs.zsh.initContent`, `plugins`, `oh-my-zsh`, `autosuggestion`, `syntaxHighlighting`) и порядок генерации `.zshrc` проверены чтением исходников модуля.
- Хуки `command-time`, `you-should-use`, функции `zsh-history-substring-search` и дедупликация PATH проверены в реальном Zsh на Linux на исходниках плагинов.
- **Не выполнено:** `nix flake lock`, `nix flake check`, `apply.sh` и сборка/активация на Debian 13 и macOS - в среде разработки не было доступа Nix к `api.github.com` и `channels.nixos.org`. Поэтому **`flake.lock` пока не создан**: выполни на машине с работающим Nix `nix flake lock --extra-experimental-features 'nix-command flakes'` и закоммить файл (`git add flake.lock`). Пути `pkgs.zsh-history-substring-search` и работа `fino-time` в Nix-сборке не проверялись на реальной сборке.
- macOS (Apple Silicon/Intel) и Intel Linux не тестировались.
