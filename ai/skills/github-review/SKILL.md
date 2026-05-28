---
name: github-review
description: Review the current branch's PR in depth and queue findings as a pending GitHub review, written in the user's voice.
argument-hint: "<base-branch> [extra context / focus areas]"
---

Review the PR for the current branch and queue findings as a **pending** GitHub review. Comments must land in pending state so the user can read, tweak, delete, or extend them before submission — never submit the review.

## Argument

The first token of `$ARGUMENTS` is the **base branch** for the diff (e.g. `main`, `master`, `develop`). Anything after is **extra context** the user wants you to factor into the review — e.g. "focus on the websocket session lifecycle", "this PR is meant to be backwards-compatible", "skip style nits". If no extra context is given, do a general review.

If the base branch isn't supplied, abort and ask for it. Do not guess.

## Phase 1 — Gather the diff and the PR

1. Identify the PR for the current branch:
   ```bash
   gh pr list --head "$(git branch --show-current)" --json number,title,baseRefName,url
   ```
   If there's no PR yet, tell the user and stop — pending reviews need a PR.
2. Pull the diff against the supplied base: `git diff <base>...HEAD`. If it's large, save to `/tmp/pr_diff.patch` and Read in chunks rather than dumping into the context.
3. Read the surrounding context for every hunk you'll comment on — bugs in unchanged lines of a touched function are in scope.

## Phase 2 — Find candidates (run in parallel)

Dispatch independent finder angles via the Agent tool. Each surfaces up to 8 candidates. Bias for recall — a missed bug ships:

- **Line-by-line diff scan** — every changed line: what input, state, timing, or platform makes this wrong? Inverted conditions, off-by-one, missing `await`, falsy-zero, copy-paste vars, swallowed errors.
- **Removed-behaviour auditor** — for each deleted/replaced line, name the invariant it enforced. Find where the new code re-establishes it. If you can't, that's a candidate.
- **Cross-file tracer** — for each touched function, grep callers. Does the change break a call site (new precondition, new exception, changed return shape)?
- **Language-pitfall specialist** — classic footguns for the diff's language/framework.
- **Wrapper/proxy correctness** — for any new wrapper/cache/adapter, verify methods route to the wrapped instance, not back through a registry/global.
- **Reuse / simplification / efficiency** — new code that re-implements existing helpers; redundant state; wasted work.
- **Altitude** — special cases layered on shared infrastructure where the underlying mechanism should be generalised.

If the user passed extra context, add an extra finder angle scoped to that concern.

## Phase 3 — Verify

Dedup candidates pointing at the same mechanism. For each remaining, run a single verifier (Agent tool, fresh context, given the diff + relevant files). Return one of:

- **CONFIRMED** — name the inputs/state and the wrong output. Quote the line.
- **PLAUSIBLE** — mechanism real, trigger uncertain. State what would confirm it.
- **REFUTED** — quote the line that disproves it.

Keep CONFIRMED + PLAUSIBLE. Recall mode: a single non-REFUTED vote carries the finding.

## Phase 4 — Sweep

Run one more finder as a fresh reviewer with the verified list, looking only for gaps. Don't pad — if nothing new, return empty.

## Phase 5 — Write the comments in the user's voice

**Voice summary:** direct, technically dense, conversational. Questions outnumber demands. Lead with the concern (often as a rhetorical question), then mechanism / failure scenario, then optional fix. Hedged but precise — soft framing, exact technical content.

### Habits

