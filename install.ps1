# DevFoxx Labs - AI Agent Standards and Skills Installer
[CmdletBinding()]
param(
    [switch]$All,
    [switch]$Claude,
    [switch]$Gemini,
    [switch]$Cursor,
    [switch]$Windsurf,
    [switch]$Agents,
    [string]$TargetProject,
    [string[]]$SkillList
)

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$UserHome = $HOME

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "   DevFoxx Labs - AI Agent Standards and Skills Installer " -ForegroundColor Yellow
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "Repository source: $ScriptDir" -ForegroundColor Gray
Write-Host "User home:         $UserHome" -ForegroundColor Gray
Write-Host ""

if (-not ($All -or $Claude -or $Gemini -or $Cursor -or $Windsurf -or $Agents -or $TargetProject)) {
    Write-Host "Select installation target:" -ForegroundColor White
    Write-Host "  [1] All supported agents (Claude, Gemini, Cursor, Windsurf, Universal Agents)"
    Write-Host "  [2] Claude Code only (~/.claude)"
    Write-Host "  [3] Google Antigravity and Gemini CLI only (~/.gemini)"
    Write-Host "  [4] Cursor only (~/.cursor)"
    Write-Host "  [5] Windsurf only (~/.codeium/windsurf)"
    Write-Host "  [6] Universal Agents standard only (~/.agents)"
    Write-Host "  [7] Specific Project repository"
    Write-Host "  [Q] Quit"
    $choice = Read-Host "Enter selection (1-7 or Q)"

    switch ($choice) {
        "1" { $All = $true }
        "2" { $Claude = $true }
        "3" { $Gemini = $true }
        "4" { $Cursor = $true }
        "5" { $Windsurf = $true }
        "6" { $Agents = $true }
        "7" {
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
    $Agents = $true
}

$skillsSource = Join-Path $ScriptDir "skills"
$rulesSource = Join-Path $ScriptDir "rules"

function Copy-SkillsToDir {
    param(
        [string]$TargetDir
    )
    if (-not (Test-Path $TargetDir)) {
        New-Item -ItemType Directory -Path $TargetDir -Force | Out-Null
    }
    
    $skills = Get-ChildItem -Path $skillsSource -Directory
    if ($SkillList -and $SkillList.Count -gt 0) {
        $skills = $skills | Where-Object { $SkillList -contains $_.Name }
    }

    foreach ($skill in $skills) {
        $destPath = Join-Path $TargetDir $skill.Name
        Copy-Item -Path $skill.FullName -Destination $destPath -Recurse -Force
        Write-Host "  [+] Skill installed: $($skill.Name)" -ForegroundColor Green
    }
}

# 1. Claude Code
if ($Claude) {
    Write-Host "`n--> Installing for Claude Code..." -ForegroundColor Cyan
    $claudeDir = Join-Path $UserHome ".claude"
    $claudeSkills = Join-Path $claudeDir "skills"
    Copy-SkillsToDir -TargetDir $claudeSkills

    $claudeMdDest = Join-Path $claudeDir "CLAUDE.md"
    $claudeMdSrc = Join-Path $rulesSource "CLAUDE_GLOBAL.md"
    if (Test-Path $claudeMdSrc) {
        Copy-Item -Path $claudeMdSrc -Destination $claudeMdDest -Force
        Write-Host "  [+] Global CLAUDE.md updated ($claudeMdDest)" -ForegroundColor Green
    }
}

# 2. Gemini / Antigravity
if ($Gemini) {
    Write-Host "`n--> Installing for Google Antigravity and Gemini CLI..." -ForegroundColor Cyan
    $geminiDir = Join-Path $UserHome ".gemini"
    $geminiSkills = Join-Path $geminiDir "skills"
    Copy-SkillsToDir -TargetDir $geminiSkills

    $geminiMdDest = Join-Path $geminiDir "GEMINI.md"
    $geminiMdSrc = Join-Path $rulesSource "GEMINI_GLOBAL.md"
    if (Test-Path $geminiMdSrc) {
        Copy-Item -Path $geminiMdSrc -Destination $geminiMdDest -Force
        Write-Host "  [+] Global GEMINI.md updated ($geminiMdDest)" -ForegroundColor Green
    }
}

# 3. Cursor
if ($Cursor) {
    Write-Host "`n--> Installing for Cursor..." -ForegroundColor Cyan
    $cursorDir = Join-Path $UserHome ".cursor"
    $cursorSkills = Join-Path $cursorDir "skills"
    Copy-SkillsToDir -TargetDir $cursorSkills

    $cursorRulesDir = Join-Path $cursorDir "rules"
    if (-not (Test-Path $cursorRulesDir)) {
        New-Item -ItemType Directory -Path $cursorRulesDir -Force | Out-Null
    }
    $cursorRuleSrc = Join-Path $rulesSource "CURSOR_GLOBAL.md"
    if (Test-Path $cursorRuleSrc) {
        Copy-Item -Path $cursorRuleSrc -Destination (Join-Path $cursorRulesDir "global_rules.md") -Force
        Write-Host "  [+] Cursor global rules updated" -ForegroundColor Green
    }
}

# 4. Windsurf
if ($Windsurf) {
    Write-Host "`n--> Installing for Windsurf..." -ForegroundColor Cyan
    $windsurfMemDir = Join-Path $UserHome ".codeium\windsurf\memories"
    if (-not (Test-Path $windsurfMemDir)) {
        New-Item -ItemType Directory -Path $windsurfMemDir -Force | Out-Null
    }
    $windsurfSrc = Join-Path $rulesSource "WINDSURF_GLOBAL.md"
    if (Test-Path $windsurfSrc) {
        Copy-Item -Path $windsurfSrc -Destination (Join-Path $windsurfMemDir "global_rules.md") -Force
        Write-Host "  [+] Windsurf memories/global_rules.md updated" -ForegroundColor Green
    }
}

# 5. Universal Agents (~/.agents)
if ($Agents) {
    Write-Host "`n--> Installing for Universal Agents (~/.agents)..." -ForegroundColor Cyan
    $agentsDir = Join-Path $UserHome ".agents"
    $agentsSkills = Join-Path $agentsDir "skills"
    $agentsRules = Join-Path $agentsDir "rules"
    Copy-SkillsToDir -TargetDir $agentsSkills

    if (-not (Test-Path $agentsRules)) {
        New-Item -ItemType Directory -Path $agentsRules -Force | Out-Null
    }
    Get-ChildItem -Path $rulesSource -Filter "*.md" | ForEach-Object {
        Copy-Item -Path $_.FullName -Destination $agentsRules -Force
    }
    Write-Host "  [+] Universal agent rules updated in $agentsRules" -ForegroundColor Green
}

# 6. Specific Project Target
if ($TargetProject) {
    if (-not (Test-Path $TargetProject)) {
        Write-Error "Project directory '$TargetProject' does not exist."
    }
    Write-Host "`n--> Installing standards to project: $TargetProject..." -ForegroundColor Cyan
    
    $projectAgentsRules = Join-Path $TargetProject ".agents\rules"
    if (-not (Test-Path $projectAgentsRules)) {
        New-Item -ItemType Directory -Path $projectAgentsRules -Force | Out-Null
    }
    Get-ChildItem -Path $rulesSource -Filter "*.md" | ForEach-Object {
        Copy-Item -Path $_.FullName -Destination $projectAgentsRules -Force
    }
    Write-Host "  [+] Project rules copied to $projectAgentsRules" -ForegroundColor Green
}

Write-Host "`n==========================================================" -ForegroundColor Green
Write-Host "   Installation Complete! All standards are active.       " -ForegroundColor Green
Write-Host "==========================================================" -ForegroundColor Green

