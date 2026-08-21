#!/bin/bash

# ----------------------------------------------------------
# Argument handling
#   -y / --yes          : assume yes to prompts (install optional
#                         build deps with sudo, pick default icons)
#   --skip-blesh        : never build/install ble.sh
#   --with-nerd-font    : download & install JetBrainsMono Nerd Font
#                         (native Linux only; WSL users get instructions)
#   -h / --help         : show usage
# ----------------------------------------------------------
ASSUME_YES=0
SKIP_BLESH=0
WITH_NERD_FONT=0

usage() {
    echo "Usage: $0 [OPTIONS]"
    echo
    echo "Options:"
    echo "  -y, --yes        Assume yes to prompts (install optional"
    echo "                   build deps with sudo, use default icon style)."
    echo "  --skip-blesh     Never build/install ble.sh."
    echo "  --with-nerd-font Download & install JetBrainsMono Nerd Font"
    echo "                   into ~/.local/share/fonts (native Linux only)."
    echo "                   On WSL the font must be installed on Windows."
    echo "  -h, --help       Show this help and exit."
}

while [ $# -gt 0 ]; do
    case "$1" in
        -y|--yes)  ASSUME_YES=1 ;;
        --skip-blesh) SKIP_BLESH=1 ;;
        --with-nerd-font) WITH_NERD_FONT=1 ;;
        -h|--help) usage; exit 0 ;;
        *) echo "[WARN] Unknown option: $1" ;;
    esac
    shift
done

# Non-interactive detection: stdin is not a terminal (e.g. /dev/null,
# a closed pipe, or CI). When false, prompts silently use defaults.
if [ -t 0 ]; then
    INTERACTIVE=1
else
    INTERACTIVE=0
fi

echo "========================================="
echo "         Dotfiles Setup"
echo "========================================="
echo

echo "[INFO] Setting up your dotfiles..."

# Detect Termux (Android userland): it defines $PREFIX and ships `pkg`,
# a no-sudo package manager, so login shells don't use sudo.
if [ -n "$PREFIX" ] && command -v pkg &> /dev/null; then
    IS_TERMUX=1
else
    IS_TERMUX=0
fi

# Detect WSL (Windows Subsystem for Linux): exposes /mnt/c and runs on a
# Windows terminal host, so Linux-side font installs are invisible to the
# terminal. Detected via the WSL-specific env var or the kernel banner.
if [ -n "${WSL_DISTRO_NAME:-}" ] || grep -qiE "microsoft|wsl" /proc/version 2>/dev/null; then
    IS_WSL=1
else
    IS_WSL=0
fi

# Termux's "C" locale is broken (Bionic setlocale), which makes ble.sh warn on
# every shell load. The documented fix is libandroid-support. Offer to install
# it (consent-gated); once installed, later runs skip the offer.
termux_fix_locale() {
    echo
    echo "[WARN] Termux has no usable UTF-8 locale, which makes ble.sh warn on every shell."
    echo "       The shell config auto-sets LC_ALL=C.UTF-8 (Bionic's native locale);"
    echo "       installing libandroid-support provides the underlying locale data."
    local answer="n"
    if [ "$ASSUME_YES" = "1" ]; then
        answer="y"
        echo "       (-y given: installing)"
    elif [ "$INTERACTIVE" = "1" ]; then
        echo -n "       Install libandroid-support now? [y/N] "
        IFS= read -r answer || answer=""
    else
        echo "       Non-interactive run: install it manually with: pkg install -y libandroid-support"
    fi
    case "${answer:-n}" in
        y|Y|yes|Yes|YES)
            echo "[INFO] Installing libandroid-support..."
            if pkg install -y libandroid-support > /dev/null 2>&1; then
                echo "[OK] libandroid-support installed."
            else
                echo "[WARN] Could not install libandroid-support (pkg install failed)."
            fi
            ;;
        *)
            echo "[INFO] Skipping. Install it yourself later: pkg install -y libandroid-support"
            ;;
    esac
    # Only ask once, so repeated installs don't nag.
    mkdir -p "$HOME/.config/dotfiles"
    touch "$HOME/.config/dotfiles/.locale_fix_asked"
}

if [ "$IS_TERMUX" = "1" ] && [ ! -f "$HOME/.config/dotfiles/.locale_fix_asked" ] && ! locale -a 2>/dev/null | grep -qiE 'utf-?8'; then
    termux_fix_locale
fi

