#!/usr/bin/env bash
# Claude Code re-attaches every invoked skill body after each compaction, cut at
# 20,000 characters, so anything past that point drops out of a long session
# (the cut ends with a Read-the-skill marker that sessions rarely act on; see
# FORK.md rule 7 for the limits). What is re-attached is "Base directory for this skill: <dir>", a
# blank line, and the body without its frontmatter, so that is what is
# measured, with room for a long plugin-cache path. Fails when it exceeds
# 20,000 characters, warns above 12,000, and fails when a SKILL.md links to a
# local .md file that does not exist (moved reference blocks are reached only
# through those links).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
CAP=20000
WARN=12000
# "Base directory for this skill: " (31) + a 160-char install path + "\n\n".
PREFIX=193

# wc -m counts characters only under a UTF-8 locale; macOS may lack C.UTF-8.
for loc in C.UTF-8 en_US.UTF-8; do
    if [[ "$(printf '\xe2\x80\x94' | LC_ALL=$loc wc -m 2>/dev/null | tr -d ' ')" == 1 ]]; then
        export LC_ALL=$loc
        break
    fi
done
[[ "${LC_ALL:-}" == *UTF-8 ]] || echo "  [WARN] no UTF-8 locale: counting bytes, which overstates multibyte text"

# The body as re-attached: everything after the closing "---" of the frontmatter.
body() { awk 'NR == 1 && /^---$/ { fm = 1; next } fm && /^---$/ { fm = 0; next } !fm' "$1"; }

failures=0
warnings=0

for skill in "$REPO_ROOT"/skills/*/SKILL.md; do
    dir="$(dirname "$skill")"
    name="$(basename "$dir")"
    chars=$(($(body "$skill" | wc -m) + PREFIX))
    if ((chars > CAP)); then
        echo "  [FAIL] $name: $chars chars re-attached, over the $CAP-char cap"
        failures=$((failures + 1))
    elif ((chars > WARN)); then
        echo "  [WARN] $name: $chars chars re-attached (above $WARN)"
        warnings=$((warnings + 1))
    else
        echo "  [PASS] $name: $chars chars re-attached"
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
