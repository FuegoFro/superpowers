---
name: subagent-driven-development
description: Use when executing implementation plans with independent tasks in the current session
---

# Subagent-Driven Development

Execute plan by dispatching a fresh implementer subagent per task, a task review (spec compliance + code quality) after each, and a broad whole-branch review at the end.

**Core principle:** Fresh subagent per task + task review (spec + quality) + broad final review = high quality, fast iteration

**Narration:** between tool calls, narrate at most one short line — the
ledger and the tool results carry the record.

**Continuous execution:** Do not pause to check in with your human partner between tasks. Execute all tasks from the plan without stopping. The only reasons to stop are the four named below, or all tasks complete. "Should I continue?" prompts and progress summaries waste their time — they asked you to execute the plan, so execute it.

**Rulings, not stalls.** A running plan does not wait on a human. Conflicts,
ambiguities, plan defects, a cap you would have asked to exceed — decide
them. The spec is the binding authority, the plan is its argument, and your
judgment settles what neither answers. Record every decision in the ledger as
`Ruling: <what you decided> — <why> — <what it costs if wrong>`, and keep
going. A wrong ruling costs rework your human partner can see and undo; a
session parked on a question costs their whole day and buys nothing.

Four things stop you, and only these: an irreversible or destructive
operation; a security-sensitive action; a side effect outside this worktree
that norms say you ask about first (a merge, a push to a shared branch, a
publish); and a plan so broken that every path forward is a guess. For those,
stop and ask.

## When to Use

Use this skill when you have a plan whose tasks are mostly independent and
your human partner has not chosen inline execution. Tightly coupled tasks,
or no plan yet: execute manually or brainstorm first. Partner chose inline,
or no subagent tool: superpowers:executing-plans. The decision graph, how
this differs from inline execution, and why subagents never inherit your
session's context: [process.md](process.md).

## The Process

Per task: dispatch an implementer, answer its questions, review the task
(spec compliance and quality), and run the fix loop — five rounds at most,
then adjudicate — until the review is clean; then ledger the completion.
After the last task: one final whole-branch review, one fix wave with one
scoped re-review, delete the workspace, finish the branch. The flow graph is
in [process.md](process.md).

## Setup

Ensure the work happens in an isolated workspace: use
superpowers:using-git-worktrees to create one or verify the existing one.
Never start implementation on a main/master branch without your human
partner's explicit consent.

Conversation memory does not survive compaction. In real sessions,
controllers that lost their place have re-dispatched entire completed task
sequences — the single most expensive failure observed. Track progress in
a ledger file, not only in todos.

- Each plan owns a workspace: at skill start, run this skill's
  `bash scripts/sdd-workspace PLAN_FILE` — it prints the plan's git-ignored
  directory (under `<repo-root>/.superpowers/sdd/`), home to
  every artifact for THIS plan: ledger, briefs, reports, review packages.
  Another plan's directory is never yours to read or write.
- Check for this plan's ledger at `<workspace>/progress.md`. If its first
  line names your plan file, tasks with a `Task <N>: complete` line are DONE
  — do not re-dispatch them; resume at the first task without one. A task
  whose last line is a fix round is mid-loop: resume the loop at the next
  round. A ledger whose first line names a different plan file — or a stray
  ledger at the old flat path `.superpowers/sdd/progress.md` — is another
  plan's progress: leave it in place and start your own, fresh.
- Create the ledger with its identity as the first line:
  `# SDD ledger — plan: <plan file path>`.
- The ledger is your recovery map: the commits it names exist in git even
  when your context no longer remembers creating them. After compaction,
  trust the ledger and `git log` over your own recollection.
