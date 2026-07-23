#!/bin/bash

echo "========================================="
echo "         Dotfiles Setup"
echo "========================================="
echo

echo "[INFO] Setting up your dotfiles..."

# Create a timestamp for backups
TIMESTAMP=$(date +%Y%m%d-%H%M)

echo "[INFO] Checking for ~/.bashrc..."

if [ -f ~/.bashrc ]; then
    cp ~/.bashrc ~/.bashrc.backup.$TIMESTAMP
    echo "[OK] Backup created."
else
    echo "[INFO] No existing .bashrc found."
    touch "$HOME/.bashrc"
    echo "[OK] Created new .bashrc."
fi

echo
echo "[INFO] Checking if dotfiles are already configured..."

if grep -q 'source "$HOME/dotfiles/.bashrc_custom"' ~/.bashrc; then
    echo "[OK] Dotfiles are already configured."
else
    echo "[INFO] Adding dotfiles configuration..."

    cat <<'EOF' >> ~/.bashrc

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
