#!/usr/bin/env bash
# Tests for SDD's plan slicing and dispatch rendering: scripts/task-brief
# carries the plan's shared header and ends a slab at the next same-or-higher
# heading; --outline and header modes; scripts/review-package appends the
# ledger's rulings and shows commit trailers; scripts/dispatch renders every
# template with no placeholder left over; scripts/commit-check fails on any
# commit that lacks a mandated trailer.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
SDD_SCRIPTS="$REPO_ROOT/skills/subagent-driven-development/scripts"

FAILURES=0
TEST_ROOT=""
# The templates' own placeholders. A rendered prompt may legitimately carry
# other bracketed words, copied in from the plan or the controller's note.
PLACEHOLDERS='\[(BRIEF_FILE|REPORT_FILE|GLOBAL_CONSTRAINTS|BASE_SHA|HEAD_SHA|DIFF_FILE|FINDINGS|FIX_BASE_SHA|DESCRIPTION|PLAN_OR_REQUIREMENTS)\]'

pass() { echo "  [PASS] $1"; }
fail() {
    echo "  [FAIL] $1"
    FAILURES=$((FAILURES + 1))
}

check() { # check DESCRIPTION COMMAND...
    local desc=$1
    shift
    if "$@"; then pass "$desc"; else fail "$desc"; fi
}

contains() { grep -Fq -- "$2" "$1"; }
lacks() { ! grep -Fq -- "$2" "$1"; }

cleanup() {
    if [[ -n "$TEST_ROOT" && -d "$TEST_ROOT" ]]; then
        rm -rf "$TEST_ROOT"
    fi
}

sum_outline_bytes() {
    awk '{ for (i = 1; i < NF; i++) if ($(i + 1) == "bytes") { s += $i; break } } END { print s + 0 }'
}

