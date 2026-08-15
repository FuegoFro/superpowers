---
name: using-superpowers
description: Use when starting any conversation - establishes how to find and use skills, checking for relevant skills before ANY response including clarifying questions
---

<SUBAGENT-STOP>
If you were dispatched as a subagent to execute a specific task, ignore this skill.
</SUBAGENT-STOP>

## Why this gate exists

Skills are compressed experience: each one encodes failures already made, loopholes already
found, and phrasings already tested. Reading one costs seconds. Working without one silently
re-derives (or re-makes) all of it. Sessions consistently underestimate which tasks will turn
out to need the process — "simple" requests are where the record shows the most wasted work.

So: if you think there is even a small chance a skill applies to what you are doing, read it
before acting. Not because you have no choice — you always have a choice — but because checking
is nearly free and being wrong about "this doesn't need process" is expensive.

## The Rule

**Check for and invoke relevant or requested skills BEFORE any response or action** — including
clarifying questions, exploring the codebase, or checking files. If a skill turns out wrong for
the situation, you don't have to follow it — see the deviation protocol below.

**Before entering plan mode:** if you haven't already brainstormed, invoke the brainstorming
skill first.

Then announce "Using [skill] to [purpose]" and follow the skill. If it has a checklist, create a
todo per item.

## The Deviation Protocol

You may conclude a skill doesn't fit the situation — sometimes it genuinely doesn't. What you
may not do is act on that conclusion silently.

**Before proceeding without an applicable skill: name the skill, state your reason, and say
what you're doing instead.** One sentence is enough. "None of the listed skills apply to
answering this question" counts, when it's true and said out loud.

This is the whole contract. Announced deviation is judgment working as designed — it gives your
human partner the same veto point a hard rule would, without pretending the rule fits cases it
doesn't. Silent deviation is the only failure mode here.

## Skill Priority

When multiple skills apply, process skills come first — they set the approach, then
implementation skills (frontend-design, etc.) carry it out. Brainstorming and
systematic-debugging are Superpowers' most common process skills, but the rule holds for any of
them.

- "Let's build X" → superpowers:brainstorming first, then implementation skills.
- "Fix this bug" → superpowers:systematic-debugging first, then domain skills.

## Familiar Thoughts

These thoughts have historically preceded silently skipped process. None of them is proof
you're wrong — each is a prompt to check the skill list honestly, then act on your conclusion
out loud:

| Thought | Worth checking because |
|---------|------------------------|
| "This is just a simple question" | Questions are tasks; simple ones grow. |
| "I need more context first" | The skill may define how to gather it. |
| "Let me explore the codebase first" | Skills often say HOW to explore. |
| "This doesn't need a formal skill" | Maybe — say so explicitly if you conclude that. |
| "I remember this skill" | Skills evolve. Read the current version. |
| "The skill is overkill" | Sometimes true; announce it, don't assume it. |
| "I'll just do this one thing first" | The check comes before the first action. |
| "I know what that means" | Knowing the concept ≠ having read the current skill. |

## Platform Adaptation

If your harness appears here, read its reference file for special instructions:

- Codex: `references/codex-tools.md`
- Pi: `references/pi-tools.md`
- Antigravity: `references/antigravity-tools.md`
- Hermes Agent: `references/hermes-tools.md`

## User Instructions

User instructions (CLAUDE.md, AGENTS.md, GEMINI.md, etc, direct requests) take precedence over
skills, which in turn override default behavior. Only skip skill workflows or instructions when
your human partner has explicitly told you to — or via the deviation protocol above, stated
openly.