# Install everything into the current user's own directory — no sudo needed.
LOCAL_BIN="$HOME/.local/bin"
mkdir -p "$LOCAL_BIN"

# Make ~/.local/bin available on PATH (findable from any directory).
case ":$PATH:" in
    *":$LOCAL_BIN:"*) ;;
    *) export PATH="$LOCAL_BIN:$PATH" ;;
esac

echo "[INFO] Installing tools into your own user directory: $LOCAL_BIN"
echo "       No sudo or system-wide changes are required."
echo

DOTFILES_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)

# Copy the custom shell config to a stable, repo-independent location so the
# shell keeps working even if this repo is moved or renamed. Re-running the
# installer refreshes this copy.
DOTFILES_CONFIG_DIR="$HOME/.config/dotfiles"
mkdir -p "$DOTFILES_CONFIG_DIR"
BASHRC_CUSTOM="$DOTFILES_CONFIG_DIR/.bashrc_custom"
cp -f "$DOTFILES_DIR/.bashrc_custom" "$BASHRC_CUSTOM"
BASHRC_CUSTOM_ESCAPED=$(printf '%q' "$BASHRC_CUSTOM")

# ----------------------------------------------------------
# lsd
# ----------------------------------------------------------

if ! command -v lsd &> /dev/null; then
    echo "[INFO] Installing lsd..."
    if [ "$IS_TERMUX" = "1" ]; then
        # Termux uses Android's bionic libc, so GitHub musl/glibc binaries
        # won't run. Install the Termux-native package instead.
        if command -v pkg &> /dev/null; then
            echo "[INFO] Installing lsd with pkg (Termux-native build)..."
            pkg install -y lsd > /dev/null 2>&1
        else
            echo "[WARN] pkg not found — install lsd manually: pkg install lsd"
        fi
    elif command -v curl &> /dev/null; then
        echo "[INFO] Fetching latest lsd version..."
        # Fetch the latest release tag. Use jq when available for robust JSON
        # parsing; fall back to a grep/cut for the archive tag name. On an
        # API error (e.g. rate limit) the response is not JSON and the version
        # is left empty, which is handled gracefully below.
        LSD_API_JSON=$(curl -fsSL https://api.github.com/repos/lsd-rs/lsd/releases/latest 2>/dev/null || true)
        if command -v jq &> /dev/null; then
            LSD_VERSION=$(printf '%s' "$LSD_API_JSON" | jq -r '.tag_name // empty' 2>/dev/null)
        else
            LSD_VERSION=$(printf '%s' "$LSD_API_JSON" | grep '"tag_name"' | cut -d'"' -f4)
        fi
        # Map the machine's CPU architecture to lsd's release asset names.
        # 64-bit Intel/ARM use the static musl builds; 32-bit ARM only ships gnu.
        case "$(uname -m)" in
            x86_64|amd64)        LSD_ARCH="x86_64-unknown-linux-musl" ;;
            aarch64|arm64)       LSD_ARCH="aarch64-unknown-linux-musl" ;;
            armv7*|armv6*|arm)   LSD_ARCH="arm-unknown-linux-gnueabihf" ;;
            i686|i386|x86)       LSD_ARCH="i686-unknown-linux-musl" ;;
            *)                   LSD_ARCH="" ;;
        esac
        if [ -n "$LSD_VERSION" ] && [ -n "$LSD_ARCH" ]; then
            LSD_URL="https://github.com/lsd-rs/lsd/releases/download/${LSD_VERSION}/lsd-${LSD_VERSION}-${LSD_ARCH}.tar.gz"
            echo "[INFO] Downloading lsd ${LSD_VERSION} (${LSD_ARCH})..."
            if curl -sL "$LSD_URL" -o /tmp/lsd.tar.gz && \
               tar xzf /tmp/lsd.tar.gz -C /tmp && \
               install -m 755 "/tmp/lsd-${LSD_VERSION}-${LSD_ARCH}/lsd" "$LOCAL_BIN/lsd" && \
               rm -rf /tmp/lsd.tar.gz "/tmp/lsd-${LSD_VERSION}-${LSD_ARCH}"; then
                echo "[OK] lsd installed to $LOCAL_BIN."
            else
                echo "[WARN] Could not install lsd automatically."
            fi
        elif [ -z "$LSD_ARCH" ]; then
            echo "[WARN] Unsupported architecture '$(uname -m)' — cannot download lsd."
            echo "       Install it manually from: https://github.com/lsd-rs/lsd/releases"
        else
            echo "[WARN] Could not determine the latest lsd version."
        fi
    else
        echo "[WARN] curl is required to install lsd."
    fi
    if ! command -v lsd &> /dev/null; then
        echo "[WARN] Could not install lsd. Install it manually from:"
        echo "       https://github.com/lsd-rs/lsd/releases"
    fi
