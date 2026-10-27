#!/usr/bin/env bash
# DevFoxx Labs — AI Agent Standards & Skills Installer (Linux & macOS)

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
USER_HOME="$HOME"

echo "=========================================================="
echo "   DevFoxx Labs — AI Agent Standards & Skills Installer   "
echo "=========================================================="
echo "Source: $SCRIPT_DIR"
echo "Home:   $USER_HOME"
echo ""

TARGET="$1"

if [ -z "$TARGET" ]; then
    echo "Usage: ./install.sh [all|claude|gemini|cursor|windsurf|agents|<path_to_project>]"
    echo "  all      - Install across Claude, Gemini/Antigravity, Cursor, Windsurf, ~/.agents"
    echo "  claude   - Install to ~/.claude"
    echo "  gemini   - Install to ~/.gemini"
    echo "  cursor   - Install to ~/.cursor"
    echo "  windsurf - Install to ~/.codeium/windsurf"
    echo "  agents   - Install to ~/.agents"
    echo ""
    read -p "Select option [all/claude/gemini/cursor/windsurf/agents]: " TARGET
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

install_claude() {
    echo "--> Installing for Claude Code..."
    copy_skills "$USER_HOME/.claude/skills"
    mkdir -p "$USER_HOME/.claude"
    cp "$SCRIPT_DIR/rules/CLAUDE_GLOBAL.md" "$USER_HOME/.claude/CLAUDE.md"
    echo "  [+] Global CLAUDE.md updated"
}

install_gemini() {
    echo "--> Installing for Google Antigravity & Gemini CLI..."
    copy_skills "$USER_HOME/.gemini/skills"
    mkdir -p "$USER_HOME/.gemini"
    cp "$SCRIPT_DIR/rules/GEMINI_GLOBAL.md" "$USER_HOME/.gemini/GEMINI.md"
    echo "  [+] Global GEMINI.md updated"
}

install_cursor() {
    echo "--> Installing for Cursor..."
    copy_skills "$USER_HOME/.cursor/skills"
    mkdir -p "$USER_HOME/.cursor/rules"
    cp "$SCRIPT_DIR/rules/CURSOR_GLOBAL.md" "$USER_HOME/.cursor/rules/global_rules.md"
    echo "  [+] Cursor global rules updated"
}

install_windsurf() {
    echo "--> Installing for Windsurf..."
    mkdir -p "$USER_HOME/.codeium/windsurf/memories"
    cp "$SCRIPT_DIR/rules/WINDSURF_GLOBAL.md" "$USER_HOME/.codeium/windsurf/memories/global_rules.md"
    echo "  [+] Windsurf memories/global_rules.md updated"
}

install_agents() {
    echo "--> Installing for Universal Agents (~/.agents)..."
    copy_skills "$USER_HOME/.agents/skills"
    mkdir -p "$USER_HOME/.agents/rules"
    cp "$SCRIPT_DIR/rules/"*.md "$USER_HOME/.agents/rules/"
    echo "  [+] Universal agent rules updated"
}

case "$TARGET" in
    all)
        install_claude
        install_gemini
        install_cursor
        install_windsurf
        install_agents
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
    agents)
        install_agents
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
