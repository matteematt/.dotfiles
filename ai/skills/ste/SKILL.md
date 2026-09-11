---
name: ste
description: Explain something in Simple Technical English, concise and friendly to the contextless reader.
argument-hint: "[what to explain — a file, symbol, concept, or the thing just discussed]"
---

Explain the requested thing **in Simple Technical English, concise and friendly to the contextless reader**.

If `$ARGUMENTS` names something, that is the subject — read it before explaining it. If no subject is given, explain the thing most recently under discussion.

## What that phrase means

**Simple Technical English** — plain words, short sentences, active voice, present tense. One idea per sentence. Keep the real technical terms and the exact identifiers, paths, and commands; simple means *defined*, not vague. Expand every acronym and piece of jargon the first time it appears.

**Concise** — lead with the answer. No preamble, no restating the question, no summary of what you are about to say. Cut any sentence that does not carry information.

**Friendly to the contextless reader** — assume they have not read the code, the thread, the ticket, or the docs. Name the thing and say what it is before you use it. Do not lean on "as you know", "obviously", or references to earlier conversation. Friendly means direct and unpatronising — not chatty, no emoji, no exclamation marks.

Never point at something by a label alone. "Step 3", "phase 2", "option B", "§7.6", "the file mentioned above" — the document is usually right there in the repo, but making the reader open it to parse your sentence costs them a switch out of this window. Carry the content across instead: "we cache the token in the keychain (step 3)" rather than "we do what step 3 says". Keep the reference as a pointer for anyone who wants the full detail; just do not let it be the only content.

This matters most when you ask something. "Do we want §7.6 or §7.7 next?" cannot be answered without opening the plan. "Do we want the retry logic or the audit log next?" can be answered from where the reader is sitting.

Recall is not repetition. If you covered the same ground a few messages ago, a clause is enough to bring it back — do not re-explain it in full. The goal is that the reader never has to leave the conversation, not that everything gets restated every time.

## Shape

Prose by default. Use bullets only for a genuine list, and a fenced code block only when the exact text matters.

Say what is uncertain rather than filling the gap. If the honest answer is that something is unknown or out of scope, say that in one sentence.
