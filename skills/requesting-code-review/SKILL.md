---
name: requesting-code-review
description: Use when completing tasks, implementing major features, or before merging to verify work meets requirements
---

# Requesting Code Review

Dispatch a code reviewer subagent to catch issues before they cascade. The reviewer gets precisely crafted context for evaluation — never your session's history.

**Core principle:** Review early, review often.

## When to Request Review

**Mandatory:**
- After each task in subagent-driven development
- After completing major feature
- Before merge to main

**Optional but valuable:**
- When stuck (fresh perspective)
- Before refactoring (baseline check)
- After fixing complex bug

## Step 0: Prefer the Host's Review Machinery

Before dispatching a reviewer of your own, check what review your harness and your repo
already ship. Claude Code provides `/code-review` (correctness plus reuse and simplification,
at a chosen effort level), `/security-review` (a security pass over the branch's changes), and
`/simplify` (quality-only cleanup, applied). Where the repo ships its own review commands —
a de-slop pass, a house-style check, an ownership-aware reviewer — those count too.

Prefer them, in this order: `/code-review` once per branch — not per task, where the reviewer
below is the gate and N host runs would be N times the cost; `/security-review` when the diff
touches authentication, authorization, input handling, secrets, or anything network-facing;
`/simplify` and the repo's own passes for quality. They are tuned to this codebase and its
conventions, their findings arrive in the shape the rest of the repo's tooling expects, and
they cost you one command instead of a dispatch you have to compose.

They do not cover everything. Spec compliance against a plan, and judgment about whether the
change was the right change at all, still want the reviewer below — run the host commands
first, act on what they find, and dispatch the subagent reviewer for the rest.
If none of these are available, the subagent reviewer is the whole review.

Anything they applied is code too. Commit their edits before capturing the SHAs below —
otherwise the reviewer reads a range that predates them, and an applied cleanup becomes the one
change on the branch nothing reviewed.

## How to Request

**1. Get git SHAs:**
```bash
BASE_SHA=$(git rev-parse HEAD~1)  # or origin/main
HEAD_SHA=$(git rev-parse HEAD)
```

**2. Dispatch code reviewer subagent:**

Dispatch a `general-purpose` subagent, filling the template at [code-reviewer.md](code-reviewer.md)

**Placeholders:**
- `{DESCRIPTION}` - Brief summary of what you built
- `{PLAN_OR_REQUIREMENTS}` - What it should do
- `{BASE_SHA}` - Starting commit
- `{HEAD_SHA}` - Ending commit

**3. Act on feedback:**
- Fix Critical issues immediately
- Fix Important issues before proceeding
- Note Minor issues for later
- Push back if reviewer is wrong (with reasoning)

## Example

```
[Just completed Task 2: Add verification function]

You: Let me request code review before proceeding.

BASE_SHA=$(git log --oneline | grep "Task 1" | head -1 | awk '{print $1}')
HEAD_SHA=$(git rev-parse HEAD)

[Dispatch code reviewer subagent]
  DESCRIPTION: Added verifyIndex() and repairIndex() with 4 issue types
  PLAN_OR_REQUIREMENTS: Task 2 from docs/superpowers/plans/deployment-plan.md
  BASE_SHA: a7981ec
  HEAD_SHA: 3df7661

[Subagent returns]:
  Strengths: Clean architecture, real tests
  Issues:
    Important: Missing progress indicators
    Minor: Magic number (100) for reporting interval
  Assessment: Ready to proceed

You: [Fix progress indicators]
[Continue to Task 3]
```

## Common Rationalizations

| Excuse | Reality |
|--------|---------|
| "A host review command ran, so the subagent review is redundant" | They answer different questions. `/code-review` reads the diff for defects; the subagent reviewer reads it against the plan the change was supposed to implement. A clean `/code-review` on code that built the wrong thing is still a clean review. |
| "I'll just review the diff myself instead of dispatching a reviewer" | You're the coordinator — reviewing the diff inline burns the context window you need to keep driving the work. Dispatch a reviewer subagent: the diff and the evaluation live in its context, and only the findings come back to you. |
| "The reviewer needs my whole session history to understand the change" | Hand it precisely crafted context, never your session's history. That keeps the reviewer on the work product, not your thought process. |

## Red Flags

**Never:**
- Skip review because "it's simple"
- Ignore Critical issues
- Proceed with unfixed Important issues
- Argue with valid technical feedback

**If reviewer wrong:**
- Push back with technical reasoning
- Show code/tests that prove it works
- Request clarification

See template at: [code-reviewer.md](code-reviewer.md)
