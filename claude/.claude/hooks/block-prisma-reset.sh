#!/bin/bash

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command')

# Block Prisma resets that would drop the local DEV database.
# Intentionally narrow: `just dev migrate-test` resets the *test* DB (suffixed
# `_test`) and is the supported way to (re)seed it for the vitest suite — allow
# that through. The patterns below only catch direct dev-DB invocations.
DANGEROUS_PATTERNS=(
  "just dev prisma migrate reset"
  "prisma db push.*--force-reset"
)

# Also block bare `prisma migrate reset` UNLESS the same command line is
# clearly targeting the test DB (via `migrate-test` or a `_test` URL/var).
if echo "$COMMAND" | grep -qE "prisma migrate reset"; then
  if ! echo "$COMMAND" | grep -qE "migrate-test|_test"; then
    echo "BLOCKED: '$COMMAND' would reset the local Prisma dev database. The user has prevented this. Use 'just dev migrate-test' if you intended the test DB." >&2
    exit 2
  fi
fi

for pattern in "${DANGEROUS_PATTERNS[@]}"; do
  if echo "$COMMAND" | grep -qE "$pattern"; then
    echo "BLOCKED: '$COMMAND' matches dangerous pattern '$pattern'. The user has prevented this." >&2
    exit 2
  fi
done

exit 0
