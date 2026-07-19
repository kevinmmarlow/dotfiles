#!/usr/bin/env bash
# Set up (or re-sync) this machine from the dotfiles repo. Idempotent: safe to
# re-run. Existing real files are backed up before being replaced by symlinks.
#
#   ~/.dotfiles/bootstrap.sh
#
# Steps: Homebrew -> brew bundle -> Oh My Zsh -> stow -> skills fork -> secrets.

set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP="$HOME/.dotfiles-backup-$(date +%Y%m%d-%H%M%S)"
SKILLS_REPO="git@github.com:kevinmmarlow/mp_skills.git"
SKILLS_DIR="$HOME/Development/claude/skills"
PACKAGES=(zsh git config claude)

log() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }

# --- Homebrew ---
if ! command -v brew >/dev/null; then
  log "Installing Homebrew"
  NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi
eval "$(/opt/homebrew/bin/brew shellenv)"

log "Installing packages from Brewfile"
brew bundle --file="$DOTFILES/Brewfile"

# --- Oh My Zsh (keep our .zshrc; the installer would otherwise replace it) ---
if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
  log "Installing Oh My Zsh"
  RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended --keep-zshrc
fi

# --- Stow: back up any conflicting real file, then symlink packages into $HOME ---
stow_package() {
  local pkg="$1"
  while IFS= read -r -d '' file; do
    local rel="${file#"$DOTFILES/$pkg/"}"
    local target="$HOME/$rel"
    if [[ -e "$target" && ! -L "$target" ]]; then
      mkdir -p "$BACKUP/$(dirname "$rel")"
      mv "$target" "$BACKUP/$rel"
      log "backed up $target -> $BACKUP/$rel"
    fi
  done < <(find "$DOTFILES/$pkg" -type f -print0)
  stow --dir="$DOTFILES" --target="$HOME" --restow "$pkg"
}

log "Stowing packages: ${PACKAGES[*]}"
for pkg in "${PACKAGES[@]}"; do stow_package "$pkg"; done

# --- Skills fork (source of truth for ~/.claude/skills + ~/.agents/skills) ---
if [[ ! -d "$SKILLS_DIR/.git" ]]; then
  log "Cloning skills fork -> $SKILLS_DIR"
  mkdir -p "$(dirname "$SKILLS_DIR")"
  git clone "$SKILLS_REPO" "$SKILLS_DIR"
fi
log "Linking skills into ~/.claude and ~/.agents"
"$SKILLS_DIR/scripts/link-skills.sh"

# --- Secrets: put refresh-secrets on PATH, then generate ~/.zsh/secrets.zsh ---
mkdir -p "$HOME/.local/bin"
ln -sfn "$DOTFILES/bin/refresh-secrets" "$HOME/.local/bin/refresh-secrets"
log "Fetching secrets from 1Password"
"$DOTFILES/bin/refresh-secrets"

log "Done. Backups (if any) in $BACKUP. Open a new shell to load everything."
