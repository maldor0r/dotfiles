#!/bin/bash

echo "========================================="
echo "         Dotfiles Setup"
echo "========================================="
echo

echo "[INFO] Setting up your dotfiles..."

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

# shellcheck disable=SC2016
if grep -q 'source "$HOME/dotfiles/.bashrc_custom"' "$HOME/.bashrc"; then
    echo "[OK] Dotfiles are already configured."
else
    echo "[INFO] Adding dotfiles configuration..."

    if [ "$BASHRC_EXISTED" = true ]; then
        cp "$HOME/.bashrc" "$HOME/.bashrc.backup.${TIMESTAMP}"
        echo "[OK] Backup created: $HOME/.bashrc.backup.${TIMESTAMP}"
    fi

    cat <<'EOF' >> "$HOME/.bashrc"

# Load custom dotfiles configuration
if [ -f "$HOME/dotfiles/.bashrc_custom" ]; then
    source "$HOME/dotfiles/.bashrc_custom"
fi
EOF

    echo "[OK] Configuration added."
fi

echo
echo "[SUCCESS] Installation complete!"
echo
echo "To apply the changes, run 'source ~/.bashrc' or restart your terminal."
