#!/usr/bin/env bash
# install.sh: install this workflow's skills into one project. Tested on Linux.
#
# Usage:
#   ./install.sh <project-dir>            # pull superpowers, then install into that project
#   ./install.sh --local <project-dir>    # install without pulling superpowers
#   ./install.sh --link <project-dir>     # link to this repo instead of copying (for
#                                         # working on the skills; not portable)
#   ./install.sh --remove <project-dir>   # remove what this script installed there
#   ./install.sh                          # asks for the project directory
#
# Skills are copied (or with --link, linked) into <project-dir>/.agents/skills/, the
# common directory, and linked from <project-dir>/.claude/skills/. Global installs go
# through `npx skills`.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILLS_SRC="${SCRIPT_DIR}/skills"
PULL_SCRIPT="${SCRIPT_DIR}/pull-superpowers.sh"

# Skills this project used to ship and no longer does. They are never installed,
# and an installed copy is never removed: it may have come from another source.
#
# verification-before-completion: superseded by our own verify-completion.
RETIRED_SKILLS=(
    verification-before-completion
)

# Every skill directory under skills/, minus anything retired. A retired skill can
# still be sitting in skills/ from an older pull.
discover_skills() {
    local name retired
    for dir in "${SKILLS_SRC}"/*/; do
        [ -d "$dir" ] || continue
        name="$(basename "$dir")"
        for retired in "${RETIRED_SKILLS[@]}"; do
            [ "$name" = "$retired" ] && continue 2
        done
        echo "$name"
    done
}

# The link target written into .claude/skills/<name>, relative so the project can move.
link_target() {
    echo "../../.agents/skills/$1"
}

install_skills() {
    local project="$1"
    local common="${project}/.agents/skills"
    local claude="${project}/.claude/skills"
    local skill dst link count=0
    mkdir -p "$common" "$claude"

    while read -r skill; do
        [ -n "$skill" ] || continue
        dst="${common}/${skill}"
        rm -rf -- "$dst"
        if [ "$LINK" = true ]; then
            ln -s -- "${SKILLS_SRC}/${skill}" "$dst"
        else
            cp -R -- "${SKILLS_SRC}/${skill}" "$dst"
        fi
        count=$((count + 1))

        link="${claude}/${skill}"
        if [ -L "$link" ] && [ "$(readlink -- "$link")" = "$(link_target "$skill")" ]; then
            :
        elif [ -e "$link" ] || [ -L "$link" ]; then
            echo "  skipped link  .claude/skills/${skill} (something else is already there)"
        else
            ln -s -- "$(link_target "$skill")" "$link"
        fi
    done < <(discover_skills)

    echo ""
    if [ "$LINK" = true ]; then
        echo "Linked ${count} skills in ${common} to ${SKILLS_SRC}"
        echo "  (edits there are live here), symlinked from ${claude}."
    else
        echo "Installed ${count} skills to ${common}"
        echo "  (the common .agents/ directory), symlinked from ${claude}."
    fi
    echo "For another agent, symlink its skills directory entries to .agents/skills/<name>."
    if ! command -v graphify >/dev/null 2>&1; then
        echo ""
        echo "Recommended: graphify powers codebase search in /brainstorm and /write-plan;"
        echo "  without it both fall back to grep. Install: https://github.com/Graphify-Labs/graphify"
    fi
}

remove_skills() {
    local project="$1"
    local common="${project}/.agents/skills"
    local claude="${project}/.claude/skills"
    local skill link count=0

    while read -r skill; do
        [ -n "$skill" ] || continue
        link="${claude}/${skill}"
        if [ -L "$link" ] && [ "$(readlink -- "$link")" = "$(link_target "$skill")" ]; then
            rm -- "$link"
        fi
        if [ -d "${common}/${skill}" ]; then
            rm -rf -- "${common:?}/${skill}"
            count=$((count + 1))
        fi
    done < <(discover_skills)

    echo "Removed ${count} skills from ${common}, and their links in ${claude}."
}

ACTION="install"
SKIP_PULL=false
LINK=false
PROJECT=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --remove|-r) ACTION="remove"; shift ;;
        --local|-l)  SKIP_PULL=true; shift ;;
        --link)      LINK=true; shift ;;
        --help|-h)   sed -n '2,14p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
        -*)          echo "Unknown option: $1 (see --help)"; exit 1 ;;
        *)
            if [ -n "$PROJECT" ]; then
                echo "One project directory only (see --help)"; exit 1
            fi
            PROJECT="$1"; shift ;;
    esac
done

if [ -z "$PROJECT" ]; then
    if [ ! -t 0 ]; then
        echo "No project directory given (see --help)"; exit 1
    fi
    read -r -p "Install into which project directory? " PROJECT
fi
if [ ! -d "$PROJECT" ]; then
    echo "Not a directory: ${PROJECT}"; exit 1
fi
PROJECT="$(cd "$PROJECT" && pwd)"

case "$ACTION" in
    remove)
        remove_skills "$PROJECT"
        ;;
    install)
        if [ "$SKIP_PULL" = false ]; then
            echo "Pulling superpowers skills..."
            bash "$PULL_SCRIPT"
            echo ""
        fi
        install_skills "$PROJECT"
        ;;
esac