main() {
    echo "=== Test: SDD plan slicing and dispatch ==="

    TEST_ROOT="$(mktemp -d)"
    trap cleanup EXIT

    git init -q -b main "$TEST_ROOT/repo"
    local repo
    repo="$(cd "$TEST_ROOT/repo" && git rev-parse --show-toplevel)"
    local git_id=(-c user.email=t@example.com -c user.name=t -c commit.gpgsign=false)

    cat > "$repo/plan.md" <<'PLAN'
# Toy Plan

**Goal:** do two things.

## Global Constraints

- Every commit ends with `Co-Authored-By: Example Model <noreply@example.com>`.
- Output files use LF line endings.

## Review Focus

- empty input

## Amended: header amendment

Applies to every task.

### Task 1: First thing

Step one.

```markdown
## Not a heading inside a fence
```

#### Step 1.2

Detail.

## Amended: task 2 uses Z

Amendment between tasks.

### Task 2: Second thing

Step two.

## Self-review

Looks fine.
PLAN
    ( cd "$repo" && git add plan.md && git "${git_id[@]}" commit -qm fixture )

    # --- task-brief: shared header plus a slab that stops at its section end ---
    local err="$TEST_ROOT/err"
    (cd "$repo" && bash "$SDD_SCRIPTS/task-brief" plan.md 1 >/dev/null 2>"$err")
    local b1="$repo/.superpowers/sdd/plan/task-1-brief.md"
    check "brief carries the shared-header marker" contains "$b1" "## Shared header (from the plan)"
    check "brief carries Global Constraints" contains "$b1" "Output files use LF line endings."
    check "brief carries Review Focus" contains "$b1" "- empty input"
    check "brief carries an amendment placed in the header" contains "$b1" "Applies to every task."
    check "brief drops the plan's H1 title" lacks "$b1" "# Toy Plan"
    check "brief carries its task heading" contains "$b1" "### Task 1: First thing"
    check "a heading inside a fence does not end the slab" contains "$b1" "#### Step 1.2"
    check "Task 1's slab excludes the amendment that follows it" lacks "$b1" "Amendment between tasks."
    check "Task 1's slab excludes Task 2" lacks "$b1" "Step two."
    check "sections outside every brief are named on stderr" contains "$err" "## Amended: task 2 uses Z"

    (cd "$repo" && bash "$SDD_SCRIPTS/task-brief" plan.md 2 >/dev/null 2>&1)
    local b2="$repo/.superpowers/sdd/plan/task-2-brief.md"
    check "the last task's slab excludes a trailing Self-review" lacks "$b2" "Looks fine."
    check "the last task's slab carries its own text" contains "$b2" "Step two."

    (cd "$repo" && bash "$SDD_SCRIPTS/task-brief" plan.md 2 "$TEST_ROOT/bare.md" --no-header >/dev/null 2>&1)
    check "--no-header gives the bare slab" lacks "$TEST_ROOT/bare.md" "Shared header"
    if [[ "$(head -n 1 "$TEST_ROOT/bare.md")" == "### Task 2: Second thing" ]]; then
        pass "--no-header slab starts at the task heading"
    else
        fail "--no-header slab starts at the task heading"
    fi

    local hout
    hout="$(cd "$repo" && bash "$SDD_SCRIPTS/task-brief" plan.md header)"
    local hfile="$repo/.superpowers/sdd/plan/plan-header.md"
    check "header mode reports the file it wrote" test "$hout" = "wrote ${hfile}: $(wc -l < "$hfile" | tr -d ' ') lines"
    check "header mode carries Global Constraints" contains "$hfile" "## Global Constraints"
    check "header mode carries no task text" lacks "$hfile" "### Task 1"

    local rc=0
    (cd "$repo" && bash "$SDD_SCRIPTS/task-brief" plan.md 9 >/dev/null 2>&1) || rc=$?
    check "a missing task exits 3" test "$rc" -eq 3

    # --- --outline: one row per section; sizes partition the file ---
    local outline
    outline="$(cd "$repo" && bash "$SDD_SCRIPTS/task-brief" plan.md --outline)"
    local rows
    rows="$(printf '%s\n' "$outline" | grep -cE '^(header|Task [0-9]+|outside) ')"
    check "outline lists header, two tasks and two outside sections" test "$rows" -eq 5
    check "outline byte sizes add up to the file size" \
        test "$(printf '%s\n' "$outline" | tail -n +2 | sum_outline_bytes)" -eq "$(wc -c < "$repo/plan.md")"

    # --- a 12-task plan with a 5KB preamble ---
    {
        echo "# Big Plan"
        echo
        echo "**Goal:** many tasks."
        echo
        echo "## Global Constraints"
        echo
        echo "- Binding rule: values are exact."
        echo
        echo "## Background"
        echo
        for _ in $(seq 1 60); do echo "Background prose that pads the preamble to about five kilobytes."; done
        for i in $(seq 1 12); do
            echo
            echo "### Task $i: Component $i"
            echo
            echo "Build component $i."
        done
    } > "$repo/big.md"
    ( cd "$repo" && git add big.md && git "${git_id[@]}" commit -qm big )
    outline="$(cd "$repo" && bash "$SDD_SCRIPTS/task-brief" big.md --outline)"
    local hbytes
    hbytes="$(printf '%s\n' "$outline" | awk '$1 == "header" { print $3 }')"
    check "big plan's preamble is about 5KB" test "$hbytes" -gt 4000
    check "big plan's outline has twelve task rows" test "$(printf '%s\n' "$outline" | grep -c '^Task ')" -eq 12
    check "big plan's outline sizes add up to the file size" \
        test "$(printf '%s\n' "$outline" | tail -n +2 | sum_outline_bytes)" -eq "$(wc -c < "$repo/big.md")"

    # --- review-package: ledger lines appended, or left out on request ---
    local ws="$repo/.superpowers/sdd/plan"
    {
        echo "# SDD ledger — plan: plan.md"
        echo "Task 1: Ruling: keep the LF rule — spec says so — cost if wrong: one rewrite"
        echo "Task 1: minor (deferred): rename helper"
        echo "Task 1: complete (commits aaaaaaa..bbbbbbb, review clean)"
        echo "Task 2: complete (commits ccccccc..ddddddd, 1 parked)"
    } > "$ws/progress.md"
    echo one > "$repo/a.txt"
    ( cd "$repo" && git add a.txt && git "${git_id[@]}" commit -qm "Task 1" )
    local pkg
    pkg="$(cd "$repo" && bash "$SDD_SCRIPTS/review-package" plan.md HEAD~1 HEAD | sed -n 's/^wrote \(.*\): .*/\1/p')"
    check "review package carries the prior-rulings section" contains "$pkg" "## Prior rulings and deferred findings"
    check "review package carries Ruling: lines" contains "$pkg" "Ruling: keep the LF rule"
    check "review package carries deferred minors" contains "$pkg" "minor (deferred): rename helper"
    check "review package leaves out completion lines" lacks "$pkg" "review clean"
    check "review package leaves out a completion line that counts parked findings" lacks "$pkg" "1 parked"
    (cd "$repo" && bash "$SDD_SCRIPTS/review-package" plan.md HEAD~1 HEAD "$TEST_ROOT/nl.diff" --no-ledger >/dev/null)
    check "--no-ledger leaves the section out" lacks "$TEST_ROOT/nl.diff" "Prior rulings"

    # --- dispatch: every role renders with no placeholder left ---
    local base head
    base="$(cd "$repo" && git rev-parse HEAD~1)"
    head="$(cd "$repo" && git rev-parse HEAD)"
    echo "Task 1 builds the reader; Task 2 consumes read_all()." > "$TEST_ROOT/note.md"
    echo "- Important: helper swallows errors (a.txt:1)" > "$TEST_ROOT/findings.md"

    local role_args
    for role_args in \
        "implementer plan.md 1 --note $TEST_ROOT/note.md" \
        "reviewer plan.md 1 $base $head" \
        "re-review plan.md 1 $base $head --note $TEST_ROOT/findings.md" \
        "re-review plan.md final $base $head --note $TEST_ROOT/findings.md" \
        "final plan.md $base $head --note $TEST_ROOT/note.md"; do
        local out file prompt label
        label="${role_args%% *}"
        case "$role_args" in *" final "*) label="$label final" ;; esac
        # shellcheck disable=SC2086 # word-split the role's argument list
        if ! out="$(cd "$repo" && bash "$SDD_SCRIPTS/dispatch" $role_args 2>&1)"; then
            fail "dispatch $label renders"
            echo "    got: $out"
            continue
        fi
        file="$(printf '%s\n' "$out" | sed -n 's/^wrote \(.*\): .*/\1/p')"
        prompt="$(printf '%s\n' "$out" | sed -n 's/^prompt: //p')"
        check "dispatch $label: rendered file exists" test -s "$file"
        if grep -qE "$PLACEHOLDERS" "$file"; then
            fail "dispatch $label: no placeholder left"
            grep -oE "$PLACEHOLDERS" "$file" | sed 's/^/    left: /'
        else
            pass "dispatch $label: no placeholder left"
        fi
        check "dispatch $label: controller-side prompt under 400 chars" test "${#prompt}" -lt 400
    done

    local impl="$ws/task-1-implementer.md"
    check "implementer dispatch names the brief" contains "$impl" "$ws/task-1-brief.md"
    check "implementer dispatch names the report file" contains "$impl" "$ws/task-1-report.md"
    check "implementer dispatch carries the controller's note" contains "$impl" "Task 2 consumes read_all()."
    check "implementer dispatch names the task" contains "$impl" "Task 1: First thing"
    check "implementer dispatch names the repo" contains "$impl" "Work from: $repo"
    local rev
    rev="$(ls "$ws"/task-1-review-*.md)"
    check "reviewer dispatch copies Global Constraints verbatim" contains "$rev" "- Output files use LF line endings."
    check "reviewer dispatch names the review package" contains "$rev" "$ws/review-"
    local fin
    fin="$(ls "$ws"/final-review-*.md)"
    check "final dispatch points at the plan header" contains "$fin" "$ws/plan-header.md"
    check "final dispatch names the review package" contains "$fin" "Review package: $ws/review-"
    rc=0
    (cd "$repo" && bash "$SDD_SCRIPTS/dispatch" re-review plan.md 1 "$base" "$head" >/dev/null 2>&1) || rc=$?
    check "re-review without findings exits 2" test "$rc" -eq 2

    # A 12-task plan: every implementer dispatch renders clean.
    local i bad=0
    for i in $(seq 1 12); do
        out="$(cd "$repo" && bash "$SDD_SCRIPTS/dispatch" implementer big.md "$i" 2>/dev/null)" || { bad=1; continue; }
        file="$(printf '%s\n' "$out" | sed -n 's/^wrote \(.*\): .*/\1/p')"
        if grep -qE "$PLACEHOLDERS" "$file"; then bad=1; fi
        contains "$file" "Task $i: Component $i" || bad=1
    done
    check "all twelve implementer dispatches render with no placeholder left" test "$bad" -eq 0

    # --- fences the tracker must not lose: ``` nested in ````, and ~~~ ---
    cat > "$repo/fences.md" <<'PLAN'
