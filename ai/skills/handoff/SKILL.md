---
name: handoff
description: Compact the current conversation into a handoff document for another agent to pick up.
argument-hint: "What will the next session be used for? (add --tmp to write to /tmp instead of the repo root)"
---

Write a handoff document summarising the current conversation so a fresh agent can continue the work.

**Where to save it:**
- By default, save it to the root of the current repository — the path returned by `git rev-parse --show-toplevel`.
- If the user passes the `--tmp` flag, save it to `/tmp` instead. Always use `/tmp` literally; do not substitute `$TMPDIR` or any other OS-specific temporary directory, since those vary between machines and agents pick inconsistent locations.
- If the default (repo root) is selected but the working directory is not inside a git repository, fall back to `/tmp` — and tell the user explicitly that you did so because you're not in a git repo, rather than silently writing to `/tmp`.

Always report the final path where you saved the document.

Give the file a verbose, descriptive name derived from the handoff contents (e.g. the repo/project, task, and a short topic slug) so it is easy to identify later among other handoffs. Use kebab-case with a date prefix, e.g. `2026-05-27-dotfiles-ai-skills-install-script-handoff.md`.

Include a "suggested skills" section in the document, which suggests skills that the agent should invoke.

Do not duplicate content already captured in other artifacts (PRDs, plans, ADRs, issues, commits, diffs). Reference them by path or URL instead.

Redact any sensitive information, such as API keys, passwords, or personally identifiable information.

If the user passed arguments, treat them as a description of what the next session will focus on and tailor the doc accordingly.