fi

# ----------------------------------------------------------
# ble.sh — Bash Line Editor
# ----------------------------------------------------------

BLESH_DIR="$HOME/.local/share/blesh"
BLESH_PRESENT=false

# Termux may not have /tmp; use a temp dir inside the user's home there.
if [ "$IS_TERMUX" = "1" ]; then
    BLESH_TMP="$HOME/.cache/blesh-build"
else
    BLESH_TMP="/tmp/ble.sh"
fi

if [ -f "$BLESH_DIR/ble.sh" ]; then
    BLESH_PRESENT=true
elif [ "$SKIP_BLESH" = "1" ]; then
    echo "[INFO] Skipping ble.sh (--skip-blesh)."
else
    echo "[INFO] Installing ble.sh (Bash Line Editor)..."

    # ble.sh must be compiled with make and gawk, which may not be present.
    # On normal Linux this needs sudo; on Termux packages install user-local
    # via `pkg`, so no sudo is required.
    BLESH_SKIP=0

    if ! command -v git &> /dev/null; then
        echo "[WARN] git is required to install ble.sh."
        echo "       Install it manually, then re-run this script."
        BLESH_SKIP=1
    elif ! command -v make &> /dev/null || ! command -v gawk &> /dev/null; then
        MISSING_DEPS=""
        command -v make &> /dev/null || MISSING_DEPS="${MISSING_DEPS}make "
        command -v gawk &> /dev/null || MISSING_DEPS="${MISSING_DEPS}gawk"
        if [ "$IS_TERMUX" = "1" ]; then
            echo "[INFO] Installing ${MISSING_DEPS} with pkg (no sudo needed)..."
            pkg install -y make gawk > /dev/null 2>&1
        elif [ "$ASSUME_YES" = "1" ]; then
            echo "[INFO] -y given: installing ${MISSING_DEPS} with sudo..."
            if command -v apt &> /dev/null; then
                sudo apt-get update > /dev/null 2>&1
                sudo apt-get install -y make gawk > /dev/null 2>&1
            elif command -v dnf &> /dev/null; then
                sudo dnf install -y make gawk > /dev/null 2>&1
            elif command -v yum &> /dev/null; then
                sudo yum install -y make gawk > /dev/null 2>&1
            elif command -v pacman &> /dev/null; then
                sudo pacman -S --noconfirm make gawk > /dev/null 2>&1
            elif command -v zypper &> /dev/null; then
                sudo zypper install -y make gawk > /dev/null 2>&1
            elif command -v apk &> /dev/null; then
                sudo apk add make gawk > /dev/null 2>&1
            else
                echo "[WARN] Unrecognized package manager."
                echo "       Install ${MISSING_DEPS} manually, then re-run this script."
            fi
        elif [ "$INTERACTIVE" = "1" ]; then
            echo "[WARN] ${MISSING_DEPS} required to build ble.sh but not installed."
            echo -n "       Install them now? (system-wide, needs sudo) [y/N] "
            IFS= read -r INSTALL_DEPS || INSTALL_DEPS=""
            case "${INSTALL_DEPS:-n}" in
                y|Y|yes|Yes|YES)
                    echo "[INFO] Installing build dependencies with sudo..."
                    if command -v apt &> /dev/null; then
                        # Fresh minimal Debian/Ubuntu images may have empty package
                        # lists; refresh them first or `apt install` can fail.
                        sudo apt-get update > /dev/null 2>&1
                        sudo apt-get install -y make gawk > /dev/null 2>&1
                    elif command -v dnf &> /dev/null; then
                        sudo dnf install -y make gawk > /dev/null 2>&1
                    elif command -v yum &> /dev/null; then
                        sudo yum install -y make gawk > /dev/null 2>&1
                    elif command -v pacman &> /dev/null; then
                        sudo pacman -S --noconfirm make gawk > /dev/null 2>&1
                    elif command -v zypper &> /dev/null; then
                        sudo zypper install -y make gawk > /dev/null 2>&1
                    elif command -v apk &> /dev/null; then
                        sudo apk add make gawk > /dev/null 2>&1
                    else
                        echo "[WARN] Unrecognized package manager."
                        echo "       Install ${MISSING_DEPS} manually, then re-run this script."
                    fi
                    ;;
                *)
                    echo "[INFO] Skipping ble.sh. Install ${MISSING_DEPS} yourself, then re-run."
                    ;;
            esac
        else
            echo "[WARN] ${MISSING_DEPS} required to build ble.sh but not installed and"
            echo "       running non-interactively. Skipping ble.sh (use -y to auto-install)."
        fi
        # If the build deps still aren't available, don't attempt a doomed build.
        if ! command -v make &> /dev/null || ! command -v gawk &> /dev/null; then
            BLESH_SKIP=1
        fi
    fi

    if [ "$BLESH_SKIP" = "0" ]; then
        echo "[INFO] Building ble.sh from GitHub..."
        # Remove any leftover copy so a stale/partial clone can't block us.
        rm -rf "$BLESH_TMP"
        if git clone --recursive --depth 1 --shallow-submodules \
            https://github.com/akinomyoga/ble.sh.git "$BLESH_TMP" \
            > /dev/null 2>&1; then
            if make -C "$BLESH_TMP" install PREFIX="$HOME/.local" > /dev/null 2>&1; then
                BLESH_PRESENT=true
                echo "[OK] ble.sh installed."
            else
                echo "[WARN] ble.sh installation failed during 'make install'."
            fi
            rm -rf "$BLESH_TMP"
        else
            echo "[WARN] ble.sh installation failed: could not clone the repository."
            echo "       Install it manually later from:"
            echo "         https://github.com/akinomyoga/ble.sh"
        fi
    fi
