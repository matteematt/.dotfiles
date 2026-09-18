---
name: github-review
description: Review the current branch's PR in depth and queue findings as a pending GitHub review, written in the user's voice.
argument-hint: "<base-branch> [extra context / focus areas]"
---

Review the PR for the current branch and queue findings as a **pending** GitHub review. Comments must land in pending state so the user can read, tweak, delete, or extend them before submission — never submit the review.

## Argument

The first token of `$ARGUMENTS` is the **base branch** for the diff (e.g. `main`, `master`, `develop`). Anything after is **extra context** the user wants you to factor into the review — e.g. "focus on the websocket session lifecycle", "this PR is meant to be backwards-compatible", "skip style nits". If no extra context is given, do a general review.

If the base branch isn't supplied, abort and ask for it. Do not guess.

## Subagents — optimise for context, not speed

Subagents are a context-management tool, not a parallelism trick. The default is to do the work yourself in the main context. Delegate a step only when it would otherwise pull a lot of material you don't need to keep — reading a large set of files, grepping call sites across the repo, scanning a huge diff — and the useful output is a short list of findings.

Don't fan out a swarm of agents just to finish sooner. Running seven finder angles as seven parallel agents costs far more than it saves when the diff is small enough to hold in context. Judge it per review: a 40-line diff is a read-it-yourself job; a 3000-line diff across 30 files is where delegation earns its keep. Where you do delegate, batch several angles into one agent rather than one agent per angle.

None of this lowers the bar. The review must be completely thorough — every angle below gets covered either way. The only question is whether you cover it inline or hand it to an agent to keep the main context clean.

## The workflow this skill sits in

You never submit a review. The full cycle is:

1. You draft findings and post them as a **pending** review. Only the user can see them.
2. The user reads, tweaks, deletes, and adds — possibly over several turns (Phase 7).
3. **The user submits the review themselves, outside this session.** From that moment the comments are public and the PR author has read them.
4. The author pushes fixes and/or replies to the comments. The user comes back and asks for another look.

Step 3 is invisible to you — nothing in the session tells you it happened. So never assume the review you created earlier is still pending. Check the state before you touch anything (Phase 1), and re-check before any edit or delete in Phase 7.

Once a review is submitted its comments are no longer yours to rewrite. Editing one silently changes something the author has already read and may have replied to; deleting one erases a thread they're mid-conversation on. Leave them alone unless the user explicitly asks for a change to a specific comment, and put new findings in a new pending review.

## Phase 1 — Gather the diff and the PR

1. Identify the PR for the current branch:
   ```bash
   gh pr list --head "$(git branch --show-current)" --json number,title,baseRefName,url
   ```
   If there's no PR yet, tell the user and stop — pending reviews need a PR.
2. Work out where things stand — what you've already said, and what's happened since:
   ```bash
   # Reviews on this PR and their state (PENDING = drafted, not yet submitted)
   gh api /repos/<owner>/<repo>/pulls/<n>/reviews \
     --jq '.[] | {id, user: .user.login, state, commit_id, submitted_at}'

   # Existing review threads, with resolution status and author replies
   gh api graphql -f query='
   {
     repository(owner: "<owner>", name: "<repo>") {
       pullRequest(number: <n>) {
         reviewThreads(first: 100) {
           nodes {
             isResolved isOutdated path line
             comments(first: 20) { nodes { author { login } body } }
           }
         }
       }
     }
   }'
   ```
   Read the results before reviewing anything:
   - **Nothing there** — first review, carry on with the full pass below.
   - **A `PENDING` review of yours** — the user hasn't submitted yet, you're still drafting. Add to that review (Phase 7); don't create a second one.
   - **A submitted review of yours** (`COMMENTED` / `CHANGES_REQUESTED` / `APPROVED`) — those comments are public. Its `commit_id` is the SHA you last reviewed, so `git diff <commit_id>...HEAD` is what the author has done since, and that's the focus of this pass. See the second-round rules in Phase 7.
   - **Resolved threads** are settled — don't re-raise them. **Unresolved threads with an author reply** are live arguments: read the reply and only push back if it doesn't hold up.
