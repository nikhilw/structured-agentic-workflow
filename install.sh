#!/usr/bin/env bash
# install.sh — Symlink workflow skills into ~/.claude/skills/
#
# Usage:
#   ./install.sh          # Install (symlink) all skills
#   ./install.sh --remove # Remove symlinks only (does not delete originals)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILLS_SRC="${SCRIPT_DIR}/skills"
SKILLS_DST="${HOME}/.claude/skills"

SKILLS=(
    agentic-workflow
    brainstorm
    write-plan
    build-phase
    3p-review
    triage
)

remove_links() {
    for skill in "${SKILLS[@]}"; do
        target="${SKILLS_DST}/${skill}"
        if [ -L "$target" ]; then
            rm "$target"
            echo "  removed  ${target}"
        elif [ -e "$target" ]; then
            echo "  skipped  ${target} (not a symlink — remove manually if intended)"
        fi
    done
    echo "Done."
}

install_links() {
    mkdir -p "$SKILLS_DST"

    for skill in "${SKILLS[@]}"; do
        src="${SKILLS_SRC}/${skill}"
        target="${SKILLS_DST}/${skill}"

        if [ ! -d "$src" ]; then
            echo "  missing  ${src} — skipping"
            continue
        fi

        if [ -L "$target" ]; then
            rm "$target"
        elif [ -e "$target" ]; then
            echo "  exists   ${target} (not a symlink — back up and remove to install)"
            continue
        fi

        ln -s "$src" "$target"
        echo "  linked   ${target} -> ${src}"
    done

    echo ""
    echo "Done. Skills are now available in Claude Code."
    echo "Verify with:  ls -la ~/.claude/skills/"
}

case "${1:-}" in
    --remove|-r)
        echo "Removing skill symlinks..."
        remove_links
        ;;
    *)
        echo "Installing workflow skills into ${SKILLS_DST}..."
        install_links
        ;;
esac
