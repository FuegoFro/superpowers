#!/usr/bin/env bash
# Claude Code re-attaches every invoked skill body after each compaction, cut at
# 20,000 characters, so anything past that point silently drops out of a long
# session. Fails when a skills/*/SKILL.md exceeds 20,000 characters, warns above
# 12,000, and fails when a SKILL.md links to a local .md file that does not exist
# (moved reference blocks are reached only through those links).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
CAP=20000
WARN=12000

# wc -m counts characters only under a UTF-8 locale.
export LC_ALL=C.UTF-8

failures=0
warnings=0

for skill in "$REPO_ROOT"/skills/*/SKILL.md; do
    dir="$(dirname "$skill")"
    name="$(basename "$dir")"
    chars="$(wc -m <"$skill")"
    if ((chars > CAP)); then
        echo "  [FAIL] $name: $chars chars, over the $CAP-char re-attach cap"
        failures=$((failures + 1))
    elif ((chars > WARN)); then
        echo "  [WARN] $name: $chars chars (above $WARN)"
        warnings=$((warnings + 1))
    else
        echo "  [PASS] $name: $chars chars"
    fi

    while IFS= read -r link; do
        target="${link%%#*}"
        case "$target" in http://* | https://* | "") continue ;; esac
        if [[ ! -f "$dir/$target" ]]; then
            echo "  [FAIL] $name: links to missing $target"
            failures=$((failures + 1))
        fi
    done < <(grep -oE '\]\([^)[:space:]]+\.md(#[^)]*)?\)' "$skill" | sed -E 's/^\]\(//; s/\)$//')
done

echo ""
if ((failures > 0)); then
    echo "Skill body size: $failures failure(s), $warnings warning(s)."
    exit 1
fi
echo "Skill body size: all SKILL.md files under $CAP chars ($warnings above $WARN)."
