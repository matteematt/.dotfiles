---
name: blueprint
description: Plan a piece of work in two phases — first explore and agree a written plan with the user (research and commands, no code changes), then, once they are happy, add a PR stack, Sonnet-first implementation tasks and a testing matrix to it.
argument-hint: "[folder holding similar plans, e.g. data/ — omit for a throwaway plan at the worktree root]"
disable-model-invocation: true
---

Run a planning process with the user for the task in front of you (a ticket, a request, or what was just discussed). It has two phases, and the user decides when the first one is over. **No code changes in either phase.**

## Where the plan lives

`$ARGUMENTS` is optional.

- **A folder is given** (for example `data/`). It holds earlier plans. Look at a few of them first and follow their conventions: subfolder and file naming (such as `data/genc-1234/PLAN.md`), heading style, how decisions and open questions are recorded. Write the new plan there. It is meant to be kept, so it can be committed when the user says so.
- **Nothing is given.** The plan is throwaway. Write it at the worktree root (`git rev-parse --show-toplevel`) as `PLAN-<short-slug>.md`. Do not commit it, and say once that it is untracked.

Write the file as soon as a direction is agreed, not at the end. Keep it up to date as the conversation moves: the file is the record, the chat is not.

## Phase 1: explore and agree

The aim is a design the user agrees with. Talk, research and iterate.

**Allowed:** reading code, docs and history; fetching the ticket and its attachments; running read-only commands; looking at prior art the user points to (other repos, earlier projects); throwaway spikes.

**Not allowed:** editing source, config, dependencies or lockfiles in the repo; commits; anything outward-facing. A spike that needs packages or code goes in the session scratchpad with its own `package.json`, never the repo. A spike can be delegated to a Sonnet subagent with a precise brief: the question, the runtime to match, what to return. Record its result in the plan.

**How to work with the user:**

- Start with an analysis: what the task asks, what already exists that it builds on (with `file:line`), the main decision and your recommendation with the reasons, the risks, and a rough size. Recommend; do not survey every option.
- When the user pushes back or brings prior art, read that prior art yourself before replying. Say plainly what it does and how it would fit, and adopt it where it is better.
- When the user restates the approach in their own words, confirm what is right and correct only what is wrong, briefly.
- Ask each open question once, with a suggested answer. Record each answer in a dated **Decisions** section and remove it from **Open questions**.
- Put a risky unknown that could change the design first in the work, as a spike, with a go/no-go and a named fallback.

**Plan contents at the end of phase 1:**

1. **Goal**, and **Acceptance**: the ticket's acceptance criteria, or ones agreed with the user.
2. **Approach**: what will be done and why, including the alternatives ruled out and why. A small comparison table helps when adapting prior art.
3. **Design**: numbered sections (`§1`, `§2`, …) that later parts refer to. Each names the files and functions it touches.
4. **Spike result**, if there was one: verdict, versions, and findings that change the build.
5. **Test material**: the inputs that will prove it works.
6. **Known gaps**: accepted for now, with why.
7. **Decisions** (dated) and **Open questions**.

Phase 1 ends only when the user says so ("happy with the plan", "define the stack", and the like). Do not move on by yourself.

## Phase 2: PR stack, implementation tasks, testing matrix

Add three sections to the plan. Each refers back to the design by `§` number.

### 1. PR stack (GitHub stacked PRs, `gh stack`)

- A table: `#`, branch, PR title, contents, plan `§`.
  - Branch names follow the repo's convention, numbered in stack order (e.g. `<prefix>/<TICKET>-1-<slug>`).
  - Titles follow the repo's commit convention, read from `git log` (prefix, ticket key, wording).
- **Every PR leaves the main branch working and honest if the stack stopped there.** Nothing a PR accepts is half-handled or dropped silently. When a later PR finishes a feature, the earlier one does something smaller but true. For example, it reports what it cannot handle yet.
- Put the riskiest infrastructure in its own early PR, with nothing user-visible beside it. Put the smallest user-visible win early, so it could merge first. Split a reviewer-sensitive change (prompts, shared paths) from the bulk of the code.
- A short **Why this order** paragraph.
- **Mechanics:** the `gh stack` commands (`init`, `add`, `submit`, `sync`), who runs them, and where the plan itself goes (usually in PR 1). Git and `gh` operations are the user's unless they have granted them (for example with `/allow-commit`).

### 2. Implementation tasks

- A table: task, PR, a short brief, what it depends on, and the **model**.
  - Usually one task per PR.
  - Split a PR when part of it can be written and tested as pure logic without the rest (for example a detection algorithm over plain data).
- **The default model is Sonnet.** Mark **Opus** only where it is materially better, and say why on the row. Typical reasons: subtle architectural design, debugging with an unknown cause, security-sensitive changes, prompt or agent-behaviour design where a wrong call is costly.
- **The plan must work fully in series.** One subagent at a time is the default. List **parallel candidates** separately, as proposals only: which tasks, why they do not collide, and the likely conflict. Never let the order depend on parallelism. Parallel runs need the user's yes for that batch.
- **Rules every brief carries:** the plan path and the `§` it implements; files to touch and not touch; decisions already made; the test and typecheck commands; no git operations; the repo's own conventions (from CLAUDE.md and memory); what to return (files changed and why, dependency diffs, test output, anything undone or unsure).
- **The review loop:** after each task, the orchestrator reads the diff and runs the tests and typechecks itself. Fixes go back to the same agent, and the orchestrator does not redo the work. Then the user commits, or the agent commits under `/allow-commit`.

### 3. Testing matrix

- **Levels.** Name the repo's real ones: unit, integration or headless, browser or manual. For each, say what it costs (live model calls spend money) and who starts it. If the user wants to watch browser runs, they start them.
- **Inputs × levels.** A table: input, what it tests, a tick per level, and the PR that adds it. Cover the happy path, each edge case from the design, each failure mode, and each known gap. Mark which rows prove the ticket's acceptance.
- **Variants.** Other dimensions that matter (vendors, environments, settings). Name which rows run on each, not all of them on everything.
- **Acceptance runs.** Which rows prove each acceptance criterion, and how a pass is judged when output varies (what must match, what may differ).
- **Cost.** What the live runs spend, and what they must measure for later steps.
- **Not in the matrix.** What general tests should avoid, so they do not hit the new behaviour.

When phase 2 is written, summarise the three sections briefly and ask whether to commit the plan and start the first task. Do not start it until the user says so.