# Fence Plan

## Global Constraints

- Log lines start with [INFO], [WARN] or [ERROR].

### Task 1: Write the README

Create README.md with exactly:

````markdown
# mytool

## Install

```bash
# from source
make install
```

## Usage

Run it.
````

~~~bash
# install deps
npm ci
~~~

- [ ] Step 2: commit

### Task 2: Next

Next step.
PLAN
    : > "$err"
    (cd "$repo" && bash "$SDD_SCRIPTS/task-brief" fences.md 1 >/dev/null 2>"$err")
    local fb="$repo/.superpowers/sdd/fences/task-1-brief.md"
    check "a nested fence keeps the rest of the task" contains "$fb" "Run it."
    check "a ~~~ fence keeps the rest of the task" contains "$fb" "npm ci"
    check "the task's last step survives both fences" contains "$fb" "Step 2: commit"
    check "the slab still ends at the next task" lacks "$fb" "Next step."
    check "no code line is reported as a section outside the tasks" lacks "$err" "# from source"

    # --- dispatch: bracketed words from the plan or the note are not placeholders ---
    echo "Leave the [TODO] marker in place." > "$TEST_ROOT/todo-note.md"
    rc=0
    out="$(cd "$repo" && bash "$SDD_SCRIPTS/dispatch" reviewer fences.md 1 HEAD~1 HEAD --note "$TEST_ROOT/todo-note.md" 2>&1)" || rc=$?
    check "dispatch renders when the constraints and note hold bracketed words" test "$rc" -eq 0
    file="$(printf '%s\n' "$out" | sed -n 's/^wrote \(.*\): .*/\1/p')"
    check "the rendered reviewer prompt keeps [INFO], [WARN] or [ERROR]" contains "$file" "[INFO], [WARN] or [ERROR]"
    check "the rendered reviewer prompt keeps the note's [TODO]" contains "$file" "[TODO]"
    check "dispatch resolves HEAD~1 to a full SHA" contains "$file" "$(cd "$repo" && git rev-parse HEAD~1)"

    # A reviewer reads the brief the implementer worked from.
    echo "HAND EDIT" >> "$fb"
    (cd "$repo" && bash "$SDD_SCRIPTS/dispatch" reviewer fences.md 1 HEAD~1 HEAD >/dev/null 2>&1) || true
    check "dispatch reviewer reuses the existing brief" contains "$fb" "HAND EDIT"

    rc=0
    out="$(cd "$repo" && bash "$SDD_SCRIPTS/dispatch" reviewer fences.md 7 HEAD~1 HEAD 2>&1)" || rc=$?
    check "dispatch reviewer for a missing task exits 3" test "$rc" -eq 3
    if [[ "$out" == *"task 7 not found"* ]]; then
        pass "dispatch reviewer for a missing task says so"
    else
        fail "dispatch reviewer for a missing task says so"
        echo "    got: $out"
    fi

    # A template placeholder the script does not fill is refused.
    local sk="$TEST_ROOT/skills"
    mkdir -p "$sk"
    cp -R "$REPO_ROOT/skills/subagent-driven-development" "$REPO_ROOT/skills/requesting-code-review" "$sk/"
    awk '{ print } /^  prompt: \|$/ { print "    Also read [NEW_PLACEHOLDER]." }' \
        "$REPO_ROOT/skills/subagent-driven-development/task-reviewer-prompt.md" \
        > "$sk/subagent-driven-development/task-reviewer-prompt.md"
    rc=0
    out="$(cd "$repo" && bash "$sk/subagent-driven-development/scripts/dispatch" reviewer fences.md 1 HEAD~1 HEAD 2>&1)" || rc=$?
    check "dispatch refuses a template placeholder it does not fill" test "$rc" -eq 1
    if [[ "$out" == *"[NEW_PLACEHOLDER]"* ]]; then
        pass "dispatch names the unfilled placeholder"
    else
        fail "dispatch names the unfilled placeholder"
        echo "    got: $out"
    fi

    # --- a plan with no shared header ---
    printf '### Task 1: Alpha\n\nDo alpha.\n' > "$repo/nohdr.md"
    rc=0
    (cd "$repo" && bash "$SDD_SCRIPTS/task-brief" nohdr.md header >/dev/null 2>&1) || rc=$?
    check "header mode on a plan with no header exits 3" test "$rc" -eq 3
    (cd "$repo" && bash "$SDD_SCRIPTS/task-brief" nohdr.md 1 >/dev/null 2>&1) || true
    check "a plan with no header gets no fake shared header" lacks "$repo/.superpowers/sdd/nohdr/task-1-brief.md" "Shared header"
    rc=0
    out="$(cd "$repo" && bash "$SDD_SCRIPTS/dispatch" final nohdr.md HEAD~1 HEAD 2>&1)" || rc=$?
    check "dispatch final renders for a plan with no header" test "$rc" -eq 0
    file="$(printf '%s\n' "$out" | sed -n 's/^wrote \(.*\): .*/\1/p')"
    check "dispatch final says the plan has no shared header" contains "$file" "no shared header"

    # --- commit-check: per-commit trailer check; review package shows trailers ---
    local trailer="Co-Authored-By: Example Model <noreply@example.com>"
    local cbase
    cbase="$(cd "$repo" && git rev-parse HEAD)"
    for i in 1 2 3; do
        echo "$i" > "$repo/c$i.txt"
        local msg="Commit $i

