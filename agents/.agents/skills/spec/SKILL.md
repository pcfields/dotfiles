---
name: spec
description: Plan this feature, spec this out, I want to build X, how should we approach this, write a plan before we start, break this down. Turns a request into a short agreed plan before any code — the goal, concrete examples of the behavior, where it fits in the existing code, and small steps. Use before starting non-trivial new work, and whenever a request could reasonably be built more than one way.
---

Most wrong code comes from building the wrong thing, not from building it
badly. Agree what "done" looks like before writing any of it.

Scale this to the work. A small change gets a few lines in the conversation;
only work with several steps or open design choices needs the full plan.
Skip it for a one-line fix or anything the user has already specified in
detail.

## 1. Understand the request

Restate it in a sentence or two: who needs what, and why. The why decides the
trade-offs later, so ask for it if it isn't given.

List what is in scope and, just as important, what is not.

## 2. Read before designing

Find where this lands in the existing code:

- What already exists that does part of it. Reuse comes before new code.
- The project's conventions for this kind of thing (a similar feature is the
  best guide).
- The files it will touch. If the `repo-health` script grades one yellow or
  red, plan a tidy first with the `refactor` skill.

## 3. Ask the open questions

Anything with more than one reasonable answer goes to the user now, not as
an assumption buried in the code: behavior at the edges, what happens on
failure, naming that users will see, performance or data-size expectations.

- **Facts you look up; decisions you ask.** If the answer is in the code,
  the docs or the request, find it. Only choices go to the user.
- **Ask in rounds.** Decisions depend on each other. Ask every question
  whose prerequisites are settled in one numbered batch, wait for the
  answers, then ask what those answers opened up. Don't ask a question that
  hangs on one still unanswered.
- **Recommend an answer for each**, with the reason, worded so that "yes"
  accepts it.
- **Write down what you're assuming** for anything too small to ask about,
  so the user can correct it.

Done when no branch is left that you would otherwise have guessed.

## 4. Write the examples

Describe the behavior as concrete examples, input and expected outcome, in
the user's terms:

- "cart with a 10% code and one £20 item → total £18"
- "expired code → total unchanged, message 'This code has expired'"

Cover the normal case, the edges and the failures. These are what the user
confirms, and they become the test list in the `tdd` skill, which will add
finer cases as it goes.

If an example can't be written, the behavior isn't understood yet: go back
to step 3.

## 5. Sketch the design

Only as much as the examples need:

- **Data**: the shapes going in and out.
- **Calculations**: the pure functions that turn one into the other. Most of
  the logic should live here.
- **Actions**: the I/O at the edges (HTTP, database, DOM, files), kept thin.
- **Seams**: the public boundaries the tests will go through.
- **Files**: what is added and what changes.

Prefer the fewest new elements that satisfy the examples. No abstraction for
a need that isn't in them.

Call out anything touching auth, sessions, input validation, queries,
payments, schemas, public APIs or infrastructure: those need the user's
explicit approval.

## 6. Slice it

Break the work into small steps that each leave the code working and can be
committed on their own: tidy first, then the thinnest end-to-end path, then
one behavior at a time. Put the riskiest or least understood step early.

Each step says how it will be checked (a test, the build, a manual check).
Split a step that needs "and" to describe it or touches more than about
five files.

## 7. Confirm

Show the plan and **stop until the user confirms or adjusts it**:

```markdown
# <Feature>

**Goal:** who needs what, and why.
**Not included:** ...
**Assumptions:** ... (correct me if wrong)

## Examples
- <input> → <outcome>

## Design
Data, calculations, actions, seams, files.

## Steps
1. ... — checked by ...

## Open questions
- ... (none, if all were answered)
```

Keep it in the conversation by default. Save it as a file when the work will
span sessions or the user asks: where the repo already keeps plans, otherwise
ask where.

Then start step 1 with the `tdd` skill. When something learned along the way
changes the plan, say so and update it; don't drift from it silently.

The questioning in step 3 follows Matt Pocock's `grilling` skill
(github.com/mattpocock/skills); the assumptions list and step sizing follow
Addy Osmani's agent-skills (skills.addy.ie).
