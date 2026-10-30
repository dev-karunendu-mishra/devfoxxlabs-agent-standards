#!/usr/bin/env bash
# DevFoxx Labs — AI Agent Standards & Skills Installer (Linux & macOS)

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
USER_HOME="$HOME"
STAMP="$(date +%Y%m%d-%H%M%S)"

# Agents that load SKILL.md folders from ~/<root>/skills. Skills are only
# installed for agents whose root folder already exists on this machine.
OTHER_AGENTS=(
    "GitHub Copilot:.copilot"
    "Continue:.continue"
    "Roo Code:.roo"
    "Kilo Code:.kilocode"
    "OpenCode:.opencode"
    "Augment:.augment"
    "CodeBuddy:.codebuddy"
    "Factory:.factory"
    "Qoder:.qoder"
    "Trae:.trae"
    "Warp:.warp"
)

echo "=========================================================="
echo "   DevFoxx Labs — AI Agent Standards & Skills Installer   "
echo "=========================================================="
echo "Source: $SCRIPT_DIR"
echo "Home:   $USER_HOME"
echo ""

TARGET="$1"

if [ -z "$TARGET" ]; then
    echo "Usage: ./install.sh [all|claude|gemini|cursor|windsurf|codex|agents|others|<path_to_project>]"
    echo "  all      - Install for every supported agent"
    echo "  claude   - Install to ~/.claude"
    echo "  gemini   - Install to ~/.gemini"
    echo "  cursor   - Install to ~/.cursor"
    echo "  windsurf - Install to ~/.codeium/windsurf"
    echo "  codex    - Install to ~/.codex (AGENTS.md) + ~/.agents/skills"
    echo "  agents   - Install to ~/.agents"
    echo "  others   - Skills for other installed agents (Copilot, Continue, Roo, Kilo Code, OpenCode, Trae, ...)"
    echo ""
    read -p "Select option [all/claude/gemini/cursor/windsurf/codex/agents/others]: " TARGET
fi

copy_skills() {
    local target_dir="$1"
    mkdir -p "$target_dir"
    for skill in "$SCRIPT_DIR/skills"/*; do
        if [ -d "$skill" ]; then
            skill_name="$(basename "$skill")"
            cp -R "$skill" "$target_dir/"
            echo "  [+] Skill installed: $skill_name"
        fi
    done
}

# Copies a rules file over an existing one, keeping a timestamped backup of the
# old file when its content differs (so a user's own global rules are never lost).
install_file() {
    local src="$1"
    local dest="$2"
    [ -f "$src" ] || return 0
    mkdir -p "$(dirname "$dest")"
    if [ -f "$dest" ]; then
        if cmp -s "$src" "$dest"; then
            echo "  [=] Up to date: $dest"
            return 0
        fi
        cp "$dest" "$dest.bak-$STAMP"
        echo "  [~] Backed up existing file to $dest.bak-$STAMP"
    fi
    cp "$src" "$dest"
    echo "  [+] Updated $dest"
}

install_claude() {
    echo "--> Installing for Claude Code..."
    copy_skills "$USER_HOME/.claude/skills"
    install_file "$SCRIPT_DIR/rules/CLAUDE_GLOBAL.md" "$USER_HOME/.claude/CLAUDE.md"
}

install_gemini() {
    echo "--> Installing for Google Antigravity & Gemini CLI..."
    copy_skills "$USER_HOME/.gemini/skills"
    install_file "$SCRIPT_DIR/rules/GEMINI_GLOBAL.md" "$USER_HOME/.gemini/GEMINI.md"
}

install_cursor() {
    echo "--> Installing for Cursor..."
    copy_skills "$USER_HOME/.cursor/skills"
    install_file "$SCRIPT_DIR/rules/CURSOR_GLOBAL.md" "$USER_HOME/.cursor/rules/global_rules.md"
}

install_windsurf() {
    echo "--> Installing for Windsurf..."
    copy_skills "$USER_HOME/.codeium/windsurf/skills"
    install_file "$SCRIPT_DIR/rules/WINDSURF_GLOBAL.md" "$USER_HOME/.codeium/windsurf/memories/global_rules.md"
}

install_codex() {
    echo "--> Installing for OpenAI Codex..."
    install_file "$SCRIPT_DIR/rules/CURSOR_GLOBAL.md" "$USER_HOME/.codex/AGENTS.md"
}

install_agents() {
    echo "--> Installing for Universal Agents (~/.agents)..."
    copy_skills "$USER_HOME/.agents/skills"
    mkdir -p "$USER_HOME/.agents/rules"
    cp "$SCRIPT_DIR/rules/"*.md "$USER_HOME/.agents/rules/"
    echo "  [+] Universal agent rules updated"
}

install_others() {
    echo "--> Installing skills for other installed agents..."
    for entry in "${OTHER_AGENTS[@]}"; do
        name="${entry%%:*}"
        root="$USER_HOME/${entry#*:}"
        if [ ! -d "$root" ]; then
            echo "  [-] $name not found ($root), skipped"
            continue
        fi
        echo "  $name"
        copy_skills "$root/skills"
    done
}

case "$TARGET" in
    all)
        install_claude
        install_gemini
        install_cursor
        install_windsurf
        install_codex
        install_agents
        install_others
        ;;
    claude)
        install_claude
        ;;
    gemini)
        install_gemini
        ;;
    cursor)
        install_cursor
        ;;
    windsurf)
        install_windsurf
        ;;
    codex)
        install_codex
        copy_skills "$USER_HOME/.agents/skills"
        ;;
    agents)
        install_agents
        ;;
    others)
        install_others
        ;;
    *)
        if [ -d "$TARGET" ]; then
            echo "--> Installing standards to project: $TARGET..."
            mkdir -p "$TARGET/.agents/rules"
            cp "$SCRIPT_DIR/rules/"*.md "$TARGET/.agents/rules/"
            echo "  [+] Project rules copied to $TARGET/.agents/rules"
        else
            echo "Unknown target: $TARGET"
            exit 1
        fi
        ;;
esac

echo ""
echo "=========================================================="
echo "   Installation Complete!                                 "
echo "=========================================================="