- `git clean -fdx` will destroy the workspace (it's git-ignored scratch); if
  that happens, recover from `git log`.

Read the plan once, note its context and Global Constraints, and create a
todo per task (`bash scripts/task-brief PLAN_FILE --outline` maps a large
plan's tasks and sections by line range and size). If the plan names a Spec, read that too: the spec is the
authority the plan argues from, and conflicts inside the plan resolve
against it. A plan with no reachable spec gets a ledger note saying so —
rulings made without one are provisional.

Before dispatching Task 1, scan the plan once for conflicts (tasks that
contradict each other or the Global Constraints, and anything the plan
mandates that the review rubric treats as a defect) and write the table
[preflight-scan.md](preflight-scan.md) describes to the ledger; "the scan
is clean" without its rows is not a scan you ran. Rule on each finding
before execution begins, the spec as the binding authority; the review loop
remains the net for conflicts that only emerge from implementation.

## Model Selection

Use the least powerful model that can handle each role to conserve cost and increase speed.

**Always specify the model explicitly when dispatching a subagent.** An
omitted model inherits your session's model — often the most capable and
most expensive — which silently defeats this section.

You choose a model on every dispatch, so the tiers stay here:

- Implementer whose plan text holds the complete code (transcription plus
  testing), or a single-file mechanical fix: the cheapest tier.
- Implementer working from prose, and task reviewers: mid-tier at least.
  Turn count beats token price: the cheapest models routinely take 2-3× the
  turns on multi-step work, costing more overall.
- Multi-file integration or debugging: a standard model. Design judgment,
  and the final whole-branch review: the most capable available model.
- Scoped re-review of a small fix diff: cheap-to-mid. Fix rounds 4-5: at
  least one tier above the implementer that got stuck.

Complexity signals and the full text: [model-selection.md](model-selection.md).

## The Task Loop

Everything you paste into a dispatch prompt — and everything a subagent
prints back — stays resident in your context for the rest of the session
and is re-read on every later turn. Hand artifacts over as files.

**Batch small same-shape work** (tasks that are each the same small edit
across files go to one subagent and one review), and **when waiting on
subagents** never poll with short timeouts or sit in one silent,
open-ended wait. Both in detail: [task-loop.md](task-loop.md).

### 1. Dispatch the implementer

Record BASE (`git rev-parse HEAD`) before dispatching — the review package
and fix-round diffs need it.

- **Dispatch by reference:** run this skill's
  `bash scripts/dispatch implementer PLAN_FILE N --note NOTE_FILE` and send
  the one-line prompt it prints, with the model set on the call. It writes
  the task brief (the task's text plus the plan's shared header) and the
  filled template to the workspace. The note carries what the brief cannot:
  where the task fits, interfaces and rulings from earlier tasks, your
  resolution of any ambiguity, any plan section the script names as outside
  every brief. Exact values (numbers, magic strings, signatures, test
  cases) appear only in the brief, so the brief stays the single source of
  requirements. Never make a subagent read the whole plan file. Why: one
  session's 60 hand-filled dispatches came to 286k characters, all resident
  in the controller afterward.
- **Report file:** the implementer writes its full report beside the brief
  (`…/task-N-report.md`) and returns only status, commits, a one-line test
  summary, and concerns.
- The note describes one task, never the session's history, and the
  implementer never dispatches subagents, a reviewer least of all; the
  evidence for both is in [task-loop.md](task-loop.md).
- If an earlier task parked a finding in the area this task touches, carry
  a pointer to that ledger entry in the dispatch.
- Record the implementer's agent identity from the dispatch result —
  fix-loop rounds 1-3 resume this agent.
- Never dispatch multiple implementation subagents in parallel (conflicts).

Template: [implementer-prompt.md](implementer-prompt.md)

### 2. Handle the report

Implementer subagents report one of four statuses. Handle each appropriately:

**DONE:** If the plan mandates a commit trailer, first run `bash scripts/commit-check BASE HEAD --trailer 'LINE'`: implementers have substituted their own model's name, and a count over several commits has been misread as all present. A commit without it goes back to the implementer as a finding. Then render the task review (`bash scripts/dispatch reviewer PLAN_FILE N BASE HEAD`; BASE is the commit you recorded before dispatching the implementer — never `HEAD~1`, which silently drops all but the last commit of a multi-commit task) and dispatch the reviewer with the line it prints.

**DONE_WITH_CONCERNS:** Read the concerns first: correctness or scope concerns are addressed before review; observations are noted ([task-loop.md](task-loop.md)).

**NEEDS_CONTEXT:** The implementer needs information that wasn't provided. Provide the missing context and re-dispatch.

**BLOCKED:** The implementer cannot complete the task. Assess the blocker
(context, reasoning tier, task size, or a plan defect to rule on) as in
[task-loop.md](task-loop.md).

**Never** ignore an escalation or force the same model to retry without changes. If the implementer said it's stuck, something needs to change.

If the implementer asks questions — before starting or mid-task — answer
clearly and completely, provide additional context if needed, and don't
rush it into implementation.

### 3. Review the task

Per-task reviews are task-scoped gates. The broad review happens once, at the
final whole-branch review. Never skip the task review, and never accept a
report missing either verdict — spec compliance AND task quality are both
required. Implementer self-review never replaces the task review; both are
needed.

- Hand the reviewer files: `scripts/dispatch reviewer` fills the template
  with the same brief, the report file, the plan's Global Constraints
  verbatim, and a review package (commits, stat, full diff, the ledger's
  rulings and deferred findings) that never enters your context. The
  constraints block is the reviewer's attention lens. The reviewer's
  template already carries the process rules (YAGNI, test hygiene, review
  method) — the constraints block is for what THIS project's spec demands,
  so spec requirements binding this task beyond the plan's go in `--note`:
  exact values, exact formats, stated relationships between components
  ("same layout as X"). Never dispatch a task reviewer without a diff file
  (without bash: `git log`, `git diff --stat` and `git diff -U10` for the
  range, in one file).
- Do not add open-ended directives like "check all uses" or "run race tests
  if useful" without a concrete, task-specific reason
- Do not ask a reviewer to re-run tests the implementer already ran on the
  same code — the implementer's report carries the test evidence
- Do not pre-judge findings for the reviewer — never instruct a reviewer to
  ignore or not flag a specific issue. If you believe a finding would be a
  false positive, let the reviewer raise it and adjudicate it in the review
  loop. If the prompt you are writing contains "do not flag," "don't treat X
  as a defect," "at most Minor," or "the plan chose" — stop: you are
  pre-judging, usually to spare yourself a review loop.
The task reviewer may report "⚠️ Cannot verify from diff" items — requirements
that live in unchanged code or span tasks. These do not block the rest of the
review, but you must resolve each one yourself before marking the task
complete: you hold the plan and cross-task context the reviewer
lacks. If you confirm an item is a real gap, treat it as a failed spec
review — it enters the fix loop with the other findings.

Template: [task-reviewer-prompt.md](task-reviewer-prompt.md)

### 4. The fix loop

The loop triggers when the review reports spec ❌, any Critical or Important
finding, or a ⚠️ item you confirmed as a real gap.

Before the loop starts, two routes leave it immediately:

- Record Minor findings in the progress ledger as you go
  (`Task <N>: minor (deferred): <one-liner>`), and point the final
  whole-branch review at that list so it can triage which must be fixed
  before merge. A roll-up nobody reads is a silent discard. Minor findings
  never enter the loop.
- A finding labeled plan-mandated — or any finding that conflicts with
  what the plan's text requires — is yours to rule on: weigh the finding
  against the plan text, decide with the spec as the binding authority, and
  ledger the ruling before you act on it. Do not dismiss the finding because
  the plan mandates it, and do not dispatch a fix that contradicts the plan
  without a recorded ruling.
Everything else enters the loop. A fix round is one fix dispatch plus one
scoped re-review. Five rounds maximum per task:

**Rounds 1-3 — resume the original implementer** with the open findings
verbatim; its context is intact. **Rounds 4-5 — dispatch a fresh
implementer on a more capable model.** The fallback without resume, and the
round-4 framing: [fix-loop-escalation.md](fix-loop-escalation.md).

**Every round, either way:** the implementer fixes, re-runs the tests
covering the amended code, appends its fix report to the same report file,
and returns the short contract. Before re-dispatching the reviewer, confirm
the fix report contains the covering tests, the command run, and the
output; dispatch the re-review once all three are present. Name the
covering test files in the fix message — a one-line fix does not need the
whole suite.

**The re-review is scoped.** Run `bash scripts/dispatch re-review PLAN_FILE N FIX_BASE HEAD --note FINDINGS_FILE`
(FIX_BASE: the head the previous review saw; the note: the open findings
verbatim) to fill [re-review-prompt.md](re-review-prompt.md). The re-reviewer verdicts
each finding ADDRESSED or NOT ADDRESSED and flags new breakage in the fix
diff only. New Critical/Important breakage in the fix diff joins the open
findings list. Out-of-scope observations go to the ledger as deferred
minors — they never extend the loop.

**After each round,** append to the ledger:
`Task <N>: fix round <R>/5 (<X> addressed, <Y> open — <finding one-liners>; commits <a7>..<b7>)`

Never fix findings yourself in the controller session — your context stays
clean for coordination, and controller fixes skip review.

**The breaker.** When round 5's re-review still leaves findings open, stop
dispatching and adjudicate each open finding yourself: park it with a
`Ruling:`, or rule on the smallest change that unblocks dependent work. The
three cases are in [fix-loop-escalation.md](fix-loop-escalation.md).

Adjudicate only at the cap. Adjudicating earlier to end a loop is
pre-judging with a different name. Every adjudication is a ledger entry —
a silent discard is forbidden.

### 5. Complete the task

When the review comes back clean — or every open finding is parked with a
ruling at the cap — append the completion line to the ledger in the same
message as your other bookkeeping:

- `Task <N>: complete (commits <base7>..<head7>, review clean)`
- `Task <N>: complete (commits <base7>..<head7>, <K> parked)` after a
  tripped breaker

Then mark the todo complete and move on. Never move to the next task while
the review has open Critical/Important issues that are neither fixed nor
parked-with-ruling at the cap.

## Final Review

**Run the host's review machinery first:** in Claude Code `/code-review`,
`/security-review` when the diff touches auth, input handling or secrets, and
`/simplify` plus any repo-specific pass (order and reasons:
superpowers:requesting-code-review Step 0). Fold what they report into the
findings list below. They read the diff for defects; the reviewer below reads
it against the plan. Run both.

Run `bash scripts/dispatch final PLAN_FILE MERGE_BASE HEAD --note NOTE_FILE`
(MERGE_BASE: where the branch started, e.g. `git merge-base main HEAD`; the
note: what was built, and the spec path) and dispatch on the most capable
available model. It fills
[code-reviewer.md](../requesting-code-review/code-reviewer.md) with the
plan's shared header and a review package ending in every `Ruling:` and
deferred-minor line from the ledger, so the reviewer can triage which must
be fixed before merge. That is not pre-judging: each ruling arrives with its
cost if wrong, to weigh and re-grade, and none says what not to flag.

If the final whole-branch review returns findings, dispatch ONE fix subagent
with the complete findings list — not one fixer per finding.
Per-finding fixers each rebuild context and re-run suites; a real
session's final-review fix wave cost more than all its tasks combined.
The fixer writes its report to `<workspace>/final-fix-report.md`. Then run
exactly one scoped re-review of the fix wave
(`bash scripts/dispatch re-review PLAN_FILE final FIX_BASE HEAD --note FINDINGS_FILE`).
Adjudicate any residual findings as in the task loop's breaker: park with
rulings, or rule on the load-bearing ones and ledger what you decided. Only
the four classes above stop you here. There is no second fix wave —
residual load-bearing findings surface to your human partner when
finishing-a-development-branch presents the options.

## Finish

Before you delete anything, collect every ledger line containing `Ruling:` —
preflight rulings, parked findings, breaker adjudications, all of them — into
your final message under "Rulings I made", in the order you made them, each
with what it costs if wrong. The list is exhaustive: if the ledger holds a
ruling, the list holds it. That list is the only place the decisions you
took on your human partner's behalf reach them — they read it and rework
whatever you got wrong. A ruling that dies with the workspace was a decision
made in secret.

When the final whole-branch review is clean and its fixes are merged,
delete this plan's workspace (`rm -rf <workspace>`) — the git history is
the record now. Sibling directories belong to other plans; leave them
alone.

Use superpowers:finishing-a-development-branch.

## Common Rationalizations

| Excuse | Reality |
|--------|---------|
| "Close enough on spec compliance" | Reviewer found spec gaps = not done. Fix or hit the cap and adjudicate — those are the only exits. |
| "I'll fix it myself, dispatching is overhead" | Controller fixes pollute your context and skip review. Resume the implementer. |
| "One more round will converge" | Past the cap, rounds don't converge — the failure is structural. Adjudicate and route. |
| "The reviewer will just find something new anyway" | Scoped re-reviews verify fixes; they cannot wander. New findings on untouched code go to the ledger, not the loop. |
| "This finding is obviously wrong, I'll drop it" | You adjudicate only at the cap, and every ruling is a ledger entry. Silent discards are forbidden. |
| "The fix was small, skip the re-review" | Unreviewed fixes are how regressions land. Every round ends with a scoped re-review. |
| "Reviews slow the loop down" | The loop without reviews is just unverified churn. Reviews are the loop's brakes and steering. |
| "Ledger bookkeeping is overhead" | The ledger is what survives compaction. Controllers without one have re-dispatched entire completed task sequences. |
| "The implementer spawned its own reviewer — free extra assurance" | It's a duplicate seat reviewing the same diff; the task review is the gate. A worker-spawned reviewer is a defect to flag, not rigor. |

## Example Workflow

A worked session, from setup through the final review: [example-workflow.md](example-workflow.md).
