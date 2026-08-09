# Curated package manifest. Install with `brew bundle --file=~/.dotfiles/Brewfile`
# (bootstrap.sh does this). Deliberately hand-maintained, not a `brew bundle dump`,
# so machine cruft stays out.

tap "withgraphite/tap"

# --- Requested toolchain ---
brew "asdf"                      # runtime version manager (versions live per-project in .tool-versions)
brew "bat"
brew "curl"
brew "direnv"
brew "fzf"
brew "gh"
brew "git"
brew "htop"
brew "just"
brew "lazygit"
brew "neovim"
brew "nginx"
brew "pnpm"
brew "sesh"
brew "starship"
brew "withgraphite/tap/graphite" # `gt`
brew "zoxide"
brew "zsh"

# --- Hard dependencies of these dotfiles ---
brew "stow"                      # symlinks packages into $HOME
brew "jq"                        # used by bin/refresh-secrets
brew "1password-cli"             # `op`; refresh-secrets reads secrets from it

cask "kitty"
cask "wezterm"
cask "font-hack-nerd-font"       # wezterm.lua + kitty.conf font

# Not managed here (install manually if missing):
#   - 1Password desktop app (git SSH signing agent; see ~/.gitconfig gpg.ssh.program)
#   - Oh My Zsh (bootstrap.sh installs it via the upstream script)
