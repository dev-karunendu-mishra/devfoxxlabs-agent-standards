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

# Skills whose SKILL.md calls its own scripts by an agent-relative path. The repo
# copy uses the Gemini path; each install rewrites it to the target agent's path.
PATH_AWARE_SKILLS=("ui-ux-pro-max")
REPO_SKILL_PREFIX=".gemini/skills/"

echo "=========================================================="
echo "   DevFoxx Labs — AI Agent Standards & Skills Installer   "
echo "=========================================================="
echo "Source: $SCRIPT_DIR"
echo "Home:   $USER_HOME"
echo ""

TARGET="$1"

if [ -z "$TARGET" ]; then
    echo "Usage: ./install.sh [new-machine|all|claude|gemini|cursor|windsurf|codex|agents|others|thirdparty|<path_to_project>]"
    echo "  new-machine - all + thirdparty (same setup as the owner's PC)"
    echo "  all      - Install for every supported agent"
    echo "  claude   - Install to ~/.claude"
    echo "  gemini   - Install to ~/.gemini"
    echo "  cursor   - Install to ~/.cursor"
    echo "  windsurf - Install to ~/.codeium/windsurf"
    echo "  codex    - Install to ~/.codex (AGENTS.md) + ~/.agents/skills"
    echo "  agents   - Install to ~/.agents"
    echo "  others   - Skills for other installed agents (Copilot, Continue, Roo, Kilo Code, OpenCode, Trae, ...)"
    echo "  thirdparty - Clerk skills, find-skills and the REA MCP server (needs Node.js)"
    echo ""
    read -p "Select option [new-machine/all/claude/gemini/cursor/windsurf/codex/agents/others/thirdparty]: " TARGET
fi

copy_skills() {
    local target_dir="$1"
    local agent_key="$2"
    # e.g. "$HOME/.cursor/skills" -> ".cursor/skills/"
    local agent_prefix="${target_dir#"$USER_HOME"/}/"
    mkdir -p "$target_dir"
    for skill in "$SCRIPT_DIR/skills"/*; do
        if [ -d "$skill" ]; then
            skill_name="$(basename "$skill")"
            cp -R "$skill" "$target_dir/"
            if [[ " ${PATH_AWARE_SKILLS[*]} " == *" $skill_name "* ]]; then
                local skill_md="$target_dir/$skill_name/SKILL.md"
                sed "s#${REPO_SKILL_PREFIX}#${agent_prefix}#g" "$skill_md" > "$skill_md.tmp" && mv "$skill_md.tmp" "$skill_md"
            fi
            local override="$SCRIPT_DIR/overrides/$agent_key/skills/$skill_name"
            if [ -n "$agent_key" ] && [ -d "$override" ]; then
                cp -R "$override/." "$target_dir/$skill_name/"
            fi
            echo "  [+] Skill installed: $skill_name"
        fi
    done
}

# Bundled skill scripts need Python 3 (ui-ux-pro-max, design, ...) and Node.js (brand, design-system).
command -v python3 >/dev/null 2>&1 || echo "[!] Python 3 not found: skill scripts (ui-ux-pro-max search, design generators) won't run."
command -v node >/dev/null 2>&1 || echo "[!] Node.js not found: .cjs skill scripts and thirdparty installs need it."

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
    copy_skills "$USER_HOME/.claude/skills" claude
    install_file "$SCRIPT_DIR/rules/CLAUDE_GLOBAL.md" "$USER_HOME/.claude/CLAUDE.md"
}

install_gemini() {
    echo "--> Installing for Google Antigravity & Gemini CLI..."
    copy_skills "$USER_HOME/.gemini/skills" gemini
    install_file "$SCRIPT_DIR/rules/GEMINI_GLOBAL.md" "$USER_HOME/.gemini/GEMINI.md"
}

install_cursor() {
    echo "--> Installing for Cursor..."
    copy_skills "$USER_HOME/.cursor/skills" cursor
    install_file "$SCRIPT_DIR/rules/CURSOR_GLOBAL.md" "$USER_HOME/.cursor/rules/global_rules.md"
    # Cursor keeps global User Rules in its Settings, not in a file.
    if command -v pbcopy >/dev/null 2>&1; then
        pbcopy < "$SCRIPT_DIR/rules/CURSOR_GLOBAL.md" && echo "  [i] Cursor rules copied to the clipboard."
    elif command -v xclip >/dev/null 2>&1; then
        xclip -selection clipboard < "$SCRIPT_DIR/rules/CURSOR_GLOBAL.md" && echo "  [i] Cursor rules copied to the clipboard."
    else
        echo "  [i] Copy the text of $SCRIPT_DIR/rules/CURSOR_GLOBAL.md manually."
    fi
    echo "      One-time step: Cursor > Settings > Rules > User Rules > paste."
}

install_windsurf() {
    echo "--> Installing for Windsurf..."
    copy_skills "$USER_HOME/.codeium/windsurf/skills" windsurf
    install_file "$SCRIPT_DIR/rules/WINDSURF_GLOBAL.md" "$USER_HOME/.codeium/windsurf/memories/global_rules.md"
}

install_codex() {
    echo "--> Installing for OpenAI Codex..."
    install_file "$SCRIPT_DIR/rules/CURSOR_GLOBAL.md" "$USER_HOME/.codex/AGENTS.md"
}

install_agents() {
    echo "--> Installing for Universal Agents (~/.agents)..."
    copy_skills "$USER_HOME/.agents/skills" agents
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
        copy_skills "$root/skills" "${root##*/.}"
    done
}

# Third-party skills and MCP servers, installed from their publishers (not copied from this repo).
install_thirdparty() {
    echo "--> Installing third-party skills and MCP servers..."
    if ! command -v npx >/dev/null 2>&1; then
        echo "  [!] npx not found. Install Node.js LTS, then run: ./install.sh thirdparty"
        return 0
    fi
    local skill_agents=(codex)
    [ -d "$USER_HOME/.aider-desk" ] && skill_agents+=(aider-desk)
    echo "  Clerk skills (github.com/clerk/skills)"
    npx -y skills add clerk/skills -g -s '*' -a "${skill_agents[@]}" -y
    echo "  find-skills (github.com/vercel-labs/skills)"
    npx -y skills add vercel-labs/skills -g -s find-skills -a "${skill_agents[@]}" -y
    echo "  REA MCP server + reverse-engineer-anything skill for Claude Code"
    npx -y rea-agents@6.7.0 setup --client claude_code --yes
}

case "$TARGET" in
    new-machine)
        install_claude
        install_gemini
        install_cursor
        install_windsurf
        install_codex
        install_agents
        install_others
        install_thirdparty
        ;;
    thirdparty)
        install_thirdparty
        ;;
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
        copy_skills "$USER_HOME/.agents/skills" agents
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
echo "   Installation Complete! Restart your agents to load it.  "
echo "=========================================================="