- **Length.** Most comments are one or two sentences. Multi-paragraph reserved for race conditions, lifecycle bugs, or "here are 2-3 alternatives" design questions.
- **Openers used heavily:** `Nitpick:`, `Question:`, `Suggestion:`, `Worth ...?`, `Why ...?`, `Why not ...?`, `Should we ...?`, `Should this ...?`, `Is there a way we can ...?`, `FYI ...`, `Not a blocker, but ...`. `worth -ing` constructions recur.
- **GitHub suggestion blocks** for any inlineable change, always followed by a one-sentence rationale — never bare.
- **Backticks around every identifier** — variables, files, types, props, CSS vars. Never bare prose for code.
- **Numbered lists (`1.` `2.` `3.`)** for alternatives — never bullets. End with "I think 2 and 3 are both valid approaches, lets discuss" or similar.
- **Hedges paired with precise claims:** `probably`, `maybe`, `I think`, `I wonder`, `not sure`, `feels like`, `slightly`. The hedge softens framing; the technical content underneath is exact.
- **British spelling:** `behaviour`, `colour`, `optimise`, `serialise`, `capitalisation`.
- **Contractions everywhere:** `don't`, `we're`, `isn't`, `let's`, `it's`. Never expanded.
- **Pronouns:** `we` dominant ("Should we explicitly..."). `you` only when squarely the author's job.
- **Acknowledgement** when something impresses is short and genuine: "Wow, this is really clever!", "Nice usage of this utility!", "Cool!". Don't pad.

### Don'ts

- No emoji.
- No markdown headers (`##`, `###`) inside review comments.
- No `**bold**` for emphasis. No italics either.
- No "LGTM" / contentless one-liners.
- No bulleted alternatives — numbered only.
- No "Pros / Cons" / "Issues:" / "Concerns:" framings — structure is prose, not checklists.
- No American spelling.
- No bare identifiers in prose — always backticks.
- No over-softening ("I might possibly suggest perhaps"). Hedged but precise, not mealy-mouthed.

### Representative comments (use as calibration)

**Short critique:**
> "This is a breaking change to the public API — are we sure no downstream apps consume it?"

**Soft nitpick + suggestion block:**
> "Nitpick: `this.value` reads through the getter which might trigger side effects we don't want here
> ```suggestion
>     this.$emit('change', newValue);
> ```"

**Why-question with rationale:**
> "Worth using `||` instead of `??` here? If an empty string comes through it's non-null, so we'd skip the fallback and keep the empty string."

**Drive-by FYI:**
> "FYI this will be wiped when the panel re-renders, so we'd lose anything stored here mid-session."

**Longer race-condition critique (question → mechanism → race → optional fix):**
> "Why both this and the `if (... isConnected)` block below? `isConnected$` is a `BehaviorSubject` so subscribing emits the current value synchronously — if we're already connected at mount, we fire `fetchData` from both the subscription callback and the `if` below. The `!this.dataSub` guard in the subscription doesn't catch it because `dataSub` is only assigned after the `await` inside `fetchData`, so both calls race past the guard."

**Numbered alternatives:**
> "Instead of an optional param that's only valid when `layout === 'vertical'`, should we make
> ```ts
> type LayoutType = ... | 'vertical' | { type: 'vertical'; height?: string }
> ```
> So it's used like
> ```ts
> options: { layout: { type: 'vertical', height: '250px' } }
> ```
> Adds a bit of redundancy but keeps the types tight without a breaking change. wdyt?"

## Phase 6 — Post as a pending review

**This is non-negotiable. The review must land in `PENDING` state. Never submit.**

Build a JSON payload with the comments and `POST` to the reviews endpoint **without an `event` field** — that's what makes it pending:

```bash
gh api -X POST /repos/<owner>/<repo>/pulls/<n>/reviews --input /tmp/review.json --jq '{id, state, html_url}'
```

The body shape:
```json
{
  "body": "Optional top-level summary",
  "comments": [
    { "path": "src/foo.ts", "line": 42, "side": "RIGHT", "body": "..." }
  ]
}
```

Expected response: `state: PENDING`. If you don't see that, something is wrong — stop and report.

### Watch-outs when posting

