---
name: so
description: Delegate the given task (or the task just discussed) to a Sonnet subagent — a fresh one, or an existing Sonnet agent that already holds the relevant context.
argument-hint: "[the task to delegate; omit to delegate the task just discussed]"
disable-model-invocation: true
---

Delegate this task to a **Sonnet** subagent instead of doing it yourself. You stay the orchestrator: brief, wait, review, relay.

The task is `$ARGUMENTS`. If that is empty, it is the task most recently discussed or agreed in this conversation.

## Push back only when it clearly needs Opus

The user chose Sonnet deliberately; the default is to comply. Question it only when you are confident the task will go materially worse on Sonnet — for example subtle architectural design, a hard debugging problem whose cause is still unknown, or a security-sensitive change where a missed case is costly. "Opus would be slightly better" is not enough.

If you do question it, ask once, in a sentence or two, naming the specific risk, and offer: Sonnet anyway, an Opus subagent, or do it yourself. Then do what the user picks. Do not delegate while you wait for the answer.

## Fresh agent or existing one

- **Reuse** an existing agent (`SendMessage` with its ID or name) when it was spawned with Sonnet and its context is relevant — follow-up work on what it just did, a fix to its output, the next step in the same area. Its model is fixed from when it was spawned, so never reuse a non-Sonnet agent for this.
- **Spawn fresh** (`Agent` with `model: "sonnet"`) for unrelated work, or when the existing agent's context is stale, polluted, or large enough to get in the way.
- Never use `subagent_type: "fork"`: a fork always runs on your model and ignores the `model` override.

If it's a toss-up, prefer reuse — the context it already has is the point.

## The brief

The agent knows only what you write. Include the goal, the relevant files and paths, decisions already made and approaches already ruled out, constraints (conventions, what not to touch), and what it should return. When reusing an agent, send only what's new.

## One agent or several in parallel

Before delegating, decide whether the work splits across multiple Sonnet agents running in parallel. Split when the pieces are genuinely independent — separate files or areas, no piece needing another's output, no shared decisions still to be made — and the speed-up is worth the extra briefs and the cost of reviewing several results. Keep it to one agent when pieces depend on each other in sequence, or share context that would be expensive to repeat in every brief.

Pieces that touch the same files can still run in parallel, each agent in its own child worktree (`isolation: "worktree"`), with the branches merged back together afterwards. Always discuss this with the user first: propose the split, where the conflicts are likely, and how you'd merge, and wait for agreement.

**At most two parallel agents without asking.** Launching three or more needs the user's go-ahead first — say how many, what each does, and why the extra agents are worth it.

If the split is obvious and within the limit, just do it: launch the agents in a single message so they run concurrently, each with its own scoped brief, and say in a line how you divided the work. If it's non-obvious — the boundaries are fuzzy, it needs worktrees, or one agent versus several is a real trade-off — briefly lay out the options and your recommendation, and let the user choose before delegating.

## After it reports

Its report is not shown to the user. Check the result where it's cheap to check (read the diff, run the test) rather than trusting the summary, then tell the user what was done and anything that looks wrong. Do not redo the work yourself; send fixes back to the same agent.
