# DevFoxx Labs - AI Agent Standards and Skills Installer
[CmdletBinding()]
param(
    [switch]$All,
    [switch]$Claude,
    [switch]$Gemini,
    [switch]$Cursor,
    [switch]$Windsurf,
    [switch]$Codex,
    [switch]$Agents,
    [switch]$OtherAgents,
    [switch]$ThirdParty,
    [string]$TargetProject,
    [string[]]$SkillList
)

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$UserHome = $HOME
$Stamp = Get-Date -Format "yyyyMMdd-HHmmss"

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "   DevFoxx Labs - AI Agent Standards and Skills Installer " -ForegroundColor Yellow
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "Repository source: $ScriptDir" -ForegroundColor Gray
Write-Host "User home:         $UserHome" -ForegroundColor Gray
Write-Host ""

if (-not ($All -or $Claude -or $Gemini -or $Cursor -or $Windsurf -or $Codex -or $Agents -or $OtherAgents -or $ThirdParty -or $TargetProject)) {
    Write-Host "Select installation target:" -ForegroundColor White
    Write-Host "  [0] New machine: everything + third-party skills and MCP (same setup as the owner's PC)"
    Write-Host "  [1] All supported agents"
    Write-Host "  [2] Claude Code only (~/.claude)"
    Write-Host "  [3] Google Antigravity and Gemini CLI only (~/.gemini)"
    Write-Host "  [4] Cursor only (~/.cursor)"
    Write-Host "  [5] Windsurf only (~/.codeium/windsurf)"
    Write-Host "  [6] OpenAI Codex only (~/.codex)"
    Write-Host "  [7] Universal Agents standard only (~/.agents)"
    Write-Host "  [8] Other installed agents (Copilot, Continue, Roo, Kilo Code, OpenCode, Trae, ...)"
    Write-Host "  [9] Specific Project repository"
    Write-Host "  [Q] Quit"
    $choice = Read-Host "Enter selection (0-9 or Q)"

    switch ($choice) {
        "0" { $All = $true; $ThirdParty = $true }
        "1" { $All = $true }
        "2" { $Claude = $true }
        "3" { $Gemini = $true }
        "4" { $Cursor = $true }
        "5" { $Windsurf = $true }
        "6" { $Codex = $true }
        "7" { $Agents = $true }
        "8" { $OtherAgents = $true }
        "9" {
            $TargetProject = Read-Host "Enter absolute path to project directory"
        }
        default {
            Write-Host "Aborted by user." -ForegroundColor Yellow
            return
        }
    }
}

if ($All) {
    $Claude = $true
    $Gemini = $true
    $Cursor = $true
    $Windsurf = $true
    $Codex = $true
    $Agents = $true
    $OtherAgents = $true
}

$skillsSource = Join-Path $ScriptDir "skills"
$rulesSource = Join-Path $ScriptDir "rules"
$overridesSource = Join-Path $ScriptDir "overrides"

# Agents that load SKILL.md folders from ~/<root>/<skills dir>. Skills are only
# installed for agents whose root folder already exists on this machine.
$OtherAgentSkillDirs = [ordered]@{
    "GitHub Copilot" = ".copilot\skills"
    "Continue"       = ".continue\skills"
    "Roo Code"       = ".roo\skills"
    "Kilo Code"      = ".kilocode\skills"
    "OpenCode"       = ".opencode\skills"
    "Augment"        = ".augment\skills"
    "CodeBuddy"      = ".codebuddy\skills"
    "Factory"        = ".factory\skills"
    "Qoder"          = ".qoder\skills"
    "Trae"           = ".trae\skills"
    "Warp"           = ".warp\skills"
}

# Skills whose SKILL.md calls its own scripts by an agent-relative path. The repo
# copy uses the Gemini path; each install rewrites it to the target agent's path.
$PathAwareSkills = @("ui-ux-pro-max")
$RepoSkillPrefix = ".gemini/skills/"
$Utf8NoBom = New-Object System.Text.UTF8Encoding($false)

function Ensure-Dir {
    param([string]$Path)
    if (-not (Test-Path $Path)) {
        New-Item -ItemType Directory -Path $Path -Force | Out-Null
    }
}

# Copies a rules file over an existing one, keeping a timestamped backup of the
# old file when its content differs (so a user's own global rules are never lost).
function Install-File {
    param(
        [string]$Source,
        [string]$Destination
    )
    if (-not (Test-Path $Source)) { return }
    Ensure-Dir (Split-Path -Parent $Destination)
    if (Test-Path $Destination) {
        $same = (Get-FileHash $Source).Hash -eq (Get-FileHash $Destination).Hash
        if ($same) {
            Write-Host "  [=] Up to date: $Destination" -ForegroundColor Gray
            return
        }
        $backup = "$Destination.bak-$Stamp"
        Copy-Item -Path $Destination -Destination $backup -Force
        Write-Host "  [~] Backed up existing file to $backup" -ForegroundColor Yellow
    }
    Copy-Item -Path $Source -Destination $Destination -Force
    Write-Host "  [+] Updated $Destination" -ForegroundColor Green
}

