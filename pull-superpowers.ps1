# pull-superpowers.ps1 — Fetch specific skills from obra/superpowers into vendor/
#
# These skills are MIT-licensed by Jesse Vincent (2025).
# See: https://github.com/obra/superpowers
#
# Usage:
#   .\pull-superpowers.ps1          # Fetch/update vendored skills
#   .\pull-superpowers.ps1 -Clean   # Remove vendored skills

[CmdletBinding()]
param(
    [switch]$Clean
)

$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$VendorDir = Join-Path $ScriptDir "vendor" "superpowers"
$RepoUrl = "https://github.com/obra/superpowers.git"
$Branch = "main"

# Skills we adopt from superpowers.
#
# We keep the upstream names verbatim so users who install via
# `npx skills add obra/superpowers` (which has no rename flag) and users who
# install via our install script end up with identically-named skills.
$Skills = @(
    "brainstorming"
    "test-driven-development"
    "systematic-debugging"
    "verification-before-completion"
)

function Remove-VendoredSkills {
    Write-Host "Removing vendored superpowers skills..."
    if (Test-Path $VendorDir) {
        Remove-Item $VendorDir -Recurse -Force
    }
    Write-Host "Done."
}

function Fetch-SuperpowersSkills {
    $tmpDir = Join-Path ([System.IO.Path]::GetTempPath()) "superpowers-$(Get-Random)"

    try {
        Write-Host "Cloning obra/superpowers (sparse)..."
        git clone --depth 1 --filter=blob:none --sparse $RepoUrl "$tmpDir/superpowers" 2>&1 |
            ForEach-Object { Write-Host "  $_" }

        Push-Location "$tmpDir/superpowers"

        $sparseArgs = ($Skills | ForEach-Object { "skills/$_" }) + @("/LICENSE")
        git sparse-checkout set --no-cone @sparseArgs
        $checkoutPaths = @("LICENSE") + ($Skills | ForEach-Object { "skills/$_" })
        git checkout $Branch -- @checkoutPaths 2>$null

        # Copy into vendor directory
        if (-not (Test-Path $VendorDir)) {
            New-Item -ItemType Directory -Path $VendorDir -Force | Out-Null
        }

        # Copy license
        Copy-Item "LICENSE" (Join-Path $VendorDir "LICENSE") -Force
        Write-Host "  copied   LICENSE"

        # Copy skills to vendor
        foreach ($skill in $Skills) {
            $src = Join-Path "skills" $skill
            $dst = Join-Path $VendorDir $skill
            if (Test-Path $src) {
                if (Test-Path $dst) { Remove-Item $dst -Recurse -Force }
                Copy-Item $src $dst -Recurse
                Write-Host "  copied   $skill/"
            } else {
                Write-Host "  missing  $skill/ - skipping"
            }
        }

        Pop-Location

        # Copy vendored skills into skills/ (names preserved from upstream)
        Write-Host ""
        Write-Host "Installing superpowers into skills/..."
        $skillsDir = Join-Path $ScriptDir "skills"

        foreach ($skill in $Skills) {
            $vendorSrc = Join-Path $VendorDir $skill
            if (-not (Test-Path $vendorSrc)) { continue }

            $dst = Join-Path $skillsDir $skill
            if (Test-Path $dst) { Remove-Item $dst -Recurse -Force }
            Copy-Item $vendorSrc $dst -Recurse
            Write-Host "  copied   $skill/ -> skills/$skill/"
        }

        # Strip the `superpowers:` namespace prefix on cross-references so the
        # skills resolve in agents that don't understand plugin-style namespacing.
        $debugSkill = Join-Path $skillsDir "systematic-debugging" "SKILL.md"
        if (Test-Path $debugSkill) {
            (Get-Content $debugSkill) `
                -replace "superpowers:test-driven-development", "/test-driven-development" `
                -replace "superpowers:verification-before-completion", "/verification-before-completion" |
                Set-Content $debugSkill
        }

        Write-Host ""
        Write-Host "Done. Vendored skills are in vendor/superpowers/"
        Write-Host "Superpowers skills installed into skills/"
        Write-Host "License: MIT (Jesse Vincent, 2025)"
        Write-Host "Source:  https://github.com/obra/superpowers"
    } finally {
        if (Test-Path $tmpDir) {
            Remove-Item $tmpDir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}

if ($Clean) {
    Remove-VendoredSkills
} else {
    Fetch-SuperpowersSkills
}
