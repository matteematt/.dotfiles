---
name: ntfy
description: Post periodic progress updates about the current work to an ntfy.sh topic, written so a reader with no context can follow them — or stop posting with `off`.
argument-hint: "<topic> | off"
disable-model-invocation: true
---

`$ARGUMENTS` is either an ntfy.sh topic name or `off`.

- **A topic** — turn on progress updates to that topic for the rest of this session. Send one message straight away saying updates are on and what you are working on (or that you are waiting for a task). Then carry on with the work, if there is any.
- **`off`** — send one last message to the active topic saying updates are stopping, with a one-line summary of where the work stands. Then send nothing more to it. If no topic is active, say so and do nothing.
- **Empty** — ask which topic to use.

Running `/ntfy <topic>` while another topic is active switches to the new topic.

Updates stay on until `/ntfy off`. This includes after the conversation is compacted and across later tasks in the same session.

## How to send

```bash
curl -s -o /dev/null -H "Title: <short title>" -d "<message>" ntfy.sh/<topic>
```

- Add `-H "Tags: <tag>"` when it fits. ntfy shows tags as emoji: `white_check_mark` (done), `x` (failed or blocked), `warning` (needs attention), `hourglass` (long step started).
- Add `-H "Priority: high"` only when the work is blocked on the user, or when everything is done.
- Do not quote message text into the shell by hand if it has quotes or `$` in it. Pass it on stdin instead: `curl … --data-binary @- ntfy.sh/<topic> <<'EOF'` … `EOF`.
- If a send fails, carry on with the work. Do not retry more than once, and do not let the update block the task.

## When to send

Send at meaningful points, not on every tool call:

- when you start a task, with the plan in a sentence or two
- when a significant step finishes, such as a build, a test run, or a fix
- when something fails or the plan changes, and what you will do next
- when you are blocked on the user, or about to ask them something
- when the task is done

There is no schedule. Send when something is worth telling the reader, and not otherwise. If several small things happen close together, fold them into one message.

## How to write a message

The reader sees the message on a phone lock screen. They have not read the conversation, the code, or the ticket. They may not even remember which session or repo this is. Write for that person.

- **Title**: name the project or repo and the task in a few words, e.g. `dotfiles: tmux copy-mode keybinding`.
- **Body**: two to four short sentences in plain English. Say what you are doing, why, and what happened. Say what comes next, or what you need from the user.
- Expand labels and shorthand. Do not write "B3 tests pass" or "step 2 done". Write what B3 or step 2 actually is: "The tests for the new retry logic now pass (12 of 12). Next I am updating the docs to describe the new timeout setting."
- Give numbers and names when they help: how many tests, which file or service, which error.
- No markdown, no code blocks, and no long paths or stack traces. A short error message in quotes is fine.

Good:

> **Title:** api-gateway: fix flaky login test
> The login integration test failed about 1 time in 5 because it did not wait for the session cache to warm up. I added an explicit wait and ran the test 50 times with no failures. Next I am running the full test suite before preparing a commit.

Bad:

> fixed flake, running suite

## Privacy

ntfy.sh topics are public. Anyone who knows or guesses the topic name can read every message. Never put secrets, tokens, credentials, customer data, or internal URLs in a message. Describe the work at the level you would be comfortable posting in a public channel.
