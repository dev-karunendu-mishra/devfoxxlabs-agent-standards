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

if (-not ($All -or $Claude -or $Gemini -or $Cursor -or $Windsurf -or $Codex -or $Agents -or $OtherAgents -or $TargetProject)) {
    Write-Host "Select installation target:" -ForegroundColor White
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
    $choice = Read-Host "Enter selection (1-9 or Q)"

    switch ($choice) {
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
        [string]$TargetDir
    )
    Ensure-Dir $TargetDir

    $skills = Get-ChildItem -Path $skillsSource -Directory
    if ($SkillList -and $SkillList.Count -gt 0) {
        $skills = $skills | Where-Object { $SkillList -contains $_.Name }
    }

    foreach ($skill in $skills) {
        # Copy into the parent folder: copying to "$TargetDir\<name>" nests the
        # skill as <name>\<name> when the folder already exists.
        Copy-Item -Path $skill.FullName -Destination $TargetDir -Recurse -Force
        Write-Host "  [+] Skill installed: $($skill.Name)" -ForegroundColor Green
    }
}

# 1. Claude Code
if ($Claude) {
    Write-Host "`n--> Installing for Claude Code..." -ForegroundColor Cyan
    $claudeDir = Join-Path $UserHome ".claude"
    Copy-SkillsToDir -TargetDir (Join-Path $claudeDir "skills")
    Install-File -Source (Join-Path $rulesSource "CLAUDE_GLOBAL.md") -Destination (Join-Path $claudeDir "CLAUDE.md")
}

# 2. Gemini / Antigravity
if ($Gemini) {
    Write-Host "`n--> Installing for Google Antigravity and Gemini CLI..." -ForegroundColor Cyan
    $geminiDir = Join-Path $UserHome ".gemini"
    Copy-SkillsToDir -TargetDir (Join-Path $geminiDir "skills")
    Install-File -Source (Join-Path $rulesSource "GEMINI_GLOBAL.md") -Destination (Join-Path $geminiDir "GEMINI.md")
}

# 3. Cursor
if ($Cursor) {
    Write-Host "`n--> Installing for Cursor..." -ForegroundColor Cyan
    $cursorDir = Join-Path $UserHome ".cursor"
    Copy-SkillsToDir -TargetDir (Join-Path $cursorDir "skills")
    Install-File -Source (Join-Path $rulesSource "CURSOR_GLOBAL.md") -Destination (Join-Path $cursorDir "rules\global_rules.md")
}

# 4. Windsurf
if ($Windsurf) {
    Write-Host "`n--> Installing for Windsurf..." -ForegroundColor Cyan
    $windsurfDir = Join-Path $UserHome ".codeium\windsurf"
    Copy-SkillsToDir -TargetDir (Join-Path $windsurfDir "skills")
    Install-File -Source (Join-Path $rulesSource "WINDSURF_GLOBAL.md") -Destination (Join-Path $windsurfDir "memories\global_rules.md")
}

# 5. OpenAI Codex (global AGENTS.md; skills come from ~/.agents/skills)
if ($Codex) {
    Write-Host "`n--> Installing for OpenAI Codex..." -ForegroundColor Cyan
    $codexDir = Join-Path $UserHome ".codex"
    Install-File -Source (Join-Path $rulesSource "CURSOR_GLOBAL.md") -Destination (Join-Path $codexDir "AGENTS.md")
    if (-not $Agents) {
        Copy-SkillsToDir -TargetDir (Join-Path $UserHome ".agents\skills")
    }
}

# 6. Universal Agents (~/.agents)
if ($Agents) {
    Write-Host "`n--> Installing for Universal Agents (~/.agents)..." -ForegroundColor Cyan
    $agentsDir = Join-Path $UserHome ".agents"
    Copy-SkillsToDir -TargetDir (Join-Path $agentsDir "skills")

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
        $agentRoot = Join-Path $UserHome ($relative.Split("\")[0])
        if (-not (Test-Path $agentRoot)) {
            Write-Host "  [-] $agent not found ($agentRoot), skipped" -ForegroundColor DarkGray
            continue
        }
        Write-Host "  $agent" -ForegroundColor White
        Copy-SkillsToDir -TargetDir (Join-Path $UserHome $relative)
    }
}

# 8. Specific Project Target
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
Write-Host "   Installation Complete! All standards are active.       " -ForegroundColor Green
Write-Host "==========================================================" -ForegroundColor Green