function Copy-SkillsToDir {
    param(
        [string]$TargetDir,
        [string]$AgentKey
    )
    Ensure-Dir $TargetDir

    $skills = Get-ChildItem -Path $skillsSource -Directory
    if ($SkillList -and $SkillList.Count -gt 0) {
        $skills = $skills | Where-Object { $SkillList -contains $_.Name }
    }

    # e.g. "C:\Users\me\.cursor\skills" -> ".cursor/skills/"
    $agentPrefix = $TargetDir.Substring($UserHome.Length).TrimStart("\", "/").Replace("\", "/") + "/"

    foreach ($skill in $skills) {
        # Copy into the parent folder: copying to "$TargetDir\<name>" nests the
        # skill as <name>\<name> when the folder already exists.
        Copy-Item -Path $skill.FullName -Destination $TargetDir -Recurse -Force

        if ($PathAwareSkills -contains $skill.Name) {
            $skillMd = Join-Path $TargetDir "$($skill.Name)\SKILL.md"
            $text = [IO.File]::ReadAllText($skillMd)
            [IO.File]::WriteAllText($skillMd, $text.Replace($RepoSkillPrefix, $agentPrefix), $Utf8NoBom)
        }

        $override = Join-Path $overridesSource "$AgentKey\skills\$($skill.Name)"
        if ($AgentKey -and (Test-Path $override)) {
            Copy-Item -Path "$override\*" -Destination (Join-Path $TargetDir $skill.Name) -Recurse -Force
        }
        Write-Host "  [+] Skill installed: $($skill.Name)" -ForegroundColor Green
    }
}

function Test-Command {
    param([string]$Name)
    return [bool](Get-Command $Name -ErrorAction SilentlyContinue)
}

# Bundled skill scripts need Python 3 (ui-ux-pro-max, design, ...) and Node.js (brand, design-system).
if (-not (Test-Command "python") -and -not (Test-Command "python3")) {
    Write-Host "[!] Python 3 not found: skill scripts (ui-ux-pro-max search, design generators) won't run." -ForegroundColor Yellow
}
if (-not (Test-Command "node")) {
    Write-Host "[!] Node.js not found: .cjs skill scripts and -ThirdParty installs need it." -ForegroundColor Yellow
}

# 1. Claude Code
if ($Claude) {
    Write-Host "`n--> Installing for Claude Code..." -ForegroundColor Cyan
    $claudeDir = Join-Path $UserHome ".claude"
    Copy-SkillsToDir -TargetDir (Join-Path $claudeDir "skills") -AgentKey "claude"
    Install-File -Source (Join-Path $rulesSource "CLAUDE_GLOBAL.md") -Destination (Join-Path $claudeDir "CLAUDE.md")
}

# 2. Gemini / Antigravity
if ($Gemini) {
    Write-Host "`n--> Installing for Google Antigravity and Gemini CLI..." -ForegroundColor Cyan
    $geminiDir = Join-Path $UserHome ".gemini"
    Copy-SkillsToDir -TargetDir (Join-Path $geminiDir "skills") -AgentKey "gemini"
    Install-File -Source (Join-Path $rulesSource "GEMINI_GLOBAL.md") -Destination (Join-Path $geminiDir "GEMINI.md")
}

# 3. Cursor (skills from ~/.cursor/skills; global User Rules live in Cursor Settings, not in a file)
if ($Cursor) {
    Write-Host "`n--> Installing for Cursor..." -ForegroundColor Cyan
    $cursorDir = Join-Path $UserHome ".cursor"
    $cursorRuleSrc = Join-Path $rulesSource "CURSOR_GLOBAL.md"
    Copy-SkillsToDir -TargetDir (Join-Path $cursorDir "skills") -AgentKey "cursor"
    Install-File -Source $cursorRuleSrc -Destination (Join-Path $cursorDir "rules\global_rules.md")
    try {
        Get-Content -Path $cursorRuleSrc -Raw -Encoding UTF8 | Set-Clipboard
        Write-Host "  [i] Cursor rules copied to the clipboard." -ForegroundColor White
    } catch {
        Write-Host "  [i] Copy the text of $cursorRuleSrc manually." -ForegroundColor White
    }
    Write-Host "      One-time step: Cursor > Settings > Rules > User Rules > paste." -ForegroundColor White
}

# 4. Windsurf
if ($Windsurf) {
    Write-Host "`n--> Installing for Windsurf..." -ForegroundColor Cyan
    $windsurfDir = Join-Path $UserHome ".codeium\windsurf"
    Copy-SkillsToDir -TargetDir (Join-Path $windsurfDir "skills") -AgentKey "windsurf"
    Install-File -Source (Join-Path $rulesSource "WINDSURF_GLOBAL.md") -Destination (Join-Path $windsurfDir "memories\global_rules.md")
}

# 5. OpenAI Codex (global AGENTS.md; skills come from ~/.agents/skills)
if ($Codex) {
    Write-Host "`n--> Installing for OpenAI Codex..." -ForegroundColor Cyan
    $codexDir = Join-Path $UserHome ".codex"
    Install-File -Source (Join-Path $rulesSource "CURSOR_GLOBAL.md") -Destination (Join-Path $codexDir "AGENTS.md")
    if (-not $Agents) {
        Copy-SkillsToDir -TargetDir (Join-Path $UserHome ".agents\skills") -AgentKey "agents"
    }
}

# 6. Universal Agents (~/.agents)
if ($Agents) {
    Write-Host "`n--> Installing for Universal Agents (~/.agents)..." -ForegroundColor Cyan
    $agentsDir = Join-Path $UserHome ".agents"
    Copy-SkillsToDir -TargetDir (Join-Path $agentsDir "skills") -AgentKey "agents"

    $agentsRules = Join-Path $agentsDir "rules"
    Ensure-Dir $agentsRules
    Get-ChildItem -Path $rulesSource -Filter "*.md" | ForEach-Object {
        Copy-Item -Path $_.FullName -Destination $agentsRules -Force
    }
    Write-Host "  [+] Universal agent rules updated in $agentsRules" -ForegroundColor Green
}

# 7. Other installed agents (skills only)
if ($OtherAgents) {
    Write-Host "`n--> Installing skills for other installed agents..." -ForegroundColor Cyan
    foreach ($agent in $OtherAgentSkillDirs.Keys) {
        $relative = $OtherAgentSkillDirs[$agent]
        $rootName = $relative.Split("\")[0]
        $agentRoot = Join-Path $UserHome $rootName
        if (-not (Test-Path $agentRoot)) {
            Write-Host "  [-] $agent not found ($agentRoot), skipped" -ForegroundColor DarkGray
            continue
        }
        Write-Host "  $agent" -ForegroundColor White
        Copy-SkillsToDir -TargetDir (Join-Path $UserHome $relative) -AgentKey $rootName.TrimStart(".")
    }
}

# 8. Third-party skills and MCP servers (installed from their publishers, not copied from this repo)
if ($ThirdParty) {
    Write-Host "`n--> Installing third-party skills and MCP servers..." -ForegroundColor Cyan
    if (-not (Test-Command "npx")) {
        Write-Host "  [!] npx not found. Install Node.js LTS, then run: .\install.ps1 -ThirdParty" -ForegroundColor Red
    } else {
        $skillAgents = @("codex")
        if (Test-Path (Join-Path $UserHome ".aider-desk")) { $skillAgents += "aider-desk" }

        Write-Host "  Clerk skills (github.com/clerk/skills)" -ForegroundColor White
        & npx -y skills add clerk/skills -g -s '*' -a @skillAgents -y
        Write-Host "  find-skills (github.com/vercel-labs/skills)" -ForegroundColor White
        & npx -y skills add vercel-labs/skills -g -s find-skills -a @skillAgents -y
        Write-Host "  REA MCP server + reverse-engineer-anything skill for Claude Code" -ForegroundColor White
        & npx -y rea-agents@6.7.0 setup --client claude_code --yes
        if ($LASTEXITCODE -ne 0) {
            Write-Host "  [!] Last third-party step failed (exit $LASTEXITCODE). Re-run: .\install.ps1 -ThirdParty" -ForegroundColor Red
        }
    }
}

# 9. Specific Project Target
if ($TargetProject) {
    if (-not (Test-Path $TargetProject)) {
        Write-Error "Project directory '$TargetProject' does not exist."
    }
    Write-Host "`n--> Installing standards to project: $TargetProject..." -ForegroundColor Cyan

    $projectAgentsRules = Join-Path $TargetProject ".agents\rules"
    Ensure-Dir $projectAgentsRules
    Get-ChildItem -Path $rulesSource -Filter "*.md" | ForEach-Object {
        Copy-Item -Path $_.FullName -Destination $projectAgentsRules -Force
    }
    Write-Host "  [+] Project rules copied to $projectAgentsRules" -ForegroundColor Green
}

Write-Host "`n==========================================================" -ForegroundColor Green
Write-Host "   Installation Complete! Restart your agents to load it.  " -ForegroundColor Green
Write-Host "==========================================================" -ForegroundColor Green
