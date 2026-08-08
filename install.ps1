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
    winget install --id Starship.Starship --accept-source-agreements --accept-package-agreements --silent
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
    winget install --id lsd-rs.lsd --accept-source-agreements --accept-package-agreements --silent
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
$TIMESTAMP = Get-Date -Format "yyyyMMdd-HHmm"

Write-Host "[INFO] Setting up PowerShell profile..."
New-Item -ItemType Directory -Force -Path $PROFILE_DIR | Out-Null

if (Test-Path $PROFILE) {
    Write-Host "[OK] Existing profile found."
    Copy-Item $PROFILE "$PROFILE.$TIMESTAMP.bak"
    Write-Host "[OK] Backup created: $PROFILE.$TIMESTAMP.bak"
} else {
    Write-Host "[INFO] No existing profile found."
}

# Build the profile content
$profileContent = @"

# ==========================================================
# Custom PowerShell configuration
# Author: maldor0r
# ==========================================================

# starship prompt
Invoke-Expression (&starship init powershell)

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

# PSReadLine: syntax highlighting and autocomplete (prediction needs PSReadLine 2.2+)
try {
    Set-PSReadLineOption -PredictionSource History
} catch {
    # Older PSReadLine, prediction not supported
}
Set-PSReadLineOption -EditMode Windows
"@

# Check if already configured
if (Test-Path $PROFILE) {
    $existing = Get-Content $PROFILE -Raw -ErrorAction SilentlyContinue
    if ($existing -match "starship init") {
        Write-Host "[OK] Profile is already configured."
    } else {
        Add-Content -Path $PROFILE -Value $profileContent
        Write-Host "[OK] Configuration added to profile."
    }
} else {
    Set-Content -Path $PROFILE -Value $profileContent
    Write-Host "[OK] Profile created."
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