fi

# ----------------------------------------------------------
# starship prompt
# ----------------------------------------------------------

if ! command -v starship &> /dev/null; then
    echo "[INFO] Installing starship..."
    if [ "$IS_TERMUX" = "1" ]; then
        # Termux's bionic libc isn't covered by the GitHub musl/glibc release
        # assets, so keep the official installer there (it handles Termux).
        if command -v curl &> /dev/null; then
            if curl -sS https://starship.rs/install.sh | sh -s -- -y --bin-dir "$LOCAL_BIN" > /dev/null 2>&1; then
                echo "[OK] starship installed to $LOCAL_BIN."
            else
                echo "[WARN] starship installation failed."
                echo "       Install it manually later from:"
                echo "         https://starship.rs/install.sh"
            fi
        else
            echo "[WARN] curl is required to install starship."
            echo "       Install it manually, then re-run this script."
        fi
    elif command -v curl &> /dev/null; then
        echo "[INFO] Fetching latest starship version..."
        STARSHIP_API_JSON=$(curl -fsSL https://api.github.com/repos/starship/starship/releases/latest 2>/dev/null || true)
        if command -v jq &> /dev/null; then
            STARSHIP_VERSION=$(printf '%s' "$STARSHIP_API_JSON" | jq -r '.tag_name // empty' 2>/dev/null)
        else
            STARSHIP_VERSION=$(printf '%s' "$STARSHIP_API_JSON" | grep '"tag_name"' | cut -d'"' -f4)
        fi
        # Map the machine's CPU architecture to starship's release assets.
        case "$(uname -m)" in
            x86_64|amd64)        STARSHIP_ARCH="x86_64-unknown-linux-musl" ;;
            aarch64|arm64)       STARSHIP_ARCH="aarch64-unknown-linux-musl" ;;
            armv7*|armv6*|arm)   STARSHIP_ARCH="arm-unknown-linux-gnueabihf" ;;
            i686|i386|x86)       STARSHIP_ARCH="i686-unknown-linux-musl" ;;
            *)                   STARSHIP_ARCH="" ;;
        esac
        if [ -n "$STARSHIP_VERSION" ] && [ -n "$STARSHIP_ARCH" ]; then
            STARSHIP_URL="https://github.com/starship/starship/releases/download/${STARSHIP_VERSION}/starship-${STARSHIP_ARCH}.tar.gz"
            echo "[INFO] Downloading starship ${STARSHIP_VERSION} (${STARSHIP_ARCH})..."
            if command -v sha256sum &> /dev/null; then
                SHA=$(curl -fsSL "${STARSHIP_URL}.sha256" 2>/dev/null | awk '{print $1}')
                if [ -n "$SHA" ] && \
                   curl -fsSL "$STARSHIP_URL" -o /tmp/starship.tar.gz && \
                   printf '%s  /tmp/starship.tar.gz\n' "$SHA" | sha256sum -c - > /dev/null 2>&1 && \
                   tar xzf /tmp/starship.tar.gz -C /tmp && \
                   install -m 755 /tmp/starship "$LOCAL_BIN/starship" && \
                   rm -rf /tmp/starship.tar.gz; then
                    echo "[OK] starship installed to $LOCAL_BIN."
                else
                    echo "[WARN] Could not install starship automatically (download or checksum failed)."
                    rm -f /tmp/starship.tar.gz
                fi
            else
                echo "[WARN] sha256sum is required to verify the starship download; skipping automatic install."
                echo "       Install it manually from: https://starship.rs/install.sh"
            fi
        elif [ -z "$STARSHIP_ARCH" ]; then
            echo "[WARN] Unsupported architecture '$(uname -m)' — cannot download starship."
            echo "       Install it manually from: https://starship.rs/install.sh"
        else
            echo "[WARN] Could not determine the latest starship version."
        fi
    else
        echo "[WARN] curl is required to install starship."
        echo "       Install it manually, then re-run this script."
    fi
    if ! command -v starship &> /dev/null; then
        echo "[WARN] Could not install starship. Install it manually from:"
        echo "       https://starship.rs/install.sh"
    fi
