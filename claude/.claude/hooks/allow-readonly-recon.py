#!/usr/bin/env python3
"""Auto-approve read-only Bash commands that static permission rules can't match.

WHY: compound commands (cd && npx biome lint … | tail; echo) never match
prefix-based permission entries, so every code-search / lint prompts. This
classifies a command as read-only (recon + non-mutating linters/typecheckers)
and returns an `allow` decision; anything it's unsure about is passed through
untouched (exit 0, no decision) to the normal permission flow. Fail-open is safe
here: worst case is a prompt, never an unwanted auto-run.
"""
import json
import re
import shlex
import sys

# Commands that cannot mutate state, spawn writers, or exfiltrate on their own.
# NOTE: no `tee` (writes a file arg) and no bare `xargs` trust — xargs' child is
# re-validated below, because `find | xargs rm` must NOT be auto-approved.
SAFE = {
    "cd", "pwd", "ls", "cat", "head", "tail", "echo", "printf", "true", "false",
    "find", "grep", "rg", "fd", "wc", "sort", "uniq", "cut", "tr", "comm", "join",
    "basename", "dirname", "realpath", "readlink", "stat", "file", "test", "[",
    "column", "jq", "yq", "xargs",
}

# Runners we unwrap to validate the real tool they invoke.
NPX_LIKE = {"npx", "bunx"}
SUBCMD_RUNNERS = {"pnpm", "yarn", "bun"}  # only `<runner> exec|dlx <tool>`

# find flags that execute or delete — never auto-approve these.
DANGEROUS_FIND = re.compile(r"(^|\s)-(exec|execdir|delete|fprint|fprintf|ok|okdir)\b")
# Output redirection to a real file. `>/dev/null`, `2>&1`, `2>/dev/null`, `&>` are fine.
WRITE_REDIRECT = re.compile(r"(?<![\d&])>>?\s*(?!/dev/null|&\d)\S")
# Redirections to strip AFTER the write check, so `2>&1`/`&>` don't confuse splitting.
REDIR = re.compile(r"(?:\d+|&)?>>?\s*(?:&\d+|/dev/\w+)")
QUOTED = re.compile(r"'[^']*'|\"[^\"]*\"")
ASSIGNMENT = re.compile(r"[A-Za-z_][A-Za-z0-9_]*=.*")

BIOME_READONLY_SUBCMDS = {"lint", "check", "format", "ci"}
BIOME_WRITE_FLAGS = {"--write", "--fix", "--apply", "--apply-unsafe", "--unsafe"}


def inner_substitutions(cmd):
    for m in re.finditer(r"\$\(([^()]*)\)", cmd):
        yield m.group(1)
    for m in re.finditer(r"`([^`]*)`", cmd):
        yield m.group(1)


def base_name(tok):
    return tok.rsplit("/", 1)[-1]


def strip_npx_flags(args):
    """Return args starting at npx's child command, or None if it's doing something
    fancy (`-p pkg`, `-c cmd`) we can't statically vouch for."""
    i = 0
    while i < len(args):
        a = args[i]
        if a in ("-p", "--package", "-c", "--call"):
            return None
        if a.startswith("-"):
            i += 1
            continue
        return args[i:]
    return None


def linter_ok(head, args):
    flags = {a for a in args if a.startswith("-")}
    words = [a for a in args if not a.startswith("-")]
    if head == "biome":
        sub = words[0] if words else None
        return sub in BIOME_READONLY_SUBCMDS and not (flags & BIOME_WRITE_FLAGS)
    if head == "eslint":
        return not (flags & {"--fix", "--fix-type"})
    if head == "prettier":
        return not (flags & {"--write", "-w"})
    if head == "stylelint":
        return "--fix" not in flags
    if head == "tsc":
        return "--noEmit" in flags and not (flags & {"--build", "-b"})
    return False


def tool_ok(tokens):
    """Validate one simple command (command word + args), recursing through runners."""
    tokens = [t for t in tokens if not ASSIGNMENT.fullmatch(t)]
    if not tokens:
        return True  # bare assignment / empty — harmless
    head = base_name(tokens[0])
    args = tokens[1:]

    if head in SAFE:
        if head == "xargs":
            for j, t in enumerate(args):
                if t.startswith("-"):
                    continue
                return tool_ok(args[j:])
            return True  # no child -> defaults to echo
        return True

    if head in NPX_LIKE:
        child = strip_npx_flags(args)
        return child is not None and tool_ok(child)

    if head in SUBCMD_RUNNERS:
        return len(args) >= 2 and args[0] in ("exec", "dlx") and tool_ok(args[1:])

    return linter_ok(head, args)


def is_safe(cmd):
    for sub in inner_substitutions(cmd):
        if not is_safe(sub):
            return False

    cleaned = cmd.replace("\\\n", " ")  # join `\`-newline line continuations
    # Drop substitutions and quoted strings so operator-splitting and the redirect
    # check aren't fooled by `|`, `;`, or `>` living inside arguments.
    cleaned = re.sub(r"\$\([^()]*\)", " ", cleaned)
    cleaned = re.sub(r"`[^`]*`", " ", cleaned)
    cleaned = QUOTED.sub(" ", cleaned)

    if WRITE_REDIRECT.search(cleaned):
        return False
    if DANGEROUS_FIND.search(cleaned):
        return False

    cleaned = REDIR.sub(" ", cleaned)
    segments = re.split(r"\|\||&&|[|;\n&]", cleaned)
    saw_command = False
    for seg in segments:
        if not seg.strip():
            continue
        try:
            tokens = shlex.split(seg, comments=True)
        except ValueError:
            return False
        if not tool_ok(tokens):
            return False
        saw_command = True
    return saw_command


def main():
    try:
        data = json.load(sys.stdin)
    except Exception:
        sys.exit(0)
    command = data.get("tool_input", {}).get("command", "")
    if command and is_safe(command):
        print(json.dumps({
            "hookSpecificOutput": {
                "hookEventName": "PreToolUse",
                "permissionDecision": "allow",
                "permissionDecisionReason": "read-only (auto-approved)",
            }
        }))
    sys.exit(0)


if __name__ == "__main__":
    main()
