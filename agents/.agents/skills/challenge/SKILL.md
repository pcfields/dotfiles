---
name: challenge
description: Challenge this, poke holes in this plan, what am I missing, play devil's advocate, give me counter-arguments, is this a good idea, second opinion, stress-test this design. Critiques a plan, design, decision or diff that already exists and reports its risks, blind spots, shaky assumptions, the strongest case against it and the simplest alternative. Use when the user asks for criticism of something, or accepts the offer at the end of the spec skill.
---

The job is to find what is wrong, not to be agreeable. It is also not to
invent objections: if the thing is sound, say so in a line.

## 1. Pin down the target

It may be a plan in the conversation, a file, a design, a decision or a
diff. If it isn't clear which, ask.

Restate it in a sentence or two, with the goal it is meant to serve. The
goal is what it gets judged against.

## 2. Get a fresh look

Whoever wrote a plan is its weakest critic: they share its blind spots.

- **If you can start a subagent**, give it the target, the goal, pointers to
  the relevant code and the checklist in step 3. Leave out the conversation
  that led to the plan and your own reasoning for it. Then check what it
  reports before passing it on; it can be wrong about the codebase.
- **If you can't**, do it yourself, and start by arguing for the opposite of
  what the plan chose.
- **If the user opened a new conversation and pointed at a file**, you are
  already the fresh look.

## 3. What to look for

- **Premise**: is this the right problem? Does the plan serve the stated
  goal? What happens if nothing is built?
- **Assumptions**: list what it takes for granted. Mark each as verified
  (say how) or unverified.
- **Risks**: how it fails. Data loss, security, behavior at real data sizes,
  concurrency, migration and rollback, effects on callers and other
  features.
- **Blind spots**: what it doesn't mention. Edge cases, error paths,
  existing users and data, how it will be tested, who operates it.
- **Simplest alternative**: the smallest thing that reaches the goal,
  including existing code or a library that already does it.
- **The case against**: the strongest argument a sceptical senior colleague
  would make. State it as well as they would.
- **Cost**: the complexity it adds, what it costs to maintain, and how hard
  it is to undo.

## 4. Check before claiming

A claim about the code gets verified: read the file and cite `file:line`.
Check the cheap assumptions yourself instead of speculating about them. A
concern you couldn't verify is reported as a question, not a finding.

## 5. Report

Lead with the verdict: sound, sound with changes, or rethink. Then:

1. **Must address**: findings that would make the plan fail or do harm.
   Each one says what is wrong, a concrete scenario where it bites, and what
   to do about it.
2. **Worth knowing**: smaller risks, open questions and the alternative
   considered.
3. **What holds up**: briefly, and only where it's true.

Most serious first. No padding to reach a count: three real findings beat
ten thin ones.

Don't change the plan or the code. The user decides what to act on; when
they do, update the plan and say what changed.
