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
    echo "       Or on Debian/Ubuntu:"
    echo "         sudo apt install lsd"
    echo ""
    read -rp "       Install lsd now? (y/N): " INSTALL_LSD
    if [[ "$INSTALL_LSD" =~ ^[Yy]$ ]]; then
        if command -v apt &> /dev/null; then
            echo "[INFO] Installing lsd via apt..."
            echo "       You may be prompted for your sudo password."
            if sudo apt update && sudo apt install -y lsd; then
                echo "[OK] lsd installed."
            else
                echo "[WARN] lsd installation failed. Please install lsd manually."
            fi
        else
            echo "[WARN] Could not detect apt. Please install lsd manually."
        fi
    fi
    echo
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

TIMESTAMP=$(date +%Y%m%d-%H%M)
BASHRC_EXISTED=false

echo "[INFO] Checking for ~/.bashrc..."

if [ -f "$HOME/.bashrc" ]; then
    BASHRC_EXISTED=true
    echo "[OK] Existing .bashrc found."
else
    echo "[INFO] No existing .bashrc found."
    touch "$HOME/.bashrc"
    echo "[OK] Created new .bashrc."
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
echo "[SUCCESS] Installation complete!"
echo
echo "To apply the changes, run 'source ~/.bashrc' or restart your terminal."
