#!/usr/bin/env bash
# install.sh — Pull superpowers and symlink workflow skills for coding agents
#
# Usage:
#   ./install.sh                    # Pull superpowers + install for all agents
#   ./install.sh --target claude    # Install for Claude Code only
#   ./install.sh --target gemini    # Install for Gemini CLI only
#   ./install.sh --target cursor    # Install for Cursor only
#   ./install.sh --target copilot   # Install for GitHub Copilot only
#   ./install.sh --remove           # Remove symlinks for all agents
#   ./install.sh --remove --target claude  # Remove for specific agent
#   ./install.sh --local            # Install without pulling superpowers
#   ./install.sh --list             # Show supported agents and their paths

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILLS_SRC="${SCRIPT_DIR}/skills"
PULL_SCRIPT="${SCRIPT_DIR}/pull-superpowers.sh"

# Supported agents and their global skills directories
declare -A AGENT_PATHS=(
    [claude]="${HOME}/.claude/skills"
    [cursor]="${HOME}/.cursor/skills"
    [gemini]="${HOME}/.gemini/skills"
    [copilot]="${HOME}/.config/github-copilot/skills"
)

ALL_AGENTS=(claude cursor gemini copilot)

# Skills this project used to install and no longer does. A link left behind by an
# earlier install is removed, but only when it is ours: a broken link, or one that
# resolves back into this repo. A real skill the user installed some other way is
# never touched.
#
# verification-before-completion: superseded by our own verify-completion.
RETIRED_SKILLS=(
    verification-before-completion
)

remove_retired_links() {
    local skills_dst="$1"
    local skill target resolved
    for skill in "${RETIRED_SKILLS[@]}"; do
        target="${skills_dst}/${skill}"
        [ -L "$target" ] || continue
        resolved="$(cd "$(dirname "$target")" && readlink -f "$skill" 2>/dev/null || true)"
        if [ -z "$resolved" ] || [ ! -e "$resolved" ]; then
            rm "$target"
            echo "    removed  ${skill} (retired — link was broken)"
        elif [ "${resolved#${SKILLS_SRC}/}" != "$resolved" ]; then
            rm "$target"
            echo "    removed  ${skill} (retired — superseded by verify-completion)"
        fi
    done
}

# Discover all skills dynamically from the skills/ directory, minus anything
# retired. A retired skill can still be sitting in skills/ from an older pull;
# linking it and then unlinking it would clobber a copy the user installed
# themselves, so it is never a candidate in the first place.
discover_skills() {
    local skills=() name retired
    for dir in "${SKILLS_SRC}"/*/; do
        [ -d "$dir" ] || continue
        name="$(basename "$dir")"
        for retired in "${RETIRED_SKILLS[@]}"; do
            [ "$name" = "$retired" ] && continue 2
        done
        skills+=("$name")
    done
    echo "${skills[@]}"
}

remove_links() {
    local agent_name="$1"
    local skills_dst="$2"
    local skills
    read -ra skills <<< "$(discover_skills)"

    echo "  [${agent_name}] ${skills_dst}"
    for skill in "${skills[@]}"; do
        target="${skills_dst}/${skill}"
        if [ -L "$target" ]; then
            rm "$target"
            echo "    removed  ${skill}"
        elif [ -e "$target" ]; then
            echo "    skipped  ${skill} (not a symlink — remove manually if intended)"
        fi
    done

    remove_retired_links "$skills_dst"
}

install_links() {
    local agent_name="$1"
    local skills_dst="$2"
    mkdir -p "$skills_dst"

    local skills
    read -ra skills <<< "$(discover_skills)"

    echo "  [${agent_name}] ${skills_dst}"
    for skill in "${skills[@]}"; do
        src="${SKILLS_SRC}/${skill}"
        target="${skills_dst}/${skill}"

        if [ ! -d "$src" ]; then
            echo "    missing  ${skill} — skipping"
            continue
        fi

        if [ -L "$target" ]; then
            rm "$target"
        elif [ -e "$target" ]; then
            echo "    exists   ${skill} (not a symlink — back up and remove to install)"
            continue
        fi

        ln -s "$src" "$target"
        echo "    linked   ${skill}"
    done

    remove_retired_links "$skills_dst"
}

list_agents() {
    echo "Supported agents:"
    echo ""
    for agent in "${ALL_AGENTS[@]}"; do
        local path="${AGENT_PATHS[$agent]}"
        local status="not installed"
        if [ -d "$path" ]; then
            status="installed"
        fi
        printf "  %-10s %s (%s)\n" "$agent" "$path" "$status"
    done
}

# Parse arguments
ACTION="install"
TARGET=""
SKIP_PULL=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        --remove|-r)
            ACTION="remove"
            shift
            ;;
        --target|-t)
            TARGET="$2"
            if [[ -z "${AGENT_PATHS[$TARGET]+x}" ]]; then
                echo "Error: unknown agent '$TARGET'"
                echo "Supported agents: ${ALL_AGENTS[*]}"
                exit 1
            fi
            shift 2
            ;;
        --local|-l)
            SKIP_PULL=true
            shift
            ;;
        --list)
            list_agents
            exit 0
            ;;
        --help|-h)
            head -12 "$0" | tail -11 | sed 's/^# //' | sed 's/^#//'
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Run with --help for usage."
            exit 1
            ;;
    esac
done

# Determine which agents to target
if [ -n "$TARGET" ]; then
    TARGETS=("$TARGET")
else
    TARGETS=("${ALL_AGENTS[@]}")
fi

# Execute
case "$ACTION" in
    remove)
        echo "Removing skill symlinks..."
        for agent in "${TARGETS[@]}"; do
            remove_links "$agent" "${AGENT_PATHS[$agent]}"
        done
        echo ""
        echo "Done."
        ;;
    install)
        if [ "$SKIP_PULL" = false ]; then
            echo "Pulling superpowers skills..."
            bash "$PULL_SCRIPT"
            echo ""
        fi
        echo "Installing workflow skills..."
        for agent in "${TARGETS[@]}"; do
            install_links "$agent" "${AGENT_PATHS[$agent]}"
        done
        echo ""
        echo "Done. Skills are now available."
        echo "Verify with:  ls -la ~/.claude/skills/  (or other agent paths)"
        if ! command -v graphify >/dev/null 2>&1; then
            echo ""
            echo "Recommended: graphify powers codebase search in /brainstorm and /write-plan."
            echo "  uv tool install graphifyy && graphify install"
            echo "  (double-y is deliberate; 'graphify' on PyPI is an unrelated package)"
            echo "  (the workflow runs without it — both skills fall back to grep)"
        fi
        ;;
esac