3. Pull the diff against the supplied base: `git diff <base>...HEAD`. If it's large, save to `/tmp/pr_diff.patch` and Read in chunks rather than dumping into the context.
4. Read the surrounding context for every hunk you'll comment on — bugs in unchanged lines of a touched function are in scope.
5. Install dependencies if it helps the review. If the repo's deps aren't present and having them would let you type-check, lint, resolve imports, or run the finder/verifier agents against real modules, go ahead and run `npm i` (or the project's equivalent — `pnpm i`, `yarn`, etc.). This is worth doing whenever it raises confidence in the findings; don't hold back on it.

## Phase 2 — Find candidates

Work through every angle below — that's the coverage bar and it doesn't move. Do them yourself unless the diff is big enough that delegating keeps the main context usable; where you delegate, batch angles together, cap each at 8 candidates, and bias for recall — a missed bug ships:

- **Line-by-line diff scan** — every changed line: what input, state, timing, or platform makes this wrong? Inverted conditions, off-by-one, missing `await`, falsy-zero, copy-paste vars, swallowed errors.
- **Removed-behaviour auditor** — for each deleted/replaced line, name the invariant it enforced. Find where the new code re-establishes it. If you can't, that's a candidate.
- **Cross-file tracer** — for each touched function, grep callers. Does the change break a call site (new precondition, new exception, changed return shape)?
- **Language-pitfall specialist** — classic footguns for the diff's language/framework.
- **Wrapper/proxy correctness** — for any new wrapper/cache/adapter, verify methods route to the wrapped instance, not back through a registry/global.
- **Reuse / simplification / efficiency** — new code that re-implements existing helpers; redundant state; wasted work.
- **Altitude** — special cases layered on shared infrastructure where the underlying mechanism should be generalised.

If the user passed extra context, add an extra finder angle scoped to that concern.

## Phase 3 — Verify

Dedup candidates pointing at the same mechanism. Then verify each survivor against the actual code — trace the path, don't pattern-match. A fresh-context verifier agent (given the diff + the relevant files) earns its cost when checking the claim means reading files you'd otherwise have to hold in context, or when you want an unprimed second opinion on a candidate you drafted yourself; otherwise verify it inline. Each verdict is one of:

- **CONFIRMED** — name the inputs/state and the wrong output. Quote the line.
- **PLAUSIBLE** — mechanism real, trigger uncertain. State what would confirm it.
- **REFUTED** — quote the line that disproves it.

Keep CONFIRMED + PLAUSIBLE. Recall mode: a single non-REFUTED vote carries the finding.

## Phase 4 — Sweep

One more pass over the diff as a fresh reviewer holding the verified list, looking only for gaps. This is the one place a subagent is usually worth it even on a small diff — an unprimed context is the entire point of the pass. Don't pad; if nothing new, return empty.

## Phase 5 — Write the comments in the user's voice

**Everything important goes in inline comments.** The top-level review `body` (the summary written when the review is created) frequently gets dropped and only the inline comments survive to be posted. Never put a finding, caveat, or piece of context the user needs solely in the top-level `body` — treat it as throwaway. If a point matters, anchor it to a line as an inline comment. Keep the top-level `body` to at most a short throat-clear (or leave it empty).

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

The top-level `body` is unreliable — it often gets dropped, leaving only the `comments` array. So every finding and every piece of context the user needs must live inside `comments` as an inline comment anchored to a line. Do not stash anything load-bearing in the top-level `body`.

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

Typical workflow: agent drafts comments → user reads, tweaks, deletes some, then comes back asking for more / for rewrites. **Re-run the state check from Phase 1 before every follow-up.** The user may have submitted the review since you last looked — everything in this section applies only while it's still `PENDING`, and the second-round rules below apply once it isn't.

While it is pending, **every follow-up must stay in that same review.** The REST `POST /pulls/{n}/comments` endpoint won't work while a pending review exists — it errors with `user_id can only have one pending review per pull request`. Use GraphQL instead.

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
| Check review state       | REST `GET /pulls/{n}/reviews` → `.state`, `.commit_id`                                  |
| Read threads + replies   | GraphQL `pullRequest.reviewThreads` → `isResolved`, `comments`                          |
| Create pending review    | REST `POST /pulls/{n}/reviews` (omit `event`)                                           |
| List pending comments    | REST `GET /pulls/{n}/reviews/{id}/comments` or GraphQL `reviews(states: PENDING)`       |
| Add comment to pending   | GraphQL `addPullRequestReviewThread` (with `pullRequestReviewId`)                       |
| Edit pending comment     | GraphQL `updatePullRequestReviewComment` (with comment node ID)                         |
| Delete pending comment   | REST `DELETE /pulls/comments/{id}`                                                      |
| Get review node_id       | REST `GET /pulls/{n}/reviews/{id}` → `.node_id`                                         |
| Get comment node_ids     | GraphQL `repository.pullRequest.reviews(states: PENDING).nodes.comments.nodes[].id`     |
| Reply to submitted comment | REST `POST /pulls/{n}/comments` with `in_reply_to` (only once nothing is pending)      |
| Submit (DO NOT)          | REST `POST /pulls/{n}/reviews/{id}/events` — never call this                            |

### After the user has submitted (second round)

The user submits outside this session, so the first sign is the state check: your review now reads `COMMENTED` / `CHANGES_REQUESTED` / `APPROVED` instead of `PENDING`, and there may be author replies on the threads. When that's the case:

- **Don't edit or delete the submitted comments.** They're public and already read. Editing rewrites history under a conversation in progress. If the user explicitly asks to change one, say what it'll look like to the author first.
- **Reply in-thread** to answer the author or concede a point — `in_reply_to` takes the original comment's `id`:
  ```bash
  gh api -X POST /repos/<owner>/<repo>/pulls/<n>/comments \
    -F in_reply_to=<comment_id> --raw-field body="$BODY"
  ```
  This endpoint works now — the "one pending review" restriction only bit while a pending review existed. Same voice rules as Phase 5.
- **Review the new commits, not the whole PR again.** Diff from the submitted review's `commit_id` to `HEAD`. A finding that's now fixed is done — don't re-raise it. A finding that *isn't* fixed belongs in the existing thread as a reply, not as a fresh comment on the same line.
- **New findings go in a new pending review** — same Phase 6 mechanics, same non-negotiable: don't submit it.

## Conduct

- **Push back on your own findings when challenged.** If the user questions a finding, walk through the actual code path — don't capitulate, but don't dig in either. Many "bugs" survive draft and dissolve on a second look. Delete the comment if it doesn't hold up.
- **Don't claim certainty you don't have.** Use the voice's hedges (`probably`, `I think`, `not sure`) when uncertain — they're stylistically aligned and intellectually honest.
- **Severity gate.** Correctness > altitude/duplication > style. If the cap forces a cut, drop nits first.
- **Don't assume the state of your own review.** The user submits outside the session, the author pushes between turns. Check before you edit, delete, or re-raise anything.
- **Don't review what you can't see.** If a finding depends on caller behaviour you haven't grepped, either grep first or downgrade to PLAUSIBLE.
