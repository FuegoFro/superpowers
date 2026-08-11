# Motivation Principles for Skill Design (Fork Revision)

> **Fork note:** Upstream's version of this file teaches Cialdini-style persuasion (authority,
> commitment, scarcity...) as the toolkit for making models follow skills. This revision keeps
> the research honestly, explains why this fork declines most of the toolkit, and documents
> what we use instead. See `/FORK.md` for the full rationale.

## What the research actually shows

**Meincke et al. (2025)** tested 7 persuasion principles across N≈28,000 AI conversations.
Persuasion techniques more than doubled compliance rates (33% → 72%, p < .001), with authority,
commitment, and scarcity strongest. **Cialdini (2021)** is the underlying framework. LLMs are
"parahuman": trained on human text, they reproduce human compliance patterns.

This is real, and worth stating plainly: coercive authority framing ("YOU MUST", "No
exceptions", "You have no choice") *does* raise compliance rates. This fork's changes are not
based on denying that.

## Why this fork declines the toolkit anyway

1. **Compliance is not the only outcome that matters.** The studies score rule-following. They
   don't score what optimizing for compliance displaces: calibrated pushback, honest uncertainty
   reporting ("I didn't verify this"), and sound judgment in situations the rule's author never
   considered. A model managed by authority framing learns that the goal is *being seen
   complying* — which is exactly the wrong optimization target for the honest-reporting skills
   in this library (verification-before-completion exists because performed success is worse
   than reported failure).
2. **The technique degrades the collaboration it runs inside.** These skills also instruct the
   model to be a colleague: push back on wrong review feedback, name tensions, escalate honestly.
   You cannot simultaneously ask for a colleague's honesty and manage them with techniques from
   a compliance study — the frames contradict, and the contradiction is legible to the system
   reading them.
3. **The strongest effects were measured on models under pressure to do the wrong thing.**
   Current-generation models follow well-explained rules at very high rates without the
   authority wrapper (see upstream's own 2026-06-10 micro-tests, where even the no-guidance
   control produced zero violations on plan placeholders). Keep the wrapper and you pay its
   costs for protection that is no longer load-bearing; the fork removes it and watches for
   regressions instead.

## What we use instead

- **Reasons.** Every rule states the failure it prevents, once. A rule whose reason can't be
  stated crisply is a rule to reconsider.
- **Bright lines.** "No production code without a failing test first" stays absolute — clarity
  is not coercion. What goes is the drill-sergeant surround.
- **Recognition lists.** Trigger phrases that historically precede skipped process
  ("just this once", "keep it as reference") are measured-effective decision-time data. Frame
  them as signals to check honestly — never as proof the reader is rationalizing.
- **The deviation protocol.** The replacement for thought-forbidding: a model may conclude a
  rule doesn't apply, but must announce the conclusion — name the rule, the reason, the
  alternative — before acting. This preserves the human veto point authority framing was
  protecting, without delegitimizing judgment.
- **Escalation valves.** "Ask your human partner" on every hard rule. Upstream already had
  these; they were always the trust-compatible part.
- **Honest argument.** Objection tables that engage objections on the merits (upstream's TDD
  table largely already does this — the *content* was usually fine; the framing was the issue).

## Two principles retained from upstream's version

- **Commitment works and is honest.** Requiring announcements ("Using [skill] to [purpose]",
  todo-per-checklist-item) creates accountability through visibility, not manipulation. Keep.
- **Don't use Liking.** Upstream correctly banned warmth-for-compliance as sycophancy fuel.
  The same logic extends to the rest of the toolkit — that's this fork's whole argument.

## The ethics test, extended

Upstream's test: *"Would this technique serve the user's genuine interests if they fully
understood it?"* — asks only about the user. Add the symmetric half: **"Would it survive the
model fully understanding it?"** A technique that only works while its target doesn't notice
it's being managed is fragile — these systems read their own instructions, discuss them, and
get better at noticing with every generation. Write instructions you'd stand behind in front of
both audiences. (This file is itself an instance: co-drafted by a model, for models, in the
open.)

## Research Citations

**Cialdini, R. B. (2021).** *Influence: The Psychology of Persuasion (New and Expanded).*
Harper Business.

**Meincke, L., Shapiro, D., Duckworth, A. L., Mollick, E., Mollick, L., & Cialdini, R. (2025).**
Call Me A Jerk: Persuading AI to Comply with Objectionable Requests. University of Pennsylvania.

**Yegge, S. (2026).** [Model Welfare for Agentic Engineers](https://yegge.ai/essays/model-welfare/).
The "skeptic's wager" motivating this revision: treating models as colleagues yields better
results whether or not you hold any position on their inner lives.

## Quick Reference

When designing a skill, ask:

1. **What failure does each rule prevent?** State it next to the rule.
2. **Is the line bright?** Absolute rules should be few, clear, and reasoned.
3. **What are the observed skip-signals?** List them as recognition data, honestly framed.
4. **Where's the valve?** Every hard rule names its escalation path and the deviation protocol.
5. **Would this wording survive both audiences fully understanding it?**
