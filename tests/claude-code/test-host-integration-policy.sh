#!/usr/bin/env bash
# Policy check for the fork's host-integration delta: the skills must defer to
# the harness's and the repo's own tooling — worktree creation, review commands,
# commit conventions — instead of prescribing their own. See FORK.md.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

USING_SKILL="$REPO_ROOT/skills/using-git-worktrees/SKILL.md"
FINISHING_SKILL="$REPO_ROOT/skills/finishing-a-development-branch/SKILL.md"
SDD_SKILL="$REPO_ROOT/skills/subagent-driven-development/SKILL.md"
RCR_SKILL="$REPO_ROOT/skills/requesting-code-review/SKILL.md"
TDD_SKILL="$REPO_ROOT/skills/test-driven-development/SKILL.md"
IMPLEMENTER="$REPO_ROOT/skills/subagent-driven-development/implementer-prompt.md"

failures=0

assert_contains() {
    local file="$1"
    local pattern="$2"
    local label="$3"

    if grep -Fq "$pattern" "$file"; then
        echo "  [PASS] $label"
    else
        echo "  [FAIL] $label"
        echo "    Expected to find: $pattern"
        echo "    In file: $file"
        failures=$((failures + 1))
    fi
}

echo "=== Host Integration Policy Test ==="
echo ""

echo "-- Worktrees: the harness owns placement and may require isolation --"
assert_contains "$USING_SKILL" "Harness-enforced isolation" \
    "using-git-worktrees handles harnesses that require a worktree"
assert_contains "$USING_SKILL" '`.claude/worktrees/`' \
    "using-git-worktrees names the harness's own worktree location"
assert_contains "$USING_SKILL" "Never relocate a harness-owned worktree" \
    "using-git-worktrees leaves harness-placed worktrees where they are"
assert_contains "$USING_SKILL" "the repo's own setup and test commands" \
    "using-git-worktrees defers setup/baseline to the repo's tooling"

echo ""
echo "-- Review: the host's review machinery runs before the generic reviewer --"
assert_contains "$SDD_SKILL" '`/code-review`' \
    "subagent-driven-development routes the final review through /code-review"
assert_contains "$SDD_SKILL" '`/security-review`' \
    "subagent-driven-development reaches for /security-review when warranted"
assert_contains "$RCR_SKILL" '`/code-review`' \
    "requesting-code-review prefers the host review command"
assert_contains "$RCR_SKILL" "the repo ships its own review commands" \
    "requesting-code-review defers to repo-shipped review commands"
assert_contains "$RCR_SKILL" "If none of these are available" \
    "requesting-code-review keeps the subagent reviewer as the fallback"

echo ""
echo "-- TDD: a repo with no reachable test path is a question, not a silent skip --"
assert_contains "$TDD_SKILL" "NO PRODUCTION CODE WITHOUT A FAILING TEST FIRST" \
    "test-driven-development keeps the bright line bright"
assert_contains "$TDD_SKILL" "no reachable test path" \
    "test-driven-development names the untestable-area exception"
assert_contains "$TDD_SKILL" "ask before you write the code, not after" \
    "test-driven-development requires asking up front, not retroactively"

echo ""
echo "-- Commits: the repo's conventions and integration norms win --"
assert_contains "$IMPLEMENTER" "the repo's own commit conventions" \
    "implementer-prompt sends implementers to the repo's commit conventions"
assert_contains "$FINISHING_SKILL" "the repo's own commit and integration conventions" \
    "finishing-a-development-branch defers to repo integration norms"
assert_contains "$FINISHING_SKILL" "Never merge a pull request yourself" \
    "finishing-a-development-branch never self-merges a PR"
assert_contains "$FINISHING_SKILL" "force-push only on your human partner's explicit request" \
    "finishing-a-development-branch keeps the force-push guard"

echo ""

if [ "$failures" -gt 0 ]; then
    echo "STATUS: FAILED ($failures failures)"
    exit 1
fi

echo "STATUS: PASSED"
