# AngelList (work) shell config. Tracked, but only meaningful on AngelList
# machines; sourced from ~/.zshrc after Oh My Zsh so `compdef` exists for the
# `al` completions. Delete this file (or don't stow it) on a personal machine.

# Go modules served from the private org
export GOPRIVATE=github.com/angellist/*

# Default AWS profile for SSO / EKS access
export AWS_PROFILE=angellist-venture-prod-engineer

# `al` CLI completions (guarded so a machine without `al` doesn't error)
command -v al >/dev/null && source <(al completion zsh)

# Flags `al console` prod/staging sessions in both terminals. WezTerm reads the
# OSC 1337 user var and swaps the whole window's color scheme. Kitty is driven
# directly over remote control, scoped to the one split.
#
# Set in preexec (before the command runs) so the swap lands immediately, and
# cleared in precmd (when the prompt returns after the session ends).

_al_console_set_uservar() {
  printf "\033]1337;SetUserVar=%s=%s\007" "$1" "$(printf "%s" "$2" | base64 | tr -d '\n')"
}

# Kitty path. WezTerm recolored the whole window, because its config overrides
# are per-window. Kitty scopes to the one split via -m id:$KITTY_WINDOW_ID, so
# neighbouring panes keep their normal colors.
_al_console_kitty_active=""

_al_console_kitty_alert() {
  local env="$1" label
  [[ -n "$KITTY_WINDOW_ID" ]] || return 0

  case "$env" in
    prod)    label="DANGER" ;;
    staging) label="CAUTION" ;;
    *)       return 0 ;;
  esac

  local theme_name alert_theme
  theme_name=$(sed -n 's/^kitty=//p' "$HOME/.config/themes/current")
  alert_theme="$HOME/.config/themes/kitty/${theme_name}.alert.conf"
  [[ -f "$alert_theme" ]] || return 0

  local match="id:$KITTY_WINDOW_ID"
  local rc=0
  kitty @ set-colors -m "$match" "$alert_theme" || rc=1
  kitty @ set-window-logo --no-response -m "$match" \
    --position bottom-right --alpha 0.35 \
    "$HOME/.config/kitty/logos/${label:l}.png" || rc=1
  kitty @ set-tab-title "$label | ${PWD:t}" || rc=1
  kitty @ set-user-vars -m "$match" "AL_CONSOLE_ENV=$env" || rc=1

  if (( rc )); then
    echo "al console: kitty alert failed, no visual warning applied" >&2
    return 0
  fi

  _al_console_kitty_active=1
}

_al_console_kitty_clear() {
  # Guarded: precmd fires on every prompt, and each `kitty @` is a socket
  # round trip.
  [[ -n "$_al_console_kitty_active" ]] || return 0
  _al_console_kitty_active=""

  local match="id:$KITTY_WINDOW_ID"
  local rc=0
  # Not --reset: that flag implies --all and would reset every window.
  kitty @ set-colors -m "$match" "$HOME/.config/kitty/current-theme.conf" || rc=1
  kitty @ set-window-logo --no-response -m "$match" none || rc=1
  kitty @ set-user-vars -m "$match" "AL_CONSOLE_ENV=" || rc=1

  if (( rc )); then
    echo "al console: kitty clear failed, alert visuals may persist" >&2
  fi
}

_al_console_preexec() {
  local cmd="$1"

  case "$cmd" in
    al\ console\ create\ *|al\ console\ exec\ *) ;;
    *) return ;;
  esac

  local -a words
  words=(${(z)cmd})

  local env="" i
  for (( i = 1; i <= ${#words}; i++ )); do
    if [[ "${words[i]}" == "-e" ]]; then
      env="${words[i+1]}"
      break
    fi
  done

  case "$env" in
    prod|staging)
      _al_console_set_uservar AL_CONSOLE_ENV "$env"
      _al_console_kitty_alert "$env"
      ;;
  esac
}

_al_console_precmd() {
  _al_console_set_uservar AL_CONSOLE_ENV ""
  _al_console_kitty_clear
}

autoload -Uz add-zsh-hook
add-zsh-hook preexec _al_console_preexec
add-zsh-hook precmd _al_console_precmd
