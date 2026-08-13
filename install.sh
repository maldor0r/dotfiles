#!/bin/bash

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
BASHRC_CUSTOM="$DOTFILES_DIR/.bashrc_custom"
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
        LSD_VERSION=$(curl -sL https://api.github.com/repos/lsd-rs/lsd/releases/latest | grep '"tag_name"' | cut -d'"' -f4)
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
else
    echo "[INFO] Installing ble.sh (Bash Line Editor)..."

    # ble.sh must be compiled with make and gawk, which may not be present.
    # On normal Linux this needs sudo; on Termux packages install user-local
    # via `pkg`, so no sudo is required.
    if ! command -v git &> /dev/null; then
        echo "[WARN] git is required to install ble.sh."
        echo "       Install it manually, then re-run this script."
    elif ! command -v make &> /dev/null || ! command -v gawk &> /dev/null; then
        if [ "$IS_TERMUX" = "1" ]; then
            echo "[INFO] Installing make and gawk with pkg (no sudo needed)..."
            pkg install -y make gawk > /dev/null 2>&1
        else
            echo "[WARN] make and/or gawk are required to build ble.sh but are not installed."
            echo -n "       Install them now? (system-wide, needs sudo) [y/N] "
            read -r INSTALL_DEPS
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
                        echo "       Install make and gawk manually, then re-run this script."
                    fi
                    ;;
                *)
                    echo "[INFO] Skipping ble.sh. Install make and gawk yourself, then re-run."
                    ;;
            esac
        fi
    fi

    if command -v make &> /dev/null; then
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
    if command -v curl &> /dev/null; then
        if curl -sS https://starship.rs/install.sh | sh -s -- -y --bin-dir "$LOCAL_BIN" > /dev/null 2>&1; then
            echo "[OK] starship installed to $LOCAL_BIN."
        else
            echo "[WARN] starship installation failed."
            echo "       You can install it manually later from:"
            echo "         https://starship.rs/install.sh"
        fi
    else
        echo "[WARN] curl is required to install starship."
        echo "       Install it manually, then re-run this script."
    fi
fi

# ----------------------------------------------------------
# Configure lsd icons
# ----------------------------------------------------------

if command -v lsd &> /dev/null; then
    echo
    echo "[INFO] Configuring lsd icons..."

    # Try to auto-detect Nerd Fonts (look for "Nerd" or "NF" in font names)
    # Note: on WSL this may not find fonts installed on the Windows host,
    # so the user can still pick Fancy manually.
    NERD_FOUND=false
    if command -v fc-list &> /dev/null; then
        fc-list : family 2>/dev/null | grep -qiE "nerd| nf" && NERD_FOUND=true
    fi
    if ! $NERD_FOUND; then
        find "$HOME/.fonts" "$HOME/.local/share/fonts" /usr/share/fonts /usr/local/share/fonts \
            -maxdepth 3 \( -iname "*nerd*" -o -iname "* nf*" -o -iname "*-nf*" \) 2>/dev/null | grep -q . && NERD_FOUND=true
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
    read -rp "       Enter choice or press Enter for default [$DEFAULT_CHOICE]: " ICON_CHOICE
    ICON_CHOICE=${ICON_CHOICE:-$DEFAULT_CHOICE}

    case "$ICON_CHOICE" in
        1)
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

# Only back up ~/.bashrc when we're actually going to modify it, so
# re-running the installer doesn't pile up no-op backups.
ADD_BLESH=false
if [ "$BLESH_PRESENT" = true ] && ! grep -Fq "blesh/ble.sh" "$HOME/.bashrc" 2>/dev/null; then
    ADD_BLESH=true
fi

ADD_DOTFILES=false
if ! grep -Fq "source ${BASHRC_CUSTOM_ESCAPED}" "$HOME/.bashrc" 2>/dev/null; then
    ADD_DOTFILES=true
fi

if [ "$ADD_BLESH" = true ] || [ "$ADD_DOTFILES" = true ]; then
    TIMESTAMP=$(date +%Y%m%d-%H%M)
    if [ -f "$HOME/.bashrc" ]; then
        echo "[OK] Existing .bashrc found."
        cp "$HOME/.bashrc" "$HOME/.bashrc.backup.${TIMESTAMP}"
        echo "[OK] Backup created: $HOME/.bashrc.backup.${TIMESTAMP}"
    else
        echo "[INFO] No existing .bashrc found."
        touch "$HOME/.bashrc"
        echo "[OK] Created new .bashrc."
    fi
fi

# Add ble.sh source if installed
if [ "$ADD_BLESH" = true ]; then
    echo
    echo "[INFO] Adding ble.sh to ~/.bashrc..."
    {
        echo
        echo "# Bash Line Editor (ble.sh)"
        echo "source \$HOME/.local/share/blesh/ble.sh"
    } >> "$HOME/.bashrc"
    echo "[OK] ble.sh added to ~/.bashrc."
fi

echo
echo "[INFO] Checking if dotfiles are already configured..."

if [ "$ADD_DOTFILES" = true ]; then
    echo "[INFO] Adding dotfiles configuration..."
    {
        echo
        echo "# Load custom dotfiles configuration"
        echo "if [ -f ${BASHRC_CUSTOM_ESCAPED} ]; then"
        echo "    source ${BASHRC_CUSTOM_ESCAPED}"
        echo "fi"
    } >> "$HOME/.bashrc"
    echo "[OK] Configuration added."
else
    echo "[OK] Dotfiles are already configured."
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
fi
if command -v starship &> /dev/null; then
    echo "  ✅ starship ready with pastel-powerline preset"
fi
echo
echo -e "\033[1;32m  \u25b6 To apply the changes, run: source ~/.bashrc\033[0m"
echo -e "\033[1;32m    or open a new terminal.\033[0m"
