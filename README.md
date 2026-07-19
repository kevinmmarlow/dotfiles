# dotfiles

Personal macOS dotfiles, managed with [GNU Stow](https://www.gnu.org/software/stow/).
Each top-level directory is a stow "package" whose contents mirror `$HOME`.

## Layout

| Package  | Symlinks into                                        |
| -------- | ---------------------------------------------------- |
| `zsh`    | `~/.zshrc`, `~/.aliases`, `~/.zsh/{functions,configs,completion,work.zsh}` |
| `git`    | `~/.gitconfig`, `~/.gitignore`                       |
| `config` | `~/.config/{starship.toml,wezterm,themes,ccstatusline,neofetch,direnv,git}` |
| `claude` | `~/.claude/{CLAUDE.md,settings.json,hooks,statusline-*.sh,plugins/*}` |

`Brewfile`, `bootstrap.sh`, and `bin/` sit at the root and are not stowed.

## New machine

```sh
git clone git@github.com:<you>/dotfiles.git ~/.dotfiles
~/.dotfiles/bootstrap.sh
```

`bootstrap.sh` is idempotent: Homebrew, `brew bundle`, Oh My Zsh, `stow`, the
skills fork, and secrets. Any pre-existing real file is backed up to
`~/.dotfiles-backup-<timestamp>/` before a symlink replaces it.

## Secrets

Never committed. `bin/refresh-secrets` reads them from 1Password (`op`) once and
writes `~/.zsh/secrets.zsh` (gitignored, `chmod 600`), which `~/.zshrc` sources.
Shells never call `op` at startup. Re-run after rotating a key:

```sh
refresh-secrets
```

## Skills

`~/.claude/skills` and `~/.agents/skills` are symlinks into a separate fork
(`kevinmmarlow/mp_skills`), not tracked here. `bootstrap.sh` clones it to
`~/Development/claude/skills` and runs its `scripts/link-skills.sh`. Update with
`git -C ~/Development/claude/skills pull`.

## Work config

AngelList-specific shell config lives in `~/.zsh/work.zsh` (sourced after Oh My
Zsh). On a personal machine, delete that file or skip stowing it.

## Themes

`theme` (a zsh function) switches WezTerm + Starship themes together. The active
choice is stored in `~/.config/themes/current` (gitignored, per machine); a fresh
machine defaults to `rose-pine-moon`.

## Caveats

`~/.zshrc` assumes some tooling is present (rust/cargo, go, `al`, uv). `bootstrap.sh`
installs the Homebrew set; language runtimes (`asdf`, rust) and the `al` CLI are
installed per-project or by hand.
