#!/bin/bash

# Read JSON input once
input=$(cat)

# Get git info from existing script
git_info=$(echo "$input" | bash ~/.claude/statusline-command.sh)

# npx re-resolves the package on every render (~5s). The asdf shim also fails in
# repos pinned to another node version, so call the install directly.
CCSL_NODE=~/.asdf/installs/nodejs/20.16.0/bin/node
CCSL_BIN=~/.asdf/installs/nodejs/20.16.0/lib/node_modules/ccstatusline/dist/ccstatusline.js

if [ -x "$CCSL_NODE" ] && [ -f "$CCSL_BIN" ]; then
  context_pct=$(echo "$input" | "$CCSL_NODE" "$CCSL_BIN")
else
  context_pct=$(echo "$input" | npx ccstatusline)
fi

# Combine outputs
printf '%s | %s' "$git_info" "$context_pct"
