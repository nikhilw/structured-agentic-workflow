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

# Skills we adopt from superpowers
SKILLS=(
    brainstorming
    test-driven-development
    systematic-debugging
    verification-before-completion
)

# Map superpowers names to our skill names (when different)
# format: "superpowers-name:our-name"
SKILL_RENAMES=(
    "systematic-debugging:debug"
    "verification-before-completion:verify"
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

    # Copy vendored skills into skills/ (applying renames)
    echo ""
    echo "Installing superpowers into skills/..."
    local skills_dir="${SCRIPT_DIR}/skills"
    for skill in "${SKILLS[@]}"; do
        local vendor_src="${VENDOR_DIR}/${skill}"
        [ -d "$vendor_src" ] || continue

        # Check if this skill has a rename mapping
        local target_name="$skill"
        for mapping in "${SKILL_RENAMES[@]}"; do
            local from="${mapping%%:*}"
            local to="${mapping##*:}"
            if [ "$skill" = "$from" ]; then
                target_name="$to"
                break
            fi
        done

        local dst="${skills_dir}/${target_name}"
        rm -rf "$dst"
        cp -r "$vendor_src" "$dst"

        # Patch the name: field in SKILL.md to match our directory name
        if [ "$target_name" != "$skill" ]; then
            local skill_md="${dst}/SKILL.md"
            if [ -f "$skill_md" ]; then
                sed -i "s/^name: ${skill}$/name: ${target_name}/" "$skill_md"
            fi
            echo "  copied   ${skill}/ -> skills/${target_name}/ (name patched)"
        else
            echo "  copied   ${skill}/ -> skills/${skill}/"
        fi
    done

    # Patch cross-references to use our skill names
    local debug_skill="${skills_dir}/debug/SKILL.md"
    if [ -f "$debug_skill" ]; then
        sed -i 's|superpowers:test-driven-development|/test-driven-development|g' "$debug_skill"
        sed -i 's|superpowers:verification-before-completion|/verify|g' "$debug_skill"
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