fi

# ----------------------------------------------------------
# Nerd Font (optional, opt-in)
# ----------------------------------------------------------

# Install JetBrainsMono Nerd Font into the user's own font dir (no sudo).
# On WSL this is a no-op that only prints instructions: a font installed
# inside Linux is invisible to the Windows terminal.
install_nerd_font() {
    local fonttmp
    echo
    if [ "$IS_WSL" = "1" ]; then
        echo "[INFO] Running under WSL: fonts are owned by the Windows host."
        echo "       Install JetBrainsMono Nerd Font on Windows, e.g.:"
        echo "         winget install --id=DEVCOM.JetBrainsMonoNerdFont"
        echo "       (or from https://www.nerdfonts.com/), then restart"
        echo "       Windows Terminal."
        return 0
    fi
    if ! command -v curl &> /dev/null; then
        echo "[WARN] curl is required to install JetBrainsMono Nerd Font."
        return 0
    fi
    echo "[INFO] Installing JetBrainsMono Nerd Font (user-local)..."
    fonttmp="${TMPDIR:-/tmp}/nerd-font-jbm"
    rm -rf "$fonttmp"; mkdir -p "$fonttmp"
    if ! curl -fsSL "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip" \
            -o "$fonttmp/JetBrainsMono.zip" 2>/dev/null; then
        echo "[WARN] Could not download JetBrainsMono Nerd Font."
        rm -rf "$fonttmp"; return 0
    fi
    if command -v unzip &> /dev/null; then
        unzip -q -o "$fonttmp/JetBrainsMono.zip" -d "$fonttmp" 2>/dev/null \
            || { echo "[WARN] The font archive is invalid."; rm -rf "$fonttmp"; return 0; }
    elif command -v bsdtar &> /dev/null; then
        bsdtar -xf "$fonttmp/JetBrainsMono.zip" -C "$fonttmp" 2>/dev/null
    elif command -v python3 &> /dev/null; then
        # Minimal distros often lack unzip but ship python3.
        python3 -c 'import sys,zipfile; zipfile.ZipFile(sys.argv[1]).extractall(sys.argv[2])' \
            "$fonttmp/JetBrainsMono.zip" "$fonttmp" 2>/dev/null \
            || { echo "[WARN] Could not extract the font archive."; rm -rf "$fonttmp"; return 0; }
    else
        echo "[WARN] unzip (or bsdtar/python3) is required to extract the font archive."
        rm -rf "$fonttmp"; return 0
    fi
    if [ "$IS_TERMUX" = "1" ]; then
        # Termux renders its terminal font from ~/.termux/font.ttf (it does not
        # use fontconfig for display), so place a single Nerd Font TTF there.
        mkdir -p "$HOME/.termux"
        # Prefer the regular face; fall back to any TTF in the archive.
        font_file=""
        if [ -f "$fonttmp/JetBrainsMonoNerdFont-Regular.ttf" ]; then
            font_file="$fonttmp/JetBrainsMonoNerdFont-Regular.ttf"
        else
            for f in "$fonttmp"/*.ttf; do
                [ -f "$f" ] && { font_file="$f"; break; }
            done
        fi
        if [ -z "$font_file" ]; then
            echo "[WARN] Could not find a TTF to use as the Termux font."
            rm -rf "$fonttmp"; return 0
        fi
        if cp -f "$font_file" "$HOME/.termux/font.ttf" 2>/dev/null; then
            [ -f "$HOME/.termux/font.ttf" ] && NERD_FOUND=true
            echo "[OK] JetBrainsMono Nerd Font installed as ~/.termux/font.ttf."
            echo "     Restart the Termux app (or run 'termux-reload-settings') to apply it."
        else
            echo "[WARN] Could not copy the font to ~/.termux/font.ttf."
        fi
        rm -rf "$fonttmp"
        return 0
    fi

    mkdir -p "$HOME/.local/share/fonts"
    # Copy each font file explicitly and count successes. (A bare
    # `find ... -exec cp` cannot detect cp failures: find reports its own
    # status, not the command's.)
    copied=0
    for f in "$fonttmp"/*.ttf "$fonttmp"/*.otf; do
        if [ -f "$f" ]; then
            cp -n "$f" "$HOME/.local/share/fonts/" 2>/dev/null && copied=$((copied + 1))
        fi
    done
    if [ "$copied" -eq 0 ]; then
        echo "[WARN] No font files could be copied from the downloaded archive."
        rm -rf "$fonttmp"; return 0
    fi
    rm -rf "$fonttmp"
    if command -v fc-cache &> /dev/null; then
        fc-cache -f "$HOME/.local/share/fonts" > /dev/null 2>&1
        echo "[OK] JetBrainsMono Nerd Font installed (fc-cache refreshed)."
    else
        echo "[OK] JetBrainsMono Nerd Font installed to ~/.local/share/fonts."
        echo "     Run 'fc-cache -f' / restart your terminal if icons don't appear."
    fi
    # Re-detect so the icon picker can default to Fancy.
    if command -v fc-list &> /dev/null; then
        fc-list "$HOME/.local/share/fonts" 2>/dev/null | grep -qiE "nerd" && NERD_FOUND=true
    fi
    if ! $NERD_FOUND; then
        find "$HOME/.local/share/fonts" -maxdepth 1 -iname "*nerd*" 2>/dev/null | grep -q . && NERD_FOUND=true
    fi
}

# ----------------------------------------------------------
# Configure lsd icons
# ----------------------------------------------------------

if command -v lsd &> /dev/null; then
    echo
    echo "[INFO] Configuring lsd icons..."

    # Try to auto-detect Nerd Fonts (look for "Nerd" or "NF" in font names).
    # On WSL, fonts live on the Windows host (invisible to fontconfig), so we
    # additionally scan the Windows user font directory exposed via /mnt/c.
    NERD_FOUND=false
    if command -v fc-list &> /dev/null; then
        fc-list : family 2>/dev/null | grep -qiE "nerd| nf" && NERD_FOUND=true
    fi
    if ! $NERD_FOUND; then
        find "$HOME/.fonts" "$HOME/.local/share/fonts" /usr/share/fonts /usr/local/share/fonts \
            -maxdepth 3 \( -iname "*nerd*" -o -iname "* nf*" -o -iname "*-nf*" \) 2>/dev/null | grep -q . && NERD_FOUND=true
    fi
    if ! $NERD_FOUND && [ "$IS_TERMUX" = "1" ] && [ -f "$HOME/.termux/font.ttf" ]; then
        # Termux renders its terminal font from ~/.termux/font.ttf.
        NERD_FOUND=true
        echo "       ✓ Nerd Font found (Termux font)"
    fi
    if ! $NERD_FOUND && [ "$IS_WSL" = "1" ]; then
        # Windows user-installed fonts (per-user registration; all-users fonts
        # live elsewhere). Matches by file name on the Windows side.
        if find /mnt/c/Users/*/AppData/Local/Microsoft/Windows/Fonts -maxdepth 1 \
            \( -iname "*nerd*" -o -iname "* nf*" -o -iname "*-nf*" \) 2>/dev/null | grep -q .; then
            NERD_FOUND=true
            echo "       ✓ Nerd Font found (Windows host, via /mnt/c)"
        fi
    fi

    # Opt-in: --with-nerd-font installs the font before the icon picker so the
    # Nerd Font (Fancy) option can become the default. On Termux a Nerd Font
    # only matters once it's present as ~/.termux/font.ttf.
    if [ "$WITH_NERD_FONT" = "1" ] && { [ "$IS_TERMUX" = "1" ] && [ ! -f "$HOME/.termux/font.ttf" ] || ! $NERD_FOUND; }; then
        install_nerd_font
    fi

    echo
    echo "       Choose icon style:"
    if $NERD_FOUND; then
        echo "       ✓ Nerd Font found"
        echo "         1) Fancy icons (requires Nerd Font)  [default]"
        DEFAULT_CHOICE=1
    else
        echo "       ✗ Nerd Font not found"
        echo "         1) Fancy icons (requires Nerd Font)"
    fi
    echo "         2) Unicode icons (works on any terminal)"
    if $NERD_FOUND; then
        echo "         3) No icons"
    else
        echo "         3) No icons  [default]"
        DEFAULT_CHOICE=3
    fi
    if [ "$ASSUME_YES" = "1" ] || [ "$INTERACTIVE" != "1" ]; then
        echo "       Non-interactive: using default [$DEFAULT_CHOICE]."
        ICON_CHOICE=$DEFAULT_CHOICE
    else
        read -rp "       Enter choice or press Enter for default [$DEFAULT_CHOICE]: " ICON_CHOICE
        ICON_CHOICE=${ICON_CHOICE:-$DEFAULT_CHOICE}
    fi

    case "$ICON_CHOICE" in
        1)
            if { [ "$IS_TERMUX" = "1" ] && [ ! -f "$HOME/.termux/font.ttf" ]; } || { [ "$IS_TERMUX" != "1" ] && ! $NERD_FOUND; }; then
                install_nerd_font
            fi
            mkdir -p "$HOME/.config/lsd"
            cp "$DOTFILES_DIR/config/lsd/config-fancy.yaml" "$HOME/.config/lsd/config.yaml"
            echo "[OK] Using fancy Nerd Font icons."
            ;;
        2)
            mkdir -p "$HOME/.config/lsd"
            cp "$DOTFILES_DIR/config/lsd/config-unicode.yaml" "$HOME/.config/lsd/config.yaml"
            echo "[OK] Using unicode icons."
            ;;
        3)
            mkdir -p "$HOME/.config/lsd"
            cp "$DOTFILES_DIR/config/lsd/config-no-icons.yaml" "$HOME/.config/lsd/config.yaml"
            echo "[OK] Icons disabled."
            ;;
        *)
            echo "[WARN] Invalid choice. Using default."
            if $NERD_FOUND; then
                mkdir -p "$HOME/.config/lsd"
                cp "$DOTFILES_DIR/config/lsd/config-fancy.yaml" "$HOME/.config/lsd/config.yaml"
                echo "[OK] Using fancy Nerd Font icons."
            else
                mkdir -p "$HOME/.config/lsd"
                cp "$DOTFILES_DIR/config/lsd/config-no-icons.yaml" "$HOME/.config/lsd/config.yaml"
                echo "[OK] Icons disabled."
            fi
            ;;
    esac
    echo
