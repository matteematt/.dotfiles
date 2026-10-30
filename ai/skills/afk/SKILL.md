---
name: afk
description: Prepare this session for the user to be away from the keyboard — deny prompting git commands, keep the work going if a turn ends early, keep the Mac awake — or undo all of it with `off`.
argument-hint: "[what to work on while I'm away, and for how long | off]"
disable-model-invocation: true
---

The user is about to step away. Nobody will answer a permission prompt or a question, so anything that waits on the user hangs the session until they're back. Set the session up so it keeps working unattended, then carry on with the task.

`$ARGUMENTS` is what to work on while they're away (and maybe for how long). If it's empty, carry on with the work already under way in this conversation. If it is `off`, skip to **Coming back** below.

Do the setup steps in order, then tell the user in a few lines what's in place before you start (or resume) the work — they may still be reading as they leave.

## Setup

All state for this AFK session lives in one place, so `off` can undo exactly what was done:

```bash
proj="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
state="$(git rev-parse --absolute-git-dir 2>/dev/null || echo "$proj/.claude")/afk"
mkdir -p "$proj/.claude" "$state"
```

`$proj` must be the directory this session was started in (where its `.claude/settings.local.json` is read from). If the session's primary working directory differs from the git top level, use the working directory instead.

If `$state` already exists with contents, an earlier `/afk` was never turned off — reuse what's there rather than stacking a second setup.

### 1. Deny the git commands that would prompt

The user's global `~/.claude/settings.json` puts mutating git commands (`git add`, `git commit`, `git push`, …) in `permissions.ask`. Unattended, each one opens a prompt that hangs the session. Turn every `ask` rule into a `deny` in the project's local settings so they fail immediately instead, and record exactly which rules were added:

```bash
f="$proj/.claude/settings.local.json"
[ -f "$f" ] || echo '{}' > "$f"
jq -n --slurpfile g ~/.claude/settings.json --slurpfile l "$f" \
  '($g[0].permissions.ask // []) - ($l[0].permissions.deny // [])' > "$state/added-deny.json"
jq --slurpfile a "$state/added-deny.json" \
  '.permissions.deny = ((.permissions.deny // []) + $a[0])' "$f" > "$f.tmp" && mv "$f.tmp" "$f"
```

Claude Code picks up the change on its own after a short delay. Do the remaining setup steps, then confirm the deny is live with a harmless command such as `git add --dry-run .`: it should be refused without a prompt. If it prompts instead, the user is still here — let them deny it, and check again after a moment.

While AFK, a denied git command is the expected outcome, not an obstacle. **Do not work around it** — no `git -C … commit`, `command git`, full paths to the binary, aliases, scripts, or `gh` equivalents that change the repo. Leave the work uncommitted in the working tree and list what you would have committed in the AFK log.

### 2. Keep the work going if a turn ends early

Schedule a recurring check-in with `CronCreate` (load it through `ToolSearch` if it's deferred). It only fires while the session is idle, so it does nothing while you're working and picks things up if a turn stops before the task is done. Use roughly every 20 minutes on off-minutes, e.g. `"7,27,47 * * * *"`, with a prompt along the lines of:

> AFK check-in: the user is still away. Read the AFK log in `<state>/log.md`. If the AFK task is not finished and not blocked, continue it. If it is finished or genuinely blocked, reply with one short line and do nothing else.

Save the returned job ID to `$state/cron-id` so `off` can delete it. If a time limit was given, also schedule a one-shot job at that time telling yourself to wrap up: finish the current step, update the log, and stop.

### 3. Keep the Mac awake

Start `caffeinate` in the background, with no time limit, so the machine doesn't sleep under the session, and record its PID. Don't ask first; it runs until `/afk off`.

```bash
caffeinate -i >/dev/null 2>&1 &
echo $! > "$state/caffeinate.pid"
```

### 4. Start the AFK log

Create `$state/log.md` with the task, what "done" means, and the time you started. Keep it current as you work — it is how check-ins resume and how the user catches up:

- progress and what's next
- decisions you made on the user's behalf, and why
- git commands that were denied, and what you would have committed (files and a proposed message)
- blockers and open questions

## While AFK

AFK lasts until the user runs `/afk off` — nothing else ends it. They may drop in now and then to ask for progress or weigh in on a decision; answer them (from the log where useful), apply what they decide, record it in the log, and carry on in AFK mode. Don't treat a message from them as being back: keep the deny rules, check-ins, and `caffeinate` in place, and don't start waiting on them again just because they replied once.

- **Don't ask; decide.** `AskUserQuestion` and questions in prose both hang. Pick the sensible default, note the decision in the log, and keep going. Take the reversible option over the irreversible one.
- **Avoid anything else that would prompt.** If a step can only be done through a command that will need approval, skip it, log it, and do the next thing that can be done.
- **Stay in scope.** Don't start unrelated work or anything hard to undo — no pushes, deploys, deletions of the user's files, or messages to other people or services.
- **Subagents:** follow the user's usual limits (no more than two in parallel without asking — and while they're away you can't ask, so two is the cap).
- **Park decisions, don't block on them.** If something genuinely needs the user, note it under open questions in the log and work on what you can meanwhile; they may answer it on their next drop-in.
- **Notify only when it's worth coming back for.** Use `PushNotification` once when the task is finished, or when you're blocked on something only the user can decide. One line, leading with what they'd act on.

## Coming back (`/afk off`)

Undo the setup, using `$proj` and `$state` as computed above:

```bash
f="$proj/.claude/settings.local.json"
jq --slurpfile a "$state/added-deny.json" \
  '.permissions.deny -= $a[0] | if .permissions.deny == [] then del(.permissions.deny) else . end' \
  "$f" > "$f.tmp" && mv "$f.tmp" "$f"
[ -f "$state/caffeinate.pid" ] && kill "$(cat "$state/caffeinate.pid")" 2>/dev/null
```

Delete the check-in job with `CronDelete` using the ID in `$state/cron-id` (and any wrap-up job). Then give the user a short catch-up from the log: what got done, decisions made for them, what's waiting to be committed, and anything blocked. Remove `$state` only after that summary is written.