- **Line must be inside a diff hunk** (or in a touched file's unified-diff range). GitHub silently drops comments on lines outside the diff. After posting, list the comments back and warn the user about any that didn't attach:
  ```bash
  gh api /repos/<owner>/<repo>/pulls/<n>/reviews/<review_id>/comments --jq '.[] | {id, path, line}'
  ```
- **One pending review per user per PR.** If the user already has a pending review on this PR, you'll get HTTP 422. In that case, switch to the follow-up workflow below (add to the existing review).
- **For multi-line comments**, use `start_line` + `start_side` alongside `line` + `side`.
- **Verify line numbers against the current file state**, not the diff line offsets.

After posting, briefly summarise: count of comments, the review URL, and which findings (if any) were dropped because they fell outside the diff hunks.

## Phase 7 — Follow-up workflow (CRITICAL)

Typical workflow: agent drafts comments → user reads, tweaks, deletes some, then comes back asking for more / for rewrites. **Every follow-up must also stay in the same pending review.** The REST `POST /pulls/{n}/comments` endpoint won't work while a pending review exists — it errors with `user_id can only have one pending review per pull request`. Use GraphQL instead.

### Adding more comments to the existing pending review

You need the review's GraphQL node ID:
```bash
gh api /repos/<owner>/<repo>/pulls/<n>/reviews/<review_id> --jq '.node_id'
# e.g. PRR_kwDOLTRkmc8AAAABBRBiog
```

Then for each new comment:
```bash
gh api graphql -f query='
  mutation($reviewId: ID!, $body: String!, $path: String!, $line: Int!) {
    addPullRequestReviewThread(input: {
      pullRequestReviewId: $reviewId,
      path: $path,
      line: $line,
      side: RIGHT,
      body: $body
    }) {
      thread { id isResolved }
    }
  }
' -F reviewId="$REVIEW_ID" -F path="$PATH_VAL" -F line="$LINE" --raw-field body="$BODY"
```

### Editing an existing pending comment

Pending comments **cannot** be edited via REST `PATCH /pulls/comments/{id}` (404). Use GraphQL with the comment's node ID:

```bash
# Get pending comment node IDs
gh api graphql -f query='
{
  repository(owner: "<owner>", name: "<repo>") {
    pullRequest(number: <n>) {
      reviews(first: 5, states: PENDING) {
        nodes { id comments(first: 100) { nodes { id databaseId path body } } }
      }
    }
  }
}'

# Update one
gh api graphql -f query='
  mutation($commentId: ID!, $body: String!) {
    updatePullRequestReviewComment(input: { pullRequestReviewCommentId: $commentId, body: $body }) {
      pullRequestReviewComment { databaseId }
    }
  }
' -F commentId="$NODE_ID" --raw-field body="$NEW_BODY"
```

### Deleting a pending comment

REST `DELETE` works for pending comments:
```bash
gh api -X DELETE /repos/<owner>/<repo>/pulls/comments/<comment_id>
```

### Map of operations

| Operation                | Endpoint                                                                                |
|--------------------------|-----------------------------------------------------------------------------------------|
| Create pending review    | REST `POST /pulls/{n}/reviews` (omit `event`)                                           |
| List pending comments    | REST `GET /pulls/{n}/reviews/{id}/comments` or GraphQL `reviews(states: PENDING)`       |
| Add comment to pending   | GraphQL `addPullRequestReviewThread` (with `pullRequestReviewId`)                       |
| Edit pending comment     | GraphQL `updatePullRequestReviewComment` (with comment node ID)                         |
| Delete pending comment   | REST `DELETE /pulls/comments/{id}`                                                      |
| Get review node_id       | REST `GET /pulls/{n}/reviews/{id}` → `.node_id`                                         |
| Get comment node_ids     | GraphQL `repository.pullRequest.reviews(states: PENDING).nodes.comments.nodes[].id`     |
| Submit (DO NOT)          | REST `POST /pulls/{n}/reviews/{id}/events` — never call this                            |

## Conduct

- **Push back on your own findings when challenged.** If the user questions a finding, walk through the actual code path — don't capitulate, but don't dig in either. Many "bugs" survive draft and dissolve on a second look. Delete the comment if it doesn't hold up.
- **Don't claim certainty you don't have.** Use the voice's hedges (`probably`, `I think`, `not sure`) when uncertain — they're stylistically aligned and intellectually honest.
- **Severity gate.** Correctness > altitude/duplication > style. If the cap forces a cut, drop nits first.
- **Don't review what you can't see.** If a finding depends on caller behaviour you haven't grepped, either grep first or downgrade to PLAUSIBLE.