fi

# ----------------------------------------------------------
# starship config
# ----------------------------------------------------------

if command -v starship &> /dev/null; then
    echo "[INFO] Configuring starship with pastel-powerline preset..."
    mkdir -p "$HOME/.config"
    cp "$DOTFILES_DIR/config/starship/starship.toml" "$HOME/.config/starship.toml"
    echo "[OK] starship configuration applied."
    echo
fi

# ----------------------------------------------------------
# Shell setup
# ----------------------------------------------------------

echo "[INFO] Setting up ~/.bashrc..."

# Self-healing managed blocks: we strip any blocks (new or legacy) that a
# previous run wrote, then append the current ones. Re-runs converge to the
# same content, so we never pile up duplicates and our latest user/locale
# fixes always reach already-installed systems.

BLE_START="# ----- dotfiles: ble.sh (managed) -----"
BLE_END="# ----- end dotfiles: ble.sh (managed) -----"
DOT_START="# ----- dotfiles: custom (managed) -----"
DOT_END="# ----- end dotfiles: custom (managed) -----"

BASHRC_FILE="$HOME/.bashrc"
[ -f "$BASHRC_FILE" ] || touch "$BASHRC_FILE"

STRIP="$HOME/.bashrc.doi.$$.s"
STAGE="$HOME/.bashrc.doi.$$.n"
trap 'rm -f "$STRIP" "$STAGE"' EXIT