$trailer"
        [[ "$i" -eq 2 ]] && msg="Commit $i

Co-Authored-By: Other Model <noreply@example.com>"
        ( cd "$repo" && git add "c$i.txt" && git "${git_id[@]}" commit -qm "$msg" )
    done
    rc=0
    out="$(cd "$repo" && bash "$SDD_SCRIPTS/commit-check" "$cbase" HEAD --trailer "$trailer" 2>&1)" || rc=$?
    check "commit-check exits 1 when one commit lacks the trailer" test "$rc" -eq 1
    local bad_sha
    bad_sha="$(cd "$repo" && git rev-parse --short HEAD~1)"
    if [[ "$out" == *"lack the trailer: $bad_sha"* ]]; then
        pass "commit-check names the commit that lacks it"
    else
        fail "commit-check names the commit that lacks it"
        echo "    got: $out"
    fi
    local good_base
    good_base="$(cd "$repo" && git rev-parse HEAD)"
    for i in 4 5 6; do
        echo "$i" > "$repo/c$i.txt"
        ( cd "$repo" && git add "c$i.txt" && git "${git_id[@]}" commit -qm "Commit $i

$trailer" )
    done
    rc=0
    (cd "$repo" && bash "$SDD_SCRIPTS/commit-check" "$good_base" HEAD --trailer "$trailer" >/dev/null 2>&1) || rc=$?
    check "commit-check exits 0 when every commit carries it" test "$rc" -eq 0
    rc=0
    (cd "$repo" && bash "$SDD_SCRIPTS/commit-check" "$cbase" HEAD --trailer >/dev/null 2>&1) || rc=$?
    check "commit-check with --trailer but no line exits 2" test "$rc" -eq 2
    rc=0
    (cd "$repo" && bash "$SDD_SCRIPTS/commit-check" HEAD HEAD --trailer "$trailer" >/dev/null 2>&1) || rc=$?
    check "commit-check on an empty range exits 3" test "$rc" -eq 3
    rc=0
    (cd "$repo" && bash "$SDD_SCRIPTS/commit-check" HEAD HEAD~1 --trailer "$trailer" >/dev/null 2>&1) || rc=$?
    check "commit-check with a HEAD that does not descend from BASE exits 3" test "$rc" -eq 3

    # A merge from another branch: neither the merge nor the merged-in
    # commits are the task's own.
    local mbase
    mbase="$(cd "$repo" && git rev-parse HEAD)"
    (
        cd "$repo"
        git checkout -qb side
        echo s > s.txt && git add s.txt && git "${git_id[@]}" commit -qm "side work"
        git checkout -q main
        echo m > m.txt && git add m.txt && git "${git_id[@]}" commit -qm "Main work

$trailer"
        git "${git_id[@]}" merge -q --no-ff side -m "Merge side"
    )
    rc=0
    (cd "$repo" && bash "$SDD_SCRIPTS/commit-check" "$mbase" HEAD --trailer "$trailer" >/dev/null 2>&1) || rc=$?
    check "commit-check skips a merge and the commits it brought in" test "$rc" -eq 0

    # The line glued to the prose above it is not a trailer git can parse.
    local tbase
    tbase="$(cd "$repo" && git rev-parse HEAD)"
    echo 7 > "$repo/c7.txt"
    ( cd "$repo" && git add c7.txt && git "${git_id[@]}" commit -qm "Commit 7

Explains the change.
$trailer" )
    rc=0
    out="$(cd "$repo" && bash "$SDD_SCRIPTS/commit-check" "$tbase" HEAD --trailer "$trailer" 2>&1)" || rc=$?
    check "commit-check fails a trailer git does not parse" test "$rc" -eq 1
    if [[ "$out" == *"NOT A TRAILER"* ]]; then
        pass "commit-check says the line is there but not a trailer"
    else
        fail "commit-check says the line is there but not a trailer"
        echo "    got: $out"
    fi
    (cd "$repo" && bash "$SDD_SCRIPTS/review-package" plan.md "$cbase" HEAD "$TEST_ROOT/t.diff" >/dev/null)
    check "review package shows commit trailers" contains "$TEST_ROOT/t.diff" "    $trailer"

    echo
    if [[ "$FAILURES" -eq 0 ]]; then
        echo "All SDD slicing tests passed."
    else
        echo "$FAILURES SDD slicing test(s) failed."
        exit 1
    fi
}

main "$@"
