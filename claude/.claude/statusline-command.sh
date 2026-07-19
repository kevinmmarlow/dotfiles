#!/bin/bash

# Read JSON input
input=$(cat)

# Extract values from JSON (without jq)
cwd=$(echo "$input" | sed -n 's/.*"current_dir":"\([^"]*\)".*/\1/p')

# Git information (skip optional locks for performance)
if git -C "$cwd" rev-parse --git-dir > /dev/null 2>&1; then
  repo_full=$(echo "$cwd" | sed "s|^$HOME/repos/||")
  repo_name="../${repo_full##*/}"

  branch=$(git -C "$cwd" --no-optional-locks rev-parse --abbrev-ref HEAD 2>/dev/null)
  branch="${branch#kmarlow/}"
  [ ${#branch} -gt 10 ] && branch="${branch:0:10}…"

  printf '\033[01;36m%s\033[00m | \033[01;32m%s\033[00m' "$repo_name" "$branch"
else
  # Not a git repo
  printf '\033[01;36m%s\033[00m' "$cwd"
fi