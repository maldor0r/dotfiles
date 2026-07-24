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
