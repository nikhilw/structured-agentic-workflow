#!/usr/bin/env bash
# pull-superpowers.sh — Fetch specific skills from obra/superpowers into vendor/
#
# These skills are MIT-licensed by Jesse Vincent (2025).
# See: https://github.com/obra/superpowers
#
# Usage:
#   ./pull-superpowers.sh          # Fetch/update vendored skills
#   ./pull-superpowers.sh --clean  # Remove vendored skills

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VENDOR_DIR="${SCRIPT_DIR}/vendor/superpowers"
REPO_URL="https://github.com/obra/superpowers.git"
BRANCH="main"

# Skills we adopt from superpowers.
#
# We keep the upstream names verbatim so users who install via
# `npx skills add obra/superpowers` (which has no rename flag) and users who
# install via our install.sh end up with identically-named skills.
SKILLS=(
    brainstorming
    test-driven-development
    systematic-debugging
)

# Skills we used to pull and no longer do. Stale copies from an earlier install
# are removed so the agent is never offered two skills for one job.
#
# verification-before-completion: superseded by this repo's own verify-completion,
# which keeps its Iron Law and adds the plan-requirements tick-off and the drift
# audit. Installing both would leave two gates claiming the same role.
RETIRED_SKILLS=(
    verification-before-completion
)

clean() {
    echo "Removing vendored superpowers skills..."
    rm -rf "$VENDOR_DIR"
    echo "Done."
}

fetch() {
    local tmp_dir
    tmp_dir=$(mktemp -d)
    trap 'rm -rf "$tmp_dir"' RETURN

    echo "Cloning obra/superpowers (sparse)..."
    git clone --depth 1 --filter=blob:none --sparse "$REPO_URL" "$tmp_dir/superpowers" 2>&1 | sed 's/^/  /'

    cd "$tmp_dir/superpowers"
    git sparse-checkout set --no-cone $(printf 'skills/%s\n' "${SKILLS[@]}") '/LICENSE'
    git checkout "$BRANCH" -- LICENSE $(printf 'skills/%s ' "${SKILLS[@]}") 2>/dev/null || true

    # Copy into vendor directory
    mkdir -p "$VENDOR_DIR"

    # Copy license
    cp LICENSE "$VENDOR_DIR/LICENSE"
    echo "  copied   LICENSE"

    # Copy skills
    for skill in "${SKILLS[@]}"; do
        src="skills/${skill}"
        dst="${VENDOR_DIR}/${skill}"
        if [ -d "$src" ]; then
            rm -rf "$dst"
            cp -r "$src" "$dst"
            echo "  copied   ${skill}/"
        else
            echo "  missing  ${skill}/ — skipping"
        fi
    done

    cd "$SCRIPT_DIR"

    # Copy vendored skills into skills/ (names preserved from upstream)
    echo ""
    echo "Installing superpowers into skills/..."
    local skills_dir="${SCRIPT_DIR}/skills"
    for skill in "${SKILLS[@]}"; do
        local vendor_src="${VENDOR_DIR}/${skill}"
        [ -d "$vendor_src" ] || continue

        local dst="${skills_dir}/${skill}"
        rm -rf "$dst"
        cp -r "$vendor_src" "$dst"
        echo "  copied   ${skill}/ -> skills/${skill}/"
    done

    # Drop stale copies of skills we no longer pull, in vendor/ and in skills/.
    for skill in "${RETIRED_SKILLS[@]}"; do
        for stale in "${VENDOR_DIR}/${skill}" "${skills_dir}/${skill}"; do
            if [ -d "$stale" ]; then
                rm -rf "$stale"
                echo "  removed  ${stale#$SCRIPT_DIR/} (retired)"
            fi
        done
    done

    # Strip the `superpowers:` namespace prefix on cross-references so the skills
    # resolve in agents that don't understand plugin-style namespacing, and point
    # the verification reference at our own gate, which replaces the upstream one.
    local debug_skill="${skills_dir}/systematic-debugging/SKILL.md"
    if [ -f "$debug_skill" ]; then
        sed -i 's|superpowers:test-driven-development|/test-driven-development|g' "$debug_skill"
        sed -i 's|superpowers:verification-before-completion|/verify-completion|g' "$debug_skill"
    fi

    echo ""
    echo "Done. Vendored skills are in vendor/superpowers/"
    echo "Superpowers skills installed into skills/"
    echo "License: MIT (Jesse Vincent, 2025)"
    echo "Source:  https://github.com/obra/superpowers"
}

case "${1:-}" in
    --clean|-c)
        clean
        ;;
    *)
        fetch
        ;;
esac
