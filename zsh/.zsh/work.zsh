# AngelList (work) shell config. Tracked, but only meaningful on AngelList
# machines; sourced from ~/.zshrc after Oh My Zsh so `compdef` exists for the
# `al` completions. Delete this file (or don't stow it) on a personal machine.

# Go modules served from the private org
export GOPRIVATE=github.com/angellist/*

# Default AWS profile for SSO / EKS access
export AWS_PROFILE=angellist-venture-prod-engineer

# `al` CLI completions (guarded so a machine without `al` doesn't error)
command -v al >/dev/null && source <(al completion zsh)

# Flags `al console` prod/staging sessions for WezTerm (see wezterm.lua) via OSC
# 1337 SetUserVar. WezTerm reads this per-pane and swaps the window color scheme
# to a light/contrasting theme so the dangerous session is unmissable.
#
# The OSC var is set in preexec (before the command runs) so WezTerm can swap
# immediately, and cleared in precmd (when the prompt returns after the session ends).

_al_console_set_uservar() {
  printf "\033]1337;SetUserVar=%s=%s\007" "$1" "$(printf "%s" "$2" | base64 | tr -d '\n')"
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
      ;;
  esac
}

_al_console_precmd() {
  _al_console_set_uservar AL_CONSOLE_ENV ""
}

autoload -Uz add-zsh-hook
add-zsh-hook preexec _al_console_preexec
add-zsh-hook precmd _al_console_precmd
