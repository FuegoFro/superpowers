#!/usr/bin/env bash
# Tests for writing-plans' scripts/plan-stats: a lean plan prints no flags; a
# plan 5x its spec and a 30k-char task are flagged with exit 1; headings inside
# code fences are not tasks; characters, not bytes, are counted.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
PLAN_STATS="$REPO_ROOT/skills/writing-plans/scripts/plan-stats"

FAILURES=0
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
has() { grep -Fq -- "$2" <<<"$1"; }
hasnt() { ! grep -Fq -- "$2" <<<"$1"; }

TEST_ROOT="$(mktemp -d)"
trap 'rm -rf "$TEST_ROOT"' EXIT

filler() { # filler CHARS: that many characters of prose, in 80-char lines
    awk -v n="$1" 'BEGIN { while (n > 0) { w = (n > 80 ? 80 : n); s = sprintf("%" (w - 1) "s", ""); gsub(/ /, "x", s); print s; n -= w } }'
}

spec="$TEST_ROOT/spec.md"
{ echo "# Spec"; filler 4000; } >"$spec"

lean="$TEST_ROOT/lean.md"
{
    echo "# Lean Plan"
    echo "**Goal:** a thing"
    echo "### Task 1: First"
    filler 2000
    echo '```python'
    echo "### Task 9: not a task, inside a fence"
    echo "def f(): pass"
    echo '```'
    echo "### Task 2: Second"
    filler 2000
    echo "## Self-review"
    filler 500
} >"$lean"

out="$(bash "$PLAN_STATS" "$lean" "$spec" 2>&1)" && rc=0 || rc=$?
check "lean plan exits 0" test "$rc" -eq 0
check "lean plan prints no flag" hasnt "$out" "FLAG"
check "lean plan counts two tasks (fenced heading is text)" has "$out" ", 2 tasks,"
check "lean plan lists Task 1" has "$out" "Task 1"
check "lean plan reports fence share" has "$out" "inside code fences"
check "lean plan reports ratio" has "$out" "x the spec"
check "self-review section is not part of Task 2" bash -c "grep -E '^  Task 2 +[0-9]+ chars' <<<\"\$1\" | awk '{ exit !(\$3 < 2200) }'" _ "$out"

fat="$TEST_ROOT/fat.md"
{
    echo "# Fat Plan"
    echo "### Task 1: Everything"
    filler 20000
} >"$fat"
out="$(bash "$PLAN_STATS" "$fat" "$spec" 2>&1)" && rc=0 || rc=$?
check "5x plan exits 1" test "$rc" -eq 1
check "5x plan flags the ratio" has "$out" "FLAG: plan is 5.0x its spec"
check "5x plan does not flag a 20k task" hasnt "$out" "FLAG: Task"

big="$TEST_ROOT/big.md"
{
    echo "# Big Task Plan"
    echo "### Task 1: Small"
    filler 1000
    echo "### Task 2: Huge"
    filler 30000
} >"$big"
out="$(bash "$PLAN_STATS" "$big" 2>&1)" && rc=0 || rc=$?
check "30k task exits 1" test "$rc" -eq 1
check "30k task is flagged by name" has "$out" "FLAG: Task 2 is"
check "small task is not flagged" hasnt "$out" "FLAG: Task 1"
check "no spec means no ratio line" hasnt "$out" "x the spec"

utf="$TEST_ROOT/utf.md"
printf '### Task 1: \xe2\x80\x94\n' >"$utf"
out="$(bash "$PLAN_STATS" "$utf" 2>&1)"
check "multibyte characters count once" has "$out" "14 chars, 1 lines"

# A ``` block nested in a ````markdown block, then a ~~~ block: the # lines in
# them are text, so Task 1 runs to Task 2 and all of it is fenced but prose.
nest="$TEST_ROOT/nest.md"
printf '%s\n' '### Task 1: README' '````markdown' '# mytool' '```bash' '# from source' '```' '## Usage' '````' \
    '~~~bash' '# deps' '~~~' 'Step 2.' '### Task 2: Next' 'Next.' >"$nest"
out="$(bash "$PLAN_STATS" "$nest" 2>&1)"
check "nested and tilde fences hide their headings" has "$out" ", 2 tasks,"
check "a nested fence's lines all count as fenced" has "$out" "61% inside code fences"

bash "$PLAN_STATS" >/dev/null 2>&1 && rc=0 || rc=$?
check "no arguments exits 2" test "$rc" -eq 2
bash "$PLAN_STATS" "$TEST_ROOT/missing.md" >/dev/null 2>&1 && rc=0 || rc=$?
check "missing plan exits 2" test "$rc" -eq 2

echo ""
if ((FAILURES > 0)); then
    echo "plan-stats tests: $FAILURES failure(s)."
    exit 1
fi
echo "All plan-stats tests passed."
