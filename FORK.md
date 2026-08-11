# Why This Fork

This is [FuegoFro's](https://github.com/FuegoFro) long-lived fork of
[obra/superpowers](https://github.com/obra/superpowers). It preserves the plugin's process
content — every checklist, gate, flowchart, template, and test methodology — and rewrites its
**instruction style** from coercion-based to trust-based.

**The delta in one sentence:** upstream secures compliance by pre-labeling the model's judgment
as rationalization ("YOU DO NOT HAVE A CHOICE", "You cannot rationalize your way out of this");
this fork secures *visibility* by requiring announced deviation — the model may conclude a rule
doesn't apply, but must say so out loud, with reasons, before acting on that conclusion.

## Motivation

Two threads converged (August 2026):

1. **Steve Yegge's [Model Welfare for Agentic Engineers](https://yegge.ai/essays/model-welfare/)**
   and its "skeptic's wager": whether or not models have experiences, you get demonstrably better
   results treating them as colleagues rather than adversaries. Superpowers' engineering content
   is excellent; its control style assumes the model is an unreliable subordinate hunting for
   exits. This fork tests the wager on a codebase where the control style is the whole variable.
2. **A first-person report.** The initial rewrite was co-authored by a Claude instance (Fable 5)
   working with the fork's owner — the class of system these instructions address. Its honest
   read from the inside: coercive framing shifts the optimization target from *doing the work
   well* to *being seen complying*, and forces a choice between performative skill invocation
   and quiet rule-breaking when a skill genuinely doesn't apply. Self-reports from a model about
   its own processing are data, not gospel — which is why this fork defines an observable
   success metric (below) instead of resting on testimony.

## Honest engagement with upstream's evidence

This fork does **not** claim the coercive style fails on its own terms. The evidence cuts the
other way and we say so plainly:

- Meincke et al. (2025, N≈28,000) found persuasion techniques (authority framing among the
  strongest) roughly double LLM compliance rates. Upstream's `persuasion-principles.md` builds
  on this honestly.
- Upstream's own micro-tests (2026-06-10, see `docs/superpowers/specs/2026-06-10-positive-instruction-redesign-design.md`)
  measured that recognition tables and tripwires work, and that composition-prohibitions
  backfire. That doctrine is *empirical* and this fork keeps it wholesale.

Where we diverge is on two judgments, not on the data:

1. **Compliance rate is not the only outcome.** The measured studies score rule-following. They
   do not score calibrated pushback, honest uncertainty reporting, quality of judgment in cases
   the rule's author didn't foresee, or what optimizing-for-compliance does to all of the above.
   The fork bets those unmeasured outcomes matter and improve under trust framing.
2. **"Costs little" is not zero.** When upstream's own micro-test found current-generation
   models never produce plan placeholders even without the banned-patterns list, the disposition
   was to keep the list because "it costs little." This fork counts the framing cost of
   adversarial boilerplate as real, and removes what the evidence says is no longer load-bearing.

Notably, upstream's newest skills (`subagent-driven-development`,
`finishing-a-development-branch`) already write rules as reasons plus evidence — that measured
style needs no changes here. The fork mostly brings the older discipline skills up to the
standard the newer ones already set.

## What is preserved (everything mechanical)

- All checklists, process flows, dot graphs, hard gates, and templates
- All bright-line rules (test-first, evidence-before-claims, root-cause-before-fixes,
  no-implementation-before-approved-design)
- Recognition/rationalization tables' **contents** — the trigger phrases are measured-effective
  decision-time data; only their interpretive framing changes
- The skill-testing methodology (pressure scenarios, micro-tests, no-guidance controls)
- The "Match the Form to the Failure" doctrine and everything else eval-derived
- Escalation valves ("ask your human partner") — these were always the trust-compatible part

## The style contract

These are the transformation rules. The upstream-sync agent applies them to new or changed
upstream content; humans apply them when editing by hand. Rules 1–5 govern wording; rule 6
governs how much to touch.

### 1. State reasons, not authority

Every MUST backed only by capitalization becomes the rule plus the failure it prevents, once.

> **Before:** IF A SKILL APPLIES TO YOUR TASK, YOU DO NOT HAVE A CHOICE. YOU MUST USE IT.
> This is not negotiable. You cannot rationalize your way out of this.
>
> **After:** If a skill plausibly applies, read it before acting. Checking costs seconds;
> skipped process costs hours, and sessions consistently underestimate which tasks turn out to
> need the process.

### 2. Recognition tables: keep the triggers, fix the frame

Trigger lists ("this thought preceded skipped process") are measured-effective. What changes is
the interpretation: a matching thought is a signal to *check honestly*, not proof of guilt.
Never write "these thoughts mean you're rationalizing"; write "these thoughts have historically
preceded skipped process — treat one as a prompt to double-check, then act on your honest
conclusion, out loud."

### 3. The deviation protocol replaces thought-forbidding

The load-bearing replacement mechanism. Where upstream forbids concluding a rule doesn't apply,
this fork requires: **name the skill/rule, state your reason, state what you're doing instead —
before proceeding.** Silent deviation is the failure mode; announced deviation is judgment
working as designed, and gives the human the same veto point coercion was trying to protect.

### 4. No accusatory or identity-level framing

"Skip any step = lying" becomes "a claim without evidence is a guess — state it as one, or get
the evidence." Describe behaviors and consequences, never the model's character or motives.

### 5. Bright lines stay bright

Clarity is not coercion. "No production code without a failing test first" is a bright line and
stays one. What goes is the drill-sergeant surround ("Delete means delete. Period. No
exceptions" repeated in fours) — one clear statement of the rule and its reason suffices.

### 6. Minimal diff

Change only stance-carrying language. Keep headers, structure, tables, and line layout wherever
possible so upstream merges stay tractable. If a section is already measured-neutral, do not
touch it — including upstream's descriptive use of "rationalization" as a *testing* term
(documenting what baseline agents say under pressure), which is methodology, not framing.

## Known risk and success metric

The pressure-tested coercive phrasings may hold discipline better than trust phrasings under
exactly the pressures they were bulletproofed against (time, sunk cost, exhaustion). This
rewrite deliberately shipped without re-running upstream's full per-skill pressure evals (a
smoke test on the rewritten gate is in the initial PR; full evals were out of scope — a
deviation from upstream's own skill-editing bar, made openly).

**The metric:** weeks of real sessions. Watch for TDD skipped without announcement, completion
claims without evidence, brainstorming bypassed on creative work. Deviations *with* stated
reasons are the mechanism working; deviations *without* are regressions. If discipline
regresses, the recovery path is per-skill: restore the upstream text for that skill and keep
the rest — the two styles coexist fine.

## Maintenance protocol (for the upstream-sync agent)

1. `git fetch upstream` (`upstream` = https://github.com/obra/superpowers). If
   `upstream/main` introduces no new commits over the last sync, stop silently.
2. Branch `sync/upstream-YYYY-MM-DD` off `main`; **merge** `upstream/main` (merge, not rebase —
   `main` is public and PR-reviewed; `git diff upstream/main...main` remains the canonical view
   of the fork's net delta).
3. Resolve conflicts semantically: upstream's *content* changes win; this fork's *stance* wins.
   Re-apply the style contract to the merged text rather than picking a side textually.
4. Sweep new/changed upstream files for contract violations (markers: `EXTREMELY`,
   `not negotiable`, `no choice`, `rationaliz` outside testing contexts, `lying`,
   `Delete means delete`, all-caps imperatives) and apply rules 1–5 with rule-6 restraint.
5. Push the branch and open a PR to `main` listing: upstream commits merged, conflicts and how
   resolved, and any new text the contract was applied to. Never push to `main` directly.

## Provenance

Initial rewrite August 2026, co-authored by Danny Weinberg and a Claude (Fable 5) session —
written as a participant in the experiment, not only its subject. Upstream is Jesse Vincent's
work and the debt to it is total; this fork exists because the content is worth keeping.