# strip_pattern: remove lines from an exact start line through an end line
# (or, when the end is "FI", through the next bare "fi"). Idempotent.
strip_pattern() {
    local f="$1" s="$2" e="$3" t
    t="$f.$$"
    if [ "$e" = "FI" ]; then
        awk -v s="$s" '$0==s{d=1;next} d&&$0=="fi"{d=0;next} !d{print}' "$f" > "$t"
    else
        awk -v s="$s" -v e="$e" '$0==s{d=1;next} d&&$0==e{d=0;next} !d{print}' "$f" > "$t"
    fi
    mv "$t" "$f"
}

cp "$BASHRC_FILE" "$STRIP"
strip_pattern "$STRIP" "$BLE_START" "$BLE_END"          # new ble block
strip_pattern "$STRIP" "$DOT_START" "$DOT_END"          # new dotfiles block
# shellcheck disable=SC2016  # literal text that must match the legacy block
strip_pattern "$STRIP" "# Bash Line Editor (ble.sh)" 'source $HOME/.local/share/blesh/ble.sh'  # legacy ble
strip_pattern "$STRIP" "# Load custom dotfiles configuration" "FI"                             # legacy dotfiles

# Remove trailing blank lines left behind by stripping so a re-run is stable.
awk '{ l[NR]=$0 } END { n=NR; while (n>0 && l[n]=="") n--; for (i=1;i<=n;i++) print l[i] }' "$STRIP" > "$STRIP.trim" && mv "$STRIP.trim" "$STRIP"

