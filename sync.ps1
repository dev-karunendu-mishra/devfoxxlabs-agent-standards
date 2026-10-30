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
$agentKey = $From.ToLower()
# Path rewrite done by install.ps1 for path-aware skills, undone here.
$PathAwareSkills = @("ui-ux-pro-max")
$RepoSkillPrefix = ".gemini/skills/"
$agentPrefix = $skillRoot.Substring($UserHome.Length).TrimStart("\", "/").Replace("\", "/") + "/"
$Utf8NoBom = New-Object System.Text.UTF8Encoding($false)

Write-Host "Pulling skills from $skillRoot into repository..." -ForegroundColor Cyan
$skills = Get-ChildItem -Path "$ScriptDir\skills" -Directory
foreach ($s in $skills) {
    $source = Join-Path $skillRoot $s.Name
    if (-not (Test-Path $source)) { continue }

    # File by file: files that have an agent-specific override go back to overrides\<agent>.
    Get-ChildItem -Path $source -Recurse -File | Where-Object { $_.FullName -notmatch "\\__pycache__\\" } | ForEach-Object {
        $relative = $_.FullName.Substring($source.Length).TrimStart("\")
        $override = Join-Path $ScriptDir "overrides\$agentKey\skills\$($s.Name)\$relative"
        $dest = if (Test-Path $override) { $override } else { Join-Path $s.FullName $relative }
        $destDir = Split-Path -Parent $dest
        if (-not (Test-Path $destDir)) { New-Item -ItemType Directory -Path $destDir -Force | Out-Null }
        Copy-Item -Path $_.FullName -Destination $dest -Force

        if (($dest -eq (Join-Path $s.FullName "SKILL.md")) -and ($PathAwareSkills -contains $s.Name)) {
            $text = [IO.File]::ReadAllText($dest)
            [IO.File]::WriteAllText($dest, $text.Replace($agentPrefix, $RepoSkillPrefix), $Utf8NoBom)
        }
    }
    Write-Host "  [<] Pulled skill: $($s.Name)" -ForegroundColor Green
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
