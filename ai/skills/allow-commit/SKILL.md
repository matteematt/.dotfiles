---
name: allow-commit
description: Grant standing permission to stage and commit the current scope of work, using the repo's message convention, without asking in prose first.
argument-hint: "[optional: what the scope of work is, or how to split the commits]"
---

For the current scope of work you are **authorised to run `git add` and `git commit` yourself** — do not stop and ask in prose whether to commit. The authorisation is deliberately narrow; everything below bounds it.

## What is and is not granted

Granted by this skill on its own, for the current unit of work in this session: `git add` and `git commit` of the paths belonging to that work. Assume the current branch is the right place for it.

Not granted by the skill on its own:

- `git push` in any form, `git rebase`, `git merge`, `git reset`, `git revert`, `git checkout` / `switch` / `restore`, `git stash`, `git clean`
- amending or rewriting any commit you did not create in this session
- deleting or moving branches or tags
- anything belonging to a different piece of work than this invocation covers

**Read the whole instruction, though, not just the skill call.** Any of the above is authorised when the rest of what the user said alongside `/allow-commit` implies it — "commit and push this", "squash these first", "put it on a fresh branch off master", "bin the stray changes before you commit". The invocation and the sentence around it are one instruction; take that implication at face value rather than asking again for something the user has already asked for.

The implication has to be real. Do not read a step in because it would be convenient, or because it is how this kind of work usually ends: `/allow-commit` on its own never means push, and finishing a commit is not a licence to open a PR. Where the surrounding instruction is silent, the step is not granted — ask.

The grant expires with the scope of work. A new, unrelated task needs a new `/allow-commit`.

## Before committing

1. **Stage deliberately.** Read `git status --porcelain` and stage explicit paths. Never `git add -A`, `git add .`, or `git add -u`: the tree may hold dirt that predates your work — installer-appended lines, local config, scratch files. Leave anything unrelated alone and say that you did.
2. **Check what you are about to include.** Run `git diff --cached` before every commit. Do not commit secrets (keys, tokens, `.env`), large binaries, or generated output that belongs in `.gitignore` — stop and tell the user instead.
3. **Split by logic, not convenience.** If the scope covers separable changes, make separate commits, each independently coherent. `$ARGUMENTS`, when given, describes the scope or the split to follow.

## The message

Follow the convention in the `commit-message` skill — read that skill and apply it rather than duplicating its rules here. In short: one line, derived from the repo's own log, no invented `(#123)` suffix, and **no Claude attribution or trailer of any kind**.

Commit with a single `-m`: `git commit -m "<line>"`. No body unless the user asked for one.

## Permission prompts

`git add`, `git commit`, and every other git write listed above are gated by the global permission rules — on the `ask` list, or falling through to the default prompt — so the harness shows a permission prompt for each one no matter what this skill or the user's instruction has authorised. That prompt is the intended final confirmation, not a sign anything is wrong — proceed through it. If a prompt is **denied**, stop immediately, leave the tree as it is, and report what you were about to do. Do not retry and do not look for another route.

## After committing

Report:

- each commit's short SHA and subject (`git log --oneline -n <count>`)
- anything you deliberately left uncommitted, and why

Then stop. Do not push and do not open a PR unless the user asks.
