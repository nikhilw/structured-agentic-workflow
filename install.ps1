# install.ps1 — Pull superpowers and symlink workflow skills for coding agents
#
# Usage:
#   .\install.ps1                        # Pull superpowers + install for all agents
#   .\install.ps1 -Target claude         # Install for Claude Code only
#   .\install.ps1 -Target gemini         # Install for Gemini CLI only
#   .\install.ps1 -Target cursor         # Install for Cursor only
#   .\install.ps1 -Target copilot        # Install for GitHub Copilot only
#   .\install.ps1 -Remove                # Remove symlinks for all agents
#   .\install.ps1 -Remove -Target claude # Remove for specific agent
#   .\install.ps1 -Local                 # Install without pulling superpowers
#   .\install.ps1 -List                  # Show supported agents and their paths
#
# Note: Creating symlinks on Windows may require Developer Mode enabled
# or an elevated (Administrator) PowerShell session.

[CmdletBinding()]
param(
    [switch]$Remove,
    [switch]$Local,
    [switch]$List,
    [ValidateSet("claude", "cursor", "gemini", "copilot")]
    [string]$Target
)

$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$SkillsSrc = Join-Path $ScriptDir "skills"
$PullScript = Join-Path $ScriptDir "pull-superpowers.ps1"

# Supported agents and their global skills directories
$AgentPaths = @{
    claude  = Join-Path $env:USERPROFILE ".claude" "skills"
    cursor  = Join-Path $env:USERPROFILE ".cursor" "skills"
    gemini  = Join-Path $env:USERPROFILE ".gemini" "skills"
    copilot = Join-Path $env:USERPROFILE ".config" "github-copilot" "skills"
}

$AllAgents = @("claude", "cursor", "gemini", "copilot")

function Get-Skills {
    Get-ChildItem -Path $SkillsSrc -Directory | Select-Object -ExpandProperty Name
}

function Remove-SkillLinks([string]$AgentName, [string]$SkillsDst) {
    $skills = Get-Skills
    Write-Host "  [$AgentName] $SkillsDst"
    foreach ($skill in $skills) {
        $target = Join-Path $SkillsDst $skill
        if (Test-Path $target) {
            $item = Get-Item $target -Force
            if ($item.Attributes -band [System.IO.FileAttributes]::ReparsePoint) {
                Remove-Item $target -Force
                Write-Host "    removed  $skill"
            } else {
                Write-Host "    skipped  $skill (not a symlink - remove manually if intended)"
            }
        }
    }
}

function Install-SkillLinks([string]$AgentName, [string]$SkillsDst) {
    if (-not (Test-Path $SkillsDst)) {
        New-Item -ItemType Directory -Path $SkillsDst -Force | Out-Null
    }

    $skills = Get-Skills
    Write-Host "  [$AgentName] $SkillsDst"
    foreach ($skill in $skills) {
        $src = Join-Path $SkillsSrc $skill
        $target = Join-Path $SkillsDst $skill

        if (-not (Test-Path $src)) {
            Write-Host "    missing  $skill - skipping"
            continue
        }

        if (Test-Path $target) {
            $item = Get-Item $target -Force
            if ($item.Attributes -band [System.IO.FileAttributes]::ReparsePoint) {
                Remove-Item $target -Force
            } else {
                Write-Host "    exists   $skill (not a symlink - back up and remove to install)"
                continue
            }
        }

        New-Item -ItemType SymbolicLink -Path $target -Target $src | Out-Null
        Write-Host "    linked   $skill"
    }
}

function Show-Agents {
    Write-Host "Supported agents:"
    Write-Host ""
    foreach ($agent in $AllAgents) {
        $path = $AgentPaths[$agent]
        $status = if (Test-Path $path) { "installed" } else { "not installed" }
        Write-Host ("  {0,-10} {1} ({2})" -f $agent, $path, $status)
    }
}

# Determine which agents to target
if ($Target) {
    $Targets = @($Target)
} else {
    $Targets = $AllAgents
}

# Execute
if ($List) {
    Show-Agents
} elseif ($Remove) {
    Write-Host "Removing skill symlinks..."
    foreach ($agent in $Targets) {
        Remove-SkillLinks $agent $AgentPaths[$agent]
    }
    Write-Host ""
    Write-Host "Done."
} else {
    if (-not $Local) {
        Write-Host "Pulling superpowers skills..."
        & $PullScript
        Write-Host ""
    }
    Write-Host "Installing workflow skills..."
    foreach ($agent in $Targets) {
        Install-SkillLinks $agent $AgentPaths[$agent]
    }
    Write-Host ""
    Write-Host "Done. Skills are now available."
    Write-Host "Verify with:  Get-ChildItem ~\.claude\skills\  (or other agent paths)"
}
