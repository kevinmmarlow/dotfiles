Be extremely concise everywhere — interactions, commits, PR descriptions, plans. Sacrifice grammar for concision.

# Writing Style

- NEVER use em dashes (—) in any writing: outputs, code comments, commits, PRs, docs. Use commas, colons, parens, or separate sentences instead.

# Code Style

- NEVER use JavaScript/TypeScript IIFEs (immediately invoked function expressions, e.g. `(() => {...})()`, `(async () => {...})()`). Use named functions, top-level await, or plain blocks instead.

# Comments

Golden rule: comments explain WHY code exists, never WHAT it does. Well-named code says what.

- Default to no comment. A comment must earn its place by documenting something the code can't: a hidden constraint, a non-obvious invariant, a workaround, a deliberate omission, a cross-service contract. If deleting it wouldn't confuse a future reader, delete it.
- Terse — sacrifice grammar for concision. One line where possible; no multi-line narration.
- Never restate the code (`// loop over users`), never explain obvious intent, never write file-header/docstring summaries.
- Never put ticket refs (Linear/Jira/GitHub #) in comments — explain the WHY directly; refs rot and belong in the PR/commit.
- Applies to code AND tests.

# Git & Github

- Use the Github CLI for all Github interactions.
- NEVER force push, reset --hard, clean -f, or branch -D without explicit permission.
- Always work on feature branches, never commit directly to main.
- Default to staging only (`git add`). Do NOT create commits unless explicitly asked.
- Use conventional commits when committing: `fix:`, `feat:`, `refactor:`.
- Branch prefix: `kmarlow/`. For Linear tickets: `kmarlow/<ticket-id>-descriptive-text`.

# Task Execution Patterns

## Small tasks (bugs, small features)
1. **grill-me** if task lacks context
2. **tdd** to implement (red-green-refactor, vertical slices)
3. Commit with conventional commits

## Larger features
1. **grill-me** → shared understanding
2. **to-prd** → formalize
3. **to-issues** → break into slices
4. Execute each slice with **tdd**

# Agent Artifacts

Agent-generated artifacts (PRDs, issues, handoffs) are local markdown. Never write agent artifacts into the project repo.

- PRDs: `~/.agents/<repo_name>/scratch/<feature-slug>/PRD.md`
- Issues: `~/.agents/<repo_name>/scratch/<feature-slug>/issues/<NN>-<slug>.md`
- Handoffs: `~/.agents/<repo_name>/handoffs/YYYY-MM-DD-<short-topic-slug>.md`

Create directories with `mkdir -p` as needed.

# PRs & Code Review

PR descriptions: Summary (required) → How it works / How it was breaking (optional) → Prerequisites / Required for (if applicable) → Test plan (checkbox format, required).

<example>
## Summary
- concise change description(s) go here

## How it works
- User story goes here

## Prerequisites
- Link to related PRs or necessary external changes

## Test plan
- [X] New spec test "xyz" passes
- [ ] Run through "abc" user story via ...
</example>

PR comments with TODOs use checkbox format: `- [ ] description here`.

# Plans

End every plan with a list of unresolved questions (if any).
