# Testing at the Boundary

**Load this reference when:** deciding what a new test should drive and
what it should replace; when tests keep breaking on refactors that changed
no behavior; or when an expected value is starting to look like a copy of
the code's own output.

## Overview

`writing-good-tests.md` says what a single test must do: name the break it
catches and exercise the real thing. This reference is about where to
stand when you write it. The short version:

```
Drive the boundary the caller sees.
Fake only the slow or external edge.
Let everything in between run for real.
```

These are guidelines with reasons, not gates. When one does not fit,
say so and say what you are doing instead.

Sources, worth reading in full:

- matklad, *Unit and Integration Tests* (2022): tests vary on two
  independent axes, purity and extent, and the unit/integration split
  confuses them.
- matklad, *How to Test* (2021): test features, not code; route tests
  through one `check` entrypoint; make adding a case trivial; prefer
  data-driven and expectation tests.
- Ted Kaminski, *Testing at the Boundaries* (2019): a test written
  against a system boundary "can almost never become technical debt";
  tests against internals get deleted the first time the design moves.

## The Two Axes

**Purity** is how much I/O and environment a test touches: network,
disk, clock, subprocesses, other services. Purity buys speed and
determinism. Each step toward impurity costs roughly half an order of
magnitude in runtime and adds a way to flake.

**Extent** is how much of the codebase a test runs. Extent is nearly free.
Running the whole command instead of one function costs microseconds and
buys fidelity: the test sees what the caller sees.

The unit/integration vocabulary treats these as one dial. They are two.
The productive shape is **high purity, natural extent**: fake the edge
where the real world comes in, and let the test cover all the real code
between the entrypoint and that edge. Mocking your own modules to shrink
extent gains nothing on speed and makes the suite brittle under refactor.

Sometimes you will choose lower purity on purpose, such as an end-to-end
run against an emulator or a real database. That is a legitimate trade
for fidelity the fakes cannot provide, made knowingly and kept to a
small number of tests.

## Guidelines

**Drive the boundary the caller sees.** Invoke the entrypoint a user or
another program would: the CLI with its arguments, the HTTP route, the
public function of a library. Assert on what comes out of the other side:
the writes, the response, the exit code. A test that imports an internal
helper is a bet that the helper survives the next design change. Ask
matklad's question: would this test still make sense if the whole
implementation were replaced by an opaque box with the same interface?

**Fake the edge, keep the extent.** Replace the things that are slow,
remote, or non-deterministic: network clients, the clock, secret lookups,
the filesystem when it matters. Replace them with one stateful fake per
external that records what was written to it and can be told to fail.
Everything between the entrypoint and that fake runs for real. A
per-test pile of patches on your own functions is a sign the fake is at
the wrong level.

**Route tests through a small number of entrypoints.** A `run(inputs,
*args)` or `check(input, expected)` helper is the one place that knows
the API under test. When the signature changes, one line changes. When a
second entrypoint appears, ask whether it is a second boundary or a leak
into the internals.

**Make adding a case trivial.** Factories with keyword overrides for the
input data, a base case that is obviously ordinary, neutral names in the
fixtures. If a new scenario costs three lines, people write it. Test
names read as sentences about behavior; classes or files group by
scenario, not by the function under test.

**Rendered output gets expectation tests.** For text, markup, or any
structured output a human will read, compare against a stored expected
file with a flag to regenerate it, instead of asserting substrings.
Substring assertions write the body down twice and fail on every
copy edit while sleeping through layout bugs. Keep a few targeted tests
beside the expectation files for behavior a diff would not explain by
itself: a marker that must lead, a round-trip that must hold, an input
that must be rejected.

**Hand-write the first expected file.** An expectation test whose first
version was generated from the code has never been red and proves only
that the code produces what the code produces. Write the first one by
hand, watch it fail, then implement. From then on a reviewed diff of the
regenerated file is enough. Regenerating without reading the diff turns
the flag into a "make it green" button.

**A test that can only fail on a decision is a change detector.** A
decision is a deliberate change: renaming a field, rewording a message,
changing a constant. A mistake is an accidental one: the wrong branch, a
missing write. If nothing but a decision can fail the test, such as
grepping a query string for a column name or asserting a removed thing
stays removed, delete it and model the contract as a type or an
expectation test instead. `writing-good-tests.md` covers this in depth.

**The fake defines a coverage hole.** Whatever code sits between the fake
and the real external is not exercised by the wide tests at all, because
the fake replaced it. That code, typically a thin client that shapes
requests and parses responses, earns its own tests at its own boundary,
driven with recorded or hand-built responses. Lower layers that the wide
tests do reach, and that nothing else consumes as an interface, need no
tests of their own; adding them is testing internals with extra steps.

**When a design change forces a whole suite to change, it was testing
internals.** Kaminski's team deleted an entire test suite after a merge
of two subsystems, because every change either broke nothing or broke
everything. That is the signal. Do not port such a suite to the new
shape; write boundary tests for the behavior it was protecting and let it
go.

## How This Composes With Red/Green

Boundary tests fit the TDD cycle well, with some texture worth knowing.

- **RED means the feature is missing.** You know the arguments and the
  expected writes before you know the modules, so the first test is
  writable before any implementation exists, and its failure means
  something. Internal-unit RED often means only that a helper you have
  not typed yet does not exist.
- **REFACTOR is free.** The third step is where internal tests hurt most.
  With boundary tests, restructuring the inside changes nothing the
  suite can see.
- **The first test is expensive; later ones are cheap.** The first
  scenario needs the fake, the `run` helper, and a command skeleton
  before it can go green, so "minimal code to pass" is a large step.
  After that each scenario is a few lines. Expect this; it is not TDD
  failing.
- **Fakes can drift from the real external.** Nothing in the cycle checks
  that the fake behaves like the thing it replaces. This is the accepted
  price of purity. Pay it knowingly, and cover the gap with a thin client
  test or an occasional lower-purity run when the cost of being wrong is
  high.
- **Open question: an already-green new scenario.** With wide extent, a
  new scenario sometimes passes on first run because the behavior fell
  out of the design. The TDD skill treats an immediately green test as a
  warning sign, and the discipline of "no behavior without a failing
  test" may still hold here if scenarios are written before the code that
  would satisfy them. Whether it does in practice is being tried, not
  settled. When it happens to you, check that the test names a break,
  consider whether the scenario is redundant, and record what you saw.

## Quick Reference

| When you... | Do |
|-------------|-----|
| Start a test file | Pick the boundary a caller uses; write one `run` or `check` helper |
| Reach for a mock of your own module | Move the fake outward to the real external instead |
| Add a fake | One stateful fake per external; record writes; allow failure injection |
| Test rendered output | Expectation file, first one by hand, later ones by reviewed diff |
| Find a test only a rename can fail | Delete it; model the contract as a type or expectation |
| Wonder if a lower layer needs tests | Yes if a fake hides it or others consume it; otherwise no |
| See a suite break wholesale on a refactor | Replace it with boundary tests; do not port it |
| Choose an emulator or real DB test | Fine; know it is a purity trade and keep the count small |

## Warning Signs

- Tests import a helper the entrypoint does not expose
- An export or alias exists only so tests can reach an internal
- The same `patch` block appears at the top of many tests
- A rename inside the module turns the suite red with no behavior change
- Expected text is a copy of the output, asserted in pieces
- The first expectation file was generated, never hand-written
- A regenerate flag was run without reading the resulting diff
- A test asserts that a removed symbol or string stays removed
