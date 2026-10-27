<#
.SYNOPSIS
    Syncs skills and rules between the repository and local agent environments.
.DESCRIPTION
    Supports -Pull (update repo from ~/.gemini / ~/.claude) or -Push (deploy repo to agents).
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [ValidateSet("Pull", "Push")]
    [string]$Action = "Push"
)

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$UserHome = $HOME

if ($Action -eq "Push") {
    Write-Host "Pushing repo standards to all local agents..." -ForegroundColor Cyan
    & "$ScriptDir\install.ps1" -All
} else {
    Write-Host "Pulling latest changes from ~/.gemini/skills into repository..." -ForegroundColor Cyan
    $skills = Get-ChildItem -Path "$ScriptDir\skills" -Directory
    foreach ($s in $skills) {
        $source = Join-Path "$UserHome\.gemini\skills" $s.Name
        if (Test-Path $source) {
            Copy-Item -Path $source -Destination "$ScriptDir\skills" -Recurse -Force
            Write-Host "  [<] Pulled: $($s.Name)" -ForegroundColor Green
        }
    }
}
