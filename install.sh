#!/bin/bash

echo "========================================="
echo "         Dotfiles Setup"
echo "========================================="
echo

echo "[INFO] Setting up your dotfiles..."

DOTFILES_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
BASHRC_CUSTOM="$DOTFILES_DIR/.bashrc_custom"
BASHRC_CUSTOM_ESCAPED=$(printf '%q' "$BASHRC_CUSTOM")

# ----------------------------------------------------------
# Check prerequisites
# ----------------------------------------------------------

if ! command -v lsd &> /dev/null; then
    echo "[WARN] 'lsd' is not installed."
    echo "       The custom aliases require lsd for the full experience."
    echo "       Without it, basic ls fallbacks will be used."
    echo ""
    echo "       Install lsd manually from:"
    echo "         https://github.com/lsd-rs/lsd/releases"
    echo ""

    # Detect package manager
    if command -v dnf &> /dev/null; then
        PKG_MANAGER="dnf"
        PKG_CMD="sudo dnf install lsd"
    elif command -v yum &> /dev/null; then
        PKG_MANAGER="yum"
        PKG_CMD="sudo yum install lsd"
    elif command -v apt &> /dev/null; then
        PKG_MANAGER="apt"
        PKG_CMD="sudo apt install lsd"
    else
        PKG_MANAGER=""
        PKG_CMD=""
    fi

    if [ -n "$PKG_MANAGER" ]; then
        echo "       Or install via $PKG_MANAGER:"
        echo "         $PKG_CMD"
    fi
    echo ""
    read -rp "       Install lsd now? (y/N): " INSTALL_LSD
    if [[ "$INSTALL_LSD" =~ ^[Yy]$ ]]; then
        if [ -n "$PKG_MANAGER" ]; then
            echo "[INFO] Installing lsd via $PKG_MANAGER..."
            echo "       You may be prompted for your sudo password."
            if [ "$PKG_MANAGER" = "apt" ]; then
                sudo apt update > /dev/null 2>&1 && sudo apt install -y lsd > /dev/null 2>&1
            else
                sudo $PKG_MANAGER install -y lsd > /dev/null 2>&1
            fi
            if command -v lsd &> /dev/null; then
                echo "[OK] lsd installed."
            else
                echo "[WARN] lsd installation failed."
                echo "       You can install it manually later from:"
                echo "         https://github.com/lsd-rs/lsd/releases"
            fi
        else
            echo "[WARN] Could not detect a package manager."
            echo "       Please install lsd manually from:"
            echo "         https://github.com/lsd-rs/lsd/releases"
        fi
    fi
fi

# ----------------------------------------------------------
# Configure lsd icons
# ----------------------------------------------------------

if command -v lsd &> /dev/null; then
    echo
    echo "[INFO] Configuring lsd icons..."

    # Try to auto-detect Nerd Fonts (look for "Nerd" or "NF" in font names)
    # If detection fails, fonts may be on host system (e.g. WSL)
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
        echo "       Nerd Font: detected ✓"
        echo "         1) Fancy icons (requires Nerd Font)  [default]"
        DEFAULT_CHOICE=1
    else
        echo "       Nerd Font: not detected"
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
# ble.sh — Bash Line Editor
# ----------------------------------------------------------

BLESH_DIR="$HOME/.local/share/blesh"

if ! [ -f "$BLESH_DIR/ble.sh" ]; then
    echo "[INFO] ble.sh (Bash Line Editor) is not installed."
    echo "       It adds syntax highlighting, autocomplete, and more."
    echo ""
    read -rp "       Install ble.sh now? (y/N): " INSTALL_BLESH
    if [[ "$INSTALL_BLESH" =~ ^[Yy]$ ]]; then
        if command -v git &> /dev/null; then
            # Ensure make is available for building ble.sh
            if ! command -v make &> /dev/null; then
                echo "[INFO] 'make' is needed to build ble.sh."
                read -rp "       Install make now? (y/N): " INSTALL_MAKE
                if [[ "$INSTALL_MAKE" =~ ^[Yy]$ ]]; then
                    if command -v dnf &> /dev/null; then
                        sudo dnf install -y make > /dev/null 2>&1
                    elif command -v yum &> /dev/null; then
                        sudo yum install -y make > /dev/null 2>&1
                    elif command -v apt &> /dev/null; then
                        sudo apt install -y make > /dev/null 2>&1
                    fi
                fi
            fi

            if command -v make &> /dev/null; then
                echo "[INFO] Installing ble.sh from GitHub..."
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
                echo "[WARN] make is required to install ble.sh."
                echo "       Install it manually, then re-run this script."
            fi
        else
            echo "[WARN] git is required to install ble.sh."
        fi
    fi
fi

# ----------------------------------------------------------
# Shell setup
# ----------------------------------------------------------

if ! command -v lsd &> /dev/null; then
    echo
    echo "[INFO] lsd not available — using basic ls aliases."
    echo "       Install lsd later and re-run this script to enable icons."
fi

TIMESTAMP=$(date +%Y%m%d-%H%M)
BASHRC_EXISTED=false

echo
echo "[INFO] Setting up ~/.bashrc..."

if [ -f "$HOME/.bashrc" ]; then
    BASHRC_EXISTED=true
    echo "[OK] Existing .bashrc found."
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

    if [ "$BASHRC_EXISTED" = true ]; then
        cp "$HOME/.bashrc" "$HOME/.bashrc.backup.${TIMESTAMP}"
        echo "[OK] Backup created: $HOME/.bashrc.backup.${TIMESTAMP}"
    fi

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
    echo "  ✅ lsd ready with your icon settings"
else
    echo "  ⚠️  lsd not installed — using basic ls aliases"
fi
if [ -f "$BLESH_DIR/ble.sh" ]; then
    echo "  ✅ ble.sh ready"
fi
echo
echo "To apply the changes, run: source ~/.bashrc"
echo "Or open a new terminal."
