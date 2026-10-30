<#
.SYNOPSIS
    Syncs skills and rules between the repository and local agent environments.
.DESCRIPTION
    -Action Push : deploy the repo to every local agent (runs install.ps1 -All).
    -Action Pull : update the repo from a local agent. Only skills that already exist in
                   the repo are pulled, so third-party skills never leak in. Global rules
                   are pulled from ~/.claude/CLAUDE.md, ~/.gemini/GEMINI.md,
                   Windsurf memories and ~/.agents/rules.
.PARAMETER From
    Agent to pull skills from: Claude (default), Gemini, Agents or Cursor.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [ValidateSet("Pull", "Push")]
    [string]$Action = "Push",

    [Parameter(Mandatory=$false)]
    [ValidateSet("Claude", "Gemini", "Agents", "Cursor")]
    [string]$From = "Claude"
)

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$UserHome = $HOME

if ($Action -eq "Push") {
    Write-Host "Pushing repo standards to all local agents..." -ForegroundColor Cyan
    & "$ScriptDir\install.ps1" -All
    return
}

$skillRoots = @{
    "Claude" = "$UserHome\.claude\skills"
    "Gemini" = "$UserHome\.gemini\skills"
    "Agents" = "$UserHome\.agents\skills"
    "Cursor" = "$UserHome\.cursor\skills"
}
$skillRoot = $skillRoots[$From]

Write-Host "Pulling skills from $skillRoot into repository..." -ForegroundColor Cyan
$skills = Get-ChildItem -Path "$ScriptDir\skills" -Directory
foreach ($s in $skills) {
    $source = Join-Path $skillRoot $s.Name
    if (Test-Path $source) {
        Copy-Item -Path $source -Destination "$ScriptDir\skills" -Recurse -Force
        Write-Host "  [<] Pulled skill: $($s.Name)" -ForegroundColor Green
    }
}

Write-Host "Pulling global rules into repository..." -ForegroundColor Cyan
$ruleSources = [ordered]@{
    "$UserHome\.claude\CLAUDE.md"                         = "CLAUDE_GLOBAL.md"
    "$UserHome\.gemini\GEMINI.md"                         = "GEMINI_GLOBAL.md"
    "$UserHome\.codeium\windsurf\memories\global_rules.md" = "WINDSURF_GLOBAL.md"
}
foreach ($source in $ruleSources.Keys) {
    if (Test-Path $source) {
        Copy-Item -Path $source -Destination (Join-Path "$ScriptDir\rules" $ruleSources[$source]) -Force
        Write-Host "  [<] Pulled rule: $($ruleSources[$source])" -ForegroundColor Green
    }
}
$agentsRules = "$UserHome\.agents\rules"
if (Test-Path $agentsRules) {
    Get-ChildItem -Path "$ScriptDir\rules" -Filter "*.md" | ForEach-Object {
        $source = Join-Path $agentsRules $_.Name
        if ((Test-Path $source) -and ($ruleSources.Values -notcontains $_.Name)) {
            Copy-Item -Path $source -Destination $_.FullName -Force
            Write-Host "  [<] Pulled rule: $($_.Name)" -ForegroundColor Green
        }
    }
}

Write-Host "Review the changes with 'git diff' before committing." -ForegroundColor Yellow
