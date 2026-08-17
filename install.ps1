# =========================================================
#  Dotfiles Setup (Windows PowerShell)
#  Author: maldor0r
# =========================================================

$ErrorActionPreference = "Stop"

Write-Host "========================================="
Write-Host "         Dotfiles Setup (Windows)"
Write-Host "========================================="
Write-Host ""
Write-Host "[INFO] Setting up your dotfiles..."
Write-Host "[INFO] This script installs tools and configures PowerShell."
Write-Host ""

$DOTFILES_DIR = Split-Path -Parent $MyInvocation.MyCommand.Path

# ----------------------------------------------------------
# starship
# ----------------------------------------------------------

if (-not (Get-Command starship -ErrorAction SilentlyContinue)) {
    Write-Host "[INFO] Installing starship..."
    if (Get-Command winget -ErrorAction SilentlyContinue) {
        winget install --id Starship.Starship --accept-source-agreements --accept-package-agreements --silent
    } else {
        Write-Warning "winget not found. Install starship manually (https://starship.rs) and re-run."
    }
    if (Get-Command starship -ErrorAction SilentlyContinue) {
        Write-Host "[OK] starship installed."
    } else {
        Write-Warning "Could not install starship. Install it manually: winget install Starship.Starship"
    }
}

# ----------------------------------------------------------
# lsd
# ----------------------------------------------------------

if (-not (Get-Command lsd -ErrorAction SilentlyContinue)) {
    Write-Host "[INFO] Installing lsd..."
    if (Get-Command winget -ErrorAction SilentlyContinue) {
        winget install --id lsd-rs.lsd --accept-source-agreements --accept-package-agreements --silent
    } else {
        Write-Warning "winget not found. Install lsd manually (https://github.com/lsd-rs/lsd) and re-run."
    }
    if (Get-Command lsd -ErrorAction SilentlyContinue) {
        Write-Host "[OK] lsd installed."
    } else {
        Write-Warning "Could not install lsd. Install it manually: winget install lsd-rs.lsd"
    }
}

# ----------------------------------------------------------
# starship config
# ----------------------------------------------------------

if (Get-Command starship -ErrorAction SilentlyContinue) {
    Write-Host "[INFO] Configuring starship with pastel-powerline preset..."
    $configDir = Join-Path $env:USERPROFILE ".config"
    New-Item -ItemType Directory -Force -Path $configDir | Out-Null
    Copy-Item (Join-Path $DOTFILES_DIR "config\starship\starship.toml") (Join-Path $configDir "starship.toml") -Force
    Write-Host "[OK] starship configuration applied."
    Write-Host ""
}

# ----------------------------------------------------------
# PowerShell profile
# ----------------------------------------------------------

$PROFILE_DIR = Split-Path -Parent $PROFILE
$marker = "# ----- dotfiles (managed) -----"

# Only add lsd aliases when lsd is actually available, so a missing lsd
# doesn't replace the stock, working `ls` with a broken command.
$lsdBlock = ""
if (Get-Command lsd -ErrorAction SilentlyContinue) {
    $lsdBlock = @"

# lsd aliases
Remove-Item Alias:ls -ErrorAction SilentlyContinue

function ls { lsd --group-directories-first @Args }
function ll { lsd -l --group-directories-first @Args }
function la { lsd -a --group-directories-first @Args }
function lla { lsd -la --group-directories-first @Args }
function lt { lsd --tree --depth 3 @Args }
function lta { lsd -a --tree --depth 3 @Args }
function llt { lsd -l --tree --depth 3 @Args }
function llta { lsd -la --tree --depth 3 @Args }
"@
} else {
    Write-Warning "lsd not installed - keeping the default ls. Re-run after installing lsd."
}

Write-Host "[INFO] Setting up PowerShell profile..."

# Build the profile content (managed block delimited by markers)
$profileContent = @"

# ==========================================================
# Custom PowerShell configuration
# Author: maldor0r
# ==========================================================
$marker

# starship prompt
Invoke-Expression (&starship init powershell)
$lsdBlock
# PSReadLine: syntax highlighting and autocomplete (prediction needs PSReadLine 2.2+)
try {
    Set-PSReadLineOption -PredictionSource History
} catch {
    # Older PSReadLine, prediction not supported
}
Set-PSReadLineOption -EditMode Windows

# ----- end dotfiles (managed) -----
"@

# Detect an existing managed block (either our marker or the legacy
# "starship init" text) so we never duplicate the config on re-runs.
$alreadyConfigured = $false
if (Test-Path $PROFILE) {
    $existing = Get-Content $PROFILE -Raw -ErrorAction SilentlyContinue
    if ($existing -match [regex]::Escape($marker) -or $existing -match "starship init") {
        $alreadyConfigured = $true
    }
}

if ($alreadyConfigured) {
    Write-Host "[OK] Profile is already configured."
} else {
    # Back up the existing profile only when we are actually going to modify it.
    if (Test-Path $PROFILE) {
        $ts = Get-Date -Format "yyyyMMdd-HHmm"
        Copy-Item $PROFILE "$PROFILE.$ts.bak"
        Write-Host "[OK] Backup created: $PROFILE.$ts.bak"
        Add-Content -Path $PROFILE -Value $profileContent
        Write-Host "[OK] Configuration added to profile."
    } else {
        New-Item -ItemType Directory -Force -Path $PROFILE_DIR | Out-Null
        Set-Content -Path $PROFILE -Value $profileContent
        Write-Host "[OK] Profile created."
    }
}

Write-Host ""
Write-Host "========================================="
Write-Host "         Setup Complete"
Write-Host "========================================="
Write-Host ""
if (Get-Command starship -ErrorAction SilentlyContinue) { Write-Host "  OK starship ready" }
if (Get-Command lsd -ErrorAction SilentlyContinue) { Write-Host "  OK lsd ready" }
Write-Host ""
Write-Host "To apply the changes, open a new PowerShell window."
