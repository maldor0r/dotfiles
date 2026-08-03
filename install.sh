#!/bin/bash

echo "========================================="
echo "         Dotfiles Setup"
echo "========================================="
echo

echo "[INFO] Setting up your dotfiles..."
echo "[INFO] This script uses sudo for package installations."
echo "       You may be prompted for your password."
echo

DOTFILES_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
BASHRC_CUSTOM="$DOTFILES_DIR/.bashrc_custom"
BASHRC_CUSTOM_ESCAPED=$(printf '%q' "$BASHRC_CUSTOM")

# Detect package manager (used for lsd and make)
if command -v dnf &> /dev/null; then
    PKG_MANAGER="dnf"
    PKG_INSTALL="sudo dnf install -y"
elif command -v yum &> /dev/null; then
    PKG_MANAGER="yum"
    PKG_INSTALL="sudo yum install -y"
elif command -v apt &> /dev/null; then
    PKG_MANAGER="apt"
    PKG_INSTALL="sudo apt install -y"
elif command -v pacman &> /dev/null; then
    PKG_MANAGER="pacman"
    PKG_INSTALL="sudo pacman -S --noconfirm"
elif command -v zypper &> /dev/null; then
    PKG_MANAGER="zypper"
    PKG_INSTALL="sudo zypper install -y"
elif command -v apk &> /dev/null; then
    PKG_MANAGER="apk"
    PKG_INSTALL="sudo apk add"
else
    PKG_MANAGER=""
    PKG_INSTALL=""
fi

# ----------------------------------------------------------
# lsd
# ----------------------------------------------------------

if ! command -v lsd &> /dev/null; then
    echo "[INFO] Installing lsd..."
    if [ -n "$PKG_INSTALL" ]; then
        if [ "$PKG_MANAGER" = "apt" ]; then
            sudo apt update > /dev/null 2>&1
        fi
        $PKG_INSTALL lsd > /dev/null 2>&1
    fi
    if command -v lsd &> /dev/null; then
        echo "[OK] lsd installed."
    else
        echo "[WARN] Could not install lsd automatically."
        echo "       Install it manually from:"
        echo "         https://github.com/lsd-rs/lsd/releases"
    fi
fi

# ----------------------------------------------------------
# ble.sh — Bash Line Editor
# ----------------------------------------------------------

BLESH_DIR="$HOME/.local/share/blesh"

if ! [ -f "$BLESH_DIR/ble.sh" ]; then
    echo "[INFO] Installing ble.sh (Bash Line Editor)..."
    if command -v git &> /dev/null; then
        if ! command -v make &> /dev/null; then
            echo "[INFO] Installing make..."
            if [ -n "$PKG_INSTALL" ]; then
                $PKG_INSTALL make > /dev/null 2>&1
            fi
        fi
        if command -v make &> /dev/null; then
            echo "[INFO] Building ble.sh from GitHub..."
            git clone --recursive --depth 1 --shallow-submodules \
                https://github.com/akinomyoga/ble.sh.git /tmp/ble.sh \
                > /dev/null 2>&1
            if make -C /tmp/ble.sh install PREFIX="$HOME/.local" > /dev/null 2>&1; then
                rm -rf /tmp/ble.sh
                echo "[OK] ble.sh installed."
            else
                echo "[WARN] ble.sh installation failed."
                echo "       You can install it manually later from:"
                echo "         https://github.com/akinomyoga/ble.sh"
            fi
        else
            echo "[WARN] make is required to build ble.sh."
            echo "       Install it manually, then re-run this script."
        fi
    else
        echo "[WARN] git is required to install ble.sh."
        echo "       Install it manually, then re-run this script."
    fi
fi

# ----------------------------------------------------------
# starship prompt
# ----------------------------------------------------------

if ! command -v starship &> /dev/null; then
    echo "[INFO] Installing starship..."
    if command -v curl &> /dev/null; then
        if curl -sS https://starship.rs/install.sh | sudo sh -s -- -y > /dev/null 2>&1; then
            echo "[OK] starship installed."
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
            rm -f "$HOME/.config/lsd/config.yaml"
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
                rm -f "$HOME/.config/lsd/config.yaml"
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

TIMESTAMP=$(date +%Y%m%d-%H%M)

echo "[INFO] Setting up ~/.bashrc..."

if [ -f "$HOME/.bashrc" ]; then
    echo "[OK] Existing .bashrc found."
    # Create backup before any modifications
    cp "$HOME/.bashrc" "$HOME/.bashrc.backup.${TIMESTAMP}"
    echo "[OK] Backup created: $HOME/.bashrc.backup.${TIMESTAMP}"
else
    echo "[INFO] No existing .bashrc found."
    touch "$HOME/.bashrc"
    echo "[OK] Created new .bashrc."
fi

# Add ble.sh source if installed
if [ -f "$BLESH_DIR/ble.sh" ] && ! grep -Fq "blesh/ble.sh" "$HOME/.bashrc"; then
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

if grep -Fq "source ${BASHRC_CUSTOM_ESCAPED}" "$HOME/.bashrc"; then
    echo "[OK] Dotfiles are already configured."
else
    echo "[INFO] Adding dotfiles configuration..."
    {
        echo
        echo "# Load custom dotfiles configuration"
        echo "if [ -f ${BASHRC_CUSTOM_ESCAPED} ]; then"
        echo "    source ${BASHRC_CUSTOM_ESCAPED}"
        echo "fi"
    } >> "$HOME/.bashrc"
    echo "[OK] Configuration added."
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
if [ -f "$BLESH_DIR/ble.sh" ]; then
    echo "  ✅ ble.sh ready"
fi
if command -v starship &> /dev/null; then
    echo "  ✅ starship ready with pastel-powerline preset"
fi
echo
echo "To apply the changes, run: source ~/.bashrc"
echo "Or open a new terminal."