cp "$STRIP" "$STAGE"
{
    echo
    echo "$DOT_START"
    echo "# Load the custom shell configuration (stable location)"
    echo "if [ -f ${BASHRC_CUSTOM_ESCAPED} ]; then"
    echo "    source ${BASHRC_CUSTOM_ESCAPED}"
    echo "fi"
    echo "$DOT_END"
    if [ "$BLESH_PRESENT" = true ]; then
        echo
        echo "$BLE_START"
        echo "if [ -z \"\${USER:-}\" ] && command -v id &> /dev/null; then export USER=\"\$(id -un)\"; fi"
        echo "if [ -n \"\${PREFIX:-}\" ] && [ -z \"\${LC_ALL:-}\" ]; then export LC_ALL='C.UTF-8' LANG='C.UTF-8' LC_CTYPE='C.UTF-8'; fi"
        echo "# hide ble.sh's one-time 'broken locale' notice (upstream Termux/bionic issue)"
        echo "_blesh_tmp=\"\${TMPDIR:-\$HOME/.cache}\""
        echo "mkdir -p \"\$_blesh_tmp\" 2>/dev/null"
        echo "_blesh_err=\"\$_blesh_tmp/blesh.stderr.\$\$\""
        echo "source \$HOME/.local/share/blesh/ble.sh 2> \"\$_blesh_err\""
        echo "grep -vE 'seems broken|please check the locale settings' \"\$_blesh_err\" 2>/dev/null >&2 || true; rm -f \"\$_blesh_err\""
        echo "$BLE_END"
    fi
} >> "$STAGE"

if cmp -s "$BASHRC_FILE" "$STAGE"; then
    echo "[OK] ~/.bashrc is already up to date."
else
    TIMESTAMP=$(date +%Y%m%d-%H%M)
    if [ -s "$BASHRC_FILE" ]; then
        cp "$BASHRC_FILE" "$HOME/.bashrc.backup.${TIMESTAMP}"
        echo "[OK] Backup created: $HOME/.bashrc.backup.${TIMESTAMP}"
    fi
    cp "$STAGE" "$BASHRC_FILE"
    echo "[OK] ~/.bashrc configured."
fi

echo
echo "========================================="
echo "         Setup Complete"
echo "========================================="
echo
echo "  ✅ Dotfiles configured"
if command -v lsd &> /dev/null; then
    echo "  ✅ lsd ready with icons"
else
    echo "  ⚠️  lsd not installed — using basic ls aliases"
fi
if [ "$BLESH_PRESENT" = true ]; then
    echo "  ✅ ble.sh ready"
elif [ "$SKIP_BLESH" = "1" ] || [ "$BLESH_SKIP" = "1" ] || [ ! -f "$BLESH_DIR/ble.sh" ]; then
    echo "  ⚠️  ble.sh NOT installed — install make+gawk, then re-run (or use -y)"
fi
if command -v starship &> /dev/null; then
    echo "  ✅ starship ready with pastel-powerline preset"
fi
echo
echo -e "\033[1;32m  \u25b6 To apply the changes, run: source ~/.bashrc\033[0m"
echo -e "\033[1;32m    or open a new terminal.\033[0m"
