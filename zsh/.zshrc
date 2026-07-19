# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
# if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
#   source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
# fi

################ Path Definitions ################

# Path to your Oh My Zsh installation.
export ZSH="$HOME/.oh-my-zsh"

################ Shell Prompt ################

ZSH_THEME=""

# load custom executable functions
for function in ~/.zsh/functions/*; do
  source $function
done

# extra files in ~/.zsh/configs/pre , ~/.zsh/configs , and ~/.zsh/configs/post
# these are loaded first, second, and third, respectively.
_load_settings() {
  _dir="$1"
  if [ -d "$_dir" ]; then
    if [ -d "$_dir/pre" ]; then
      for config in "$_dir"/pre/**/*~*.zwc(N-.); do
        . $config
      done
    fi

    for config in "$_dir"/**/*(N-.); do
      case "$config" in
        "$_dir"/(pre|post)/*|*.zwc)
          :
          ;;
        *)
          . $config
          ;;
      esac
    done

    if [ -d "$_dir/post" ]; then
      for config in "$_dir"/post/**/*~*.zwc(N-.); do
        . $config
      done
    fi
  fi
}
_load_settings "$HOME/.zsh/configs"


# aliases
[[ -f ~/.aliases ]] && source ~/.aliases


zstyle ':omz:update' mode auto      # update automatically without asking

source $ZSH/oh-my-zsh.sh

# zsh-shift-select only binds into the emacs keymap, but bindkey -v (in
# ~/.zsh/configs/keybindings.zsh) makes viins the active one, so mirror the same
# sequences there. Table copied from zsh-shift-select.plugin.zsh.
() {
  emulate -L zsh
  local kcap seq seq_mac widget
  for  kcap   seq          seq_mac    widget (
    kLFT   '^[[1;2D'    x          backward-char
    kRIT   '^[[1;2C'    x          forward-char
    kri    '^[[1;2A'    x          up-line
    kind   '^[[1;2B'    x          down-line
    kHOM   '^[[1;2H'    x          beginning-of-line
    x      '^[[97;6u'   x          beginning-of-line
    kEND   '^[[1;2F'    x          end-of-line
    x      '^[[101;6u'  x          end-of-line
    x      '^[[1;6D'    '^[[1;4D'  backward-word
    x      '^[[1;6C'    '^[[1;4C'  forward-word
    x      '^[[1;6H'    '^[[1;4H'  beginning-of-buffer
    x      '^[[1;6F'    '^[[1;4F'  end-of-buffer
  ); do
    [[ "$OSTYPE" = darwin* && "$seq_mac" != x ]] && seq=$seq_mac
    bindkey -M viins ${terminfo[$kcap]:-$seq} shift-select::$widget
  done
}

# Colorise the top Tabs of Iterm2 with the same color as background
# Just change the 18/26/33 wich are the rgb values
echo -e "\033]6;1;bg;red;brightness;18\a"
echo -e "\033]6;1;bg;green;brightness;26\a"
echo -e "\033]6;1;bg;blue;brightness;33\a"

## iTerm integration
test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh"

# Set up fzf key bindings and fuzzy completion
source <(fzf --zsh)

ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=10"
# pnpm
export PNPM_HOME="/Users/kevinmarlow/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end


. "$HOME/.cargo/env"


export JAVA_HOME="/opt/homebrew/opt/openjdk@21"
export PATH="$JAVA_HOME/bin:$PATH"

export ANDROID_HOME=$HOME/Library/Android/sdk
export PATH=$PATH:$ANDROID_HOME/platform-tools
export PATH=$PATH:$ANDROID_HOME/tools
export PATH=$PATH:$ANDROID_HOME/tools/bin
export PATH=$PATH:$ANDROID_HOME/emulator
# Added by Windsurf
export PATH="/Users/kevinmarlow/.codeium/windsurf/bin:$PATH"

ulimit -n 8192
# bun completions
[ -s "/Users/kevinmarlow/.bun/_bun" ] && source "/Users/kevinmarlow/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# Orbstack
source ~/.orbstack/shell/init.zsh 2>/dev/null || :

# Go
export GOBIN=$HOME/bin
export PATH=$(go env GOBIN):$PATH

. "$HOME/.local/bin/env"

# Work (AngelList) config: tracked but machine-specific, absent on personal machines.
[[ -f ~/.zsh/work.zsh ]] && source ~/.zsh/work.zsh

# Secrets: generated from 1Password by `refresh-secrets`. Gitignored, never
# committed; rerun refresh-secrets after rotating a key.
[[ -f ~/.zsh/secrets.zsh ]] && source ~/.zsh/secrets.zsh

eval "$(zoxide init zsh)"

eval "$(starship init zsh)"
