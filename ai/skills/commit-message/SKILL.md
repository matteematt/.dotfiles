---
name: commit-message
description: Propose a one-line commit message for the current dirty work, matching this repo's commit style, with no Claude attribution.
argument-hint: "[optional steer, e.g. 'this is a fix not a feature' or 'scope it to the installer']"
---

Produce a single-line commit message for the work currently in the tree. **Propose only — do not stage, do not commit, do not write any file.** End your response with the message on its own final line and nothing after it, so it can be copied straight into `git commit -m`.

## Phase 1 — See the work

Staged and unstaged changes both count as "the current dirty work":

```bash
git status --porcelain
git diff
git diff --cached
```

Untracked files appear in neither diff — if `git status` lists any, read them directly. A new file is often the whole point of the change.

If the tree is clean, say so and stop. Do not invent a message.

## Phase 2 — Derive the repo's convention

Never assume a house style — read it off the log:

```bash
git log --no-merges --pretty=format:%s -n 40
```

Infer and match:

- **Prefix scheme** — Conventional Commits (`feat:`, `fix:`, `chore(scope):`)? A ticket key (`ABC-123:`)? Bare prose? Match whichever dominates, including whether a parenthesised scope is used and how existing scopes are named.
- **Mood and case** — imperative vs past tense; lowercase vs sentence case after the prefix.
- **Punctuation** — trailing period or not (usually not).
- **Length** — stay within the length the log actually uses; absent a signal, keep under ~72 characters.

If the log is genuinely mixed, follow the most recent 10 commits.

**Artefacts the log will show that you must not reproduce:**

- A trailing PR/MR reference such as `(#296)` — the forge appends that on squash-merge, the author never typed it. Never invent one.
- `Co-authored-by:`, `Signed-off-by:`, `Generated with …`, or any other trailer.

## Phase 3 — Write the line

- Describe **what the change does**, not what you did or which files moved. `fix: guard against empty worktree list` beats `update script`.
- One line only. No body, no bullets, no surrounding quotes, no backticks, no code fence.
- **No Claude or AI attribution in any form** — no trailer, no emoji, no "with Claude". The author of record is the user.
- If `$ARGUMENTS` is present, treat it as the user's steer on framing (change type, scope, what to emphasise) and honour it over your own reading of the diff.

If the tree holds two or more unrelated changes, still give the best single line, then add one short sentence noting that it would read better as separate commits and what the split would be. Put that note *above* the message so the final line stays copy-pasteable.
