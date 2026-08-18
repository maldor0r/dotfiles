# =========================================================
#  Dotfiles Setup (Windows PowerShell)
#  Author: maldor0r
# =========================================================

param(
    [switch]$WithNerdFont,                               # download & install JetBrainsMono Nerd Font on Windows
    [ValidateSet("auto", "fancy", "unicode", "none")]    # lsd icon style
    [string]$Icons = "auto"                              #   auto=detect, or force fancy/unicode/none
)

$ErrorActionPreference = "Stop"

Write-Host "========================================="
Write-Host "         Dotfiles Setup (Windows)"
Write-Host "========================================="
Write-Host ""
Write-Host "[INFO] Setting up your dotfiles..."
Write-Host "[INFO] This script installs tools and configures PowerShell."
Write-Host ""

$DOTFILES_DIR = Split-Path -Parent $MyInvocation.MyCommand.Path

# winget/app-installer update the persisted (registry) PATH, but the current
# process keeps its session snapshot; re-read Machine+User PATH so the
# Get-Command checks right after an install see the freshly added programs.
function Refresh-EnvPath {
    $machinePath = [System.Environment]::GetEnvironmentVariable("Path", "Machine")
    $userPath = [System.Environment]::GetEnvironmentVariable("Path", "User")
    $env:Path = (@($machinePath, $userPath) | Where-Object { $_ }) -join ";"
}

# A fresh App Installer (winget) starts with an empty source cache; refresh it
# once so the very first `winget install` doesn't fail with a source error.
if (Get-Command winget -ErrorAction SilentlyContinue) {
    winget source update 2>$null | Out-Null
}

# ----------------------------------------------------------
# starship
# ----------------------------------------------------------

if (-not (Get-Command starship -ErrorAction SilentlyContinue)) {
    Write-Host "[INFO] Installing starship..."
    if (Get-Command winget -ErrorAction SilentlyContinue) {
        winget install --id Starship.Starship --source winget --accept-source-agreements --accept-package-agreements --silent 2>$null
        Refresh-EnvPath
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
        winget install --id lsd-rs.lsd --source winget --accept-source-agreements --accept-package-agreements --silent 2>$null
        Refresh-EnvPath
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
# Nerd Font (optional, opt-in via -WithNerdFont)
# ----------------------------------------------------------

function Test-NerdFont {
    # Registry-first: a font registered for the user/machine shows up here
    # immediately (no process restart needed, unlike the GDI snapshot). Each
    # value name looks like "JetBrainsMono Nerd Font (TrueType)".
    $regPaths = @(
        "HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Fonts",
        "HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Fonts"
    )
    foreach ($p in $regPaths) {
        if (Test-Path $p) {
            foreach ($prop in (Get-ItemProperty $p).PSObject.Properties) {
                if ($prop.Name -match "Nerd|NF") { return $true }
            }
        }
    }
    # Fallback: installed-font collection (cached per process, so mainly used
    # for fonts present before this session started).
    try {
        $coll = New-Object System.Drawing.Text.InstalledFontCollection
        foreach ($family in $coll.Families) {
            if ($family.Name -match "Nerd| NF") { return $true }
        }
    } catch { }
    return $false
}

$nerdFontPresent = Test-NerdFont

# Install the Nerd Font when opted in, no Nerd Font is present, and the user
# did not explicitly pick "none".
if ($WithNerdFont -and -not $nerdFontPresent -and $Icons -ne "none") {
    Write-Host "[INFO] Installing JetBrainsMono Nerd Font..."
    $installed = $false

    # Preferred: winget package.
    if (Get-Command winget -ErrorAction SilentlyContinue) {
        winget install --id DEVCOM.JetBrainsMonoNerdFont --source winget --accept-source-agreements --accept-package-agreements --silent 2>$null
        Refresh-EnvPath
        $installed = Test-NerdFont
    }

    # Fallback: download the release zip and register the fonts per-user.
    if (-not $installed) {
        try {
            $fontDir = Join-Path $env:LOCALAPPDATA "Microsoft\Windows\Fonts"
            $tmp = Join-Path $env:TEMP "jetbrainsmono-nerd.zip"
            $extract = Join-Path $fontDir "jetbrainsmono"
            New-Item -ItemType Directory -Force -Path $fontDir | Out-Null
            Write-Host "      Downloading JetBrainsMono Nerd Font..."
            Invoke-WebRequest -Uri "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip" -OutFile $tmp -UseBasicParsing
            New-Item -ItemType Directory -Force -Path $extract | Out-Null
            Expand-Archive -LiteralPath $tmp -DestinationPath $extract -Force
            Remove-Item $tmp -Force

            if (-not ("Win32.Font" -as [type])) {
                Add-Type -Namespace Win32 -Name Font -MemberDefinition '[DllImport("gdi32.dll")] public static extern int AddFontResource(string file);'
            }

            $fontFiles = Get-ChildItem $extract -Recurse | Where-Object { $_.Extension -in ".ttf", ".otf" }
            $fontsReg = "HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Fonts"
            New-Item -Path $fontsReg -Force | Out-Null
            foreach ($f in $fontFiles) {
                [Win32.Font]::AddFontResource($f.FullName) | Out-Null
                New-ItemProperty -Path $fontsReg -Name $f.BaseName -PropertyType String -Value $f.Name -Force | Out-Null
            }
            $installed = Test-NerdFont
        } catch {
            Write-Warning "Could not install the Nerd Font automatically. Install it manually from https://www.nerdfonts.com/ and restart Windows Terminal."
        }
    }

    $nerdFontPresent = Test-NerdFont
    if ($nerdFontPresent) {
        Write-Host "[OK] Nerd Font installed. Restart Windows Terminal to use it."
    }
}

# Resolve the icon style: explicit choice wins; otherwise auto = fancy when a
# Nerd Font is present, else plain.
if ($Icons -eq "auto") {
    $iconStyle = if ($nerdFontPresent) { "fancy" } else { "none" }
} else {
    $iconStyle = $Icons
}

# Configure lsd icons with the resolved style (only relevant when lsd is installed).
if (Get-Command lsd -ErrorAction SilentlyContinue) {
    $lsdConfigDir = Join-Path $env:USERPROFILE ".config\lsd"
    New-Item -ItemType Directory -Force -Path $lsdConfigDir | Out-Null
    switch ($iconStyle) {
        "fancy" {
            Copy-Item (Join-Path $DOTFILES_DIR "config\lsd\config-fancy.yaml") (Join-Path $lsdConfigDir "config.yaml") -Force
            Write-Host "[OK] lsd configured with fancy Nerd Font icons."
            if (-not $nerdFontPresent) {
                Write-Host "      Note: no Nerd Font detected - icons may not render until one is installed."
            }
        }
        "unicode" {
            Copy-Item (Join-Path $DOTFILES_DIR "config\lsd\config-unicode.yaml") (Join-Path $lsdConfigDir "config.yaml") -Force
            Write-Host "[OK] lsd configured with unicode icons."
        }
        "none" {
            Copy-Item (Join-Path $DOTFILES_DIR "config\lsd\config-no-icons.yaml") (Join-Path $lsdConfigDir "config.yaml") -Force
            Write-Host "[OK] lsd configured with icons disabled."
        }
    }
}

# Informative hint when auto-detection found no Nerd Font.
if ($Icons -eq "auto" -and -not $nerdFontPresent) {
    Write-Host "[INFO] No Nerd Font detected - using plain icons by default."
    Write-Host "       Force a style with -Icons fancy|unicode|none, or install one and"
    Write-Host "       re-run (e.g. winget install --id DEVCOM.JetBrainsMonoNerdFont)."
}

# ----------------------------------------------------------
# PowerShell execution policy
# ----------------------------------------------------------

# The profile generated below is a script; on a default-locked system
# (e.g. a fresh Windows Sandbox) the execution policy "Restricted" blocks
# local scripts and "AllSigned" only allows signed ones. Set it to
# RemoteSigned for the current user only (minimal, non-admin change) so the
# freshly generated local profile loads in future (non-Bypass) sessions.
# We inspect CurrentUser scope rather than the effective policy so a run that
# itself launched under `-ExecutionPolicy Bypass` still normalizes the user
# policy (under Bypass the effective value would be "Bypass" and we would
# otherwise skip doing anything).
$userEp = Get-ExecutionPolicy -Scope CurrentUser
if ($userEp -notin @("RemoteSigned", "Unrestricted", "Bypass")) {
    try {
        Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned -Force
        Write-Host "[OK] Execution policy (CurrentUser) set to RemoteSigned so the profile can load."
    } catch {
        Write-Warning "Could not adjust the execution policy. The profile may not load; run:"
        Write-Warning "    Set-ExecutionPolicy -Scope CurrentUser RemoteSigned"
    }
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

# Detect an existing managed block. If found, replace it in place so re-runs
# self-heal (e.g. lsd aliases appear once lsd gets installed later); if only a
# legacy "starship init" line exists, leave it alone to avoid duplication.
$blockEnd = "# ----- end dotfiles (managed) -----"
$managedReplaced = $false
if (Test-Path $PROFILE) {
    $existing = Get-Content $PROFILE -Raw -ErrorAction SilentlyContinue
    $sIdx = $existing.IndexOf($marker)
    $eIdx = $existing.IndexOf($blockEnd)
    if ($sIdx -ge 0 -and $eIdx -gt $sIdx) {
        $eIdx += $blockEnd.Length
        $ts = Get-Date -Format "yyyyMMdd-HHmm"
        Copy-Item $PROFILE "$PROFILE.$ts.bak"
        Write-Host "[OK] Backup created: $PROFILE.$ts.bak"
        $existing = $existing.Substring(0, $sIdx) + $profileContent + $existing.Substring($eIdx)
        Set-Content -Path $PROFILE -Value $existing
        Write-Host "[OK] Profile updated."
        $managedReplaced = $true
    } elseif ($existing -match "starship init") {
        Write-Host "[OK] Profile is already configured (legacy)."
        $managedReplaced = $true
    }
}

if (-not $managedReplaced) {
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
