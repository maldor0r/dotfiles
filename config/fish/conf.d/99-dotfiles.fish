# ==========================================================
# dotfiles - managed Fish integration
#
# Managed by install.sh - this file is safe to delete and is
# regenerated on every install run. The "99-" prefix ensures it
# is loaded last, so these definitions take precedence over any
# system/distro defaults (e.g. CachyOS ls/la/ll/lt functions).
#
# Provides:
#   - eza-based ls/la/ll/lla/lt/lta/llt/llta (same semantics as
#     the Bash/lsd aliases)
#   - Starship prompt via native fish init
#   - rich/plain terminal mode (Linux virtual TTYs)
#
# Fish has its own line editor - ble.sh stays Bash-only and is
# never loaded here.
# ==========================================================

# ----------------------------------------------------------
# Rich/Plain mode detection (mirrors the Bash implementation)
#   plain when DOTFILES_PLAIN is set, OR on a real Linux
#   virtual console (TERM=linux / /dev/ttyN).
# ----------------------------------------------------------

set -g __dotfiles_use_plain 0
if set -q DOTFILES_PLAIN
    set -g __dotfiles_use_plain 1
else if string match -q 'linux*' -- "$TERM"
    set -g __dotfiles_use_plain 1
else if command -q tty; and string match -q '/dev/tty*' -- (tty 2>/dev/null)
    set -g __dotfiles_use_plain 1
end

# Locate the plain Starship config: the installed copy next to
# the runtime dotfiles, falling back to the repo checkout.
set -g __dotfiles_plain_cfg "$HOME/.config/dotfiles/starship-plain.toml"
if not test -f "$__dotfiles_plain_cfg"
    set -l here (dirname (status filename))
    set -g __dotfiles_plain_cfg "$here/../../starship/starship-plain.toml"
end

# eza icons flag: "" (rich, default auto) or "--icons=never" (plain).
set -g _dotfiles_eza_icons ''
if test "$__dotfiles_use_plain" -eq 1
    set -g _dotfiles_eza_icons '--icons=never'
    set -gx STARSHIP_CONFIG "$__dotfiles_plain_cfg"
else
    set -eg STARSHIP_CONFIG
end

# ----------------------------------------------------------
# eza-based ls functions.
#   Override any existing definitions (e.g. CachyOS) so ours win.
#   Only defined when eza is available; otherwise the shell's
#   default ls is left untouched.
# ----------------------------------------------------------

if command -q eza
    functions -q ls;  and functions -e ls 2>/dev/null
    functions -q la;  and functions -e la 2>/dev/null
    functions -q ll;  and functions -e ll 2>/dev/null
    functions -q lla; and functions -e lla 2>/dev/null
    functions -q lt;  and functions -e lt 2>/dev/null
    functions -q lta; and functions -e lta 2>/dev/null
    functions -q llt; and functions -e llt 2>/dev/null
    functions -q llta; and functions -e llta 2>/dev/null

    function ls --wraps=eza
        eza $_dotfiles_eza_icons --group-directories-first $argv
    end
    function la --wraps=eza
        eza $_dotfiles_eza_icons -a --group-directories-first $argv
    end
    function ll --wraps=eza
        eza $_dotfiles_eza_icons -l --group-directories-first $argv
    end
    function lla --wraps=eza
        eza $_dotfiles_eza_icons -la --group-directories-first $argv
    end
    function lt --wraps=eza
        eza $_dotfiles_eza_icons --tree --level=3 --group-directories-first $argv
    end
    function lta --wraps=eza
        eza $_dotfiles_eza_icons -a --tree --level=3 --group-directories-first $argv
    end
    function llt --wraps=eza
        eza $_dotfiles_eza_icons -l --tree --level=3 --group-directories-first $argv
    end
    function llta --wraps=eza
        eza $_dotfiles_eza_icons -la --tree --level=3 --group-directories-first $argv
    end
end

# ----------------------------------------------------------
# Starship prompt (native Fish initialization).
# ----------------------------------------------------------

if command -q starship
    starship init fish | source
end

# ----------------------------------------------------------
# Toggles (current session only, take effect on next prompt)
# ----------------------------------------------------------

function dotfiles-plain
    set -gx DOTFILES_PLAIN 1
    set -g _dotfiles_eza_icons '--icons=never'
    set -gx STARSHIP_CONFIG "$__dotfiles_plain_cfg"
    command -q starship; and starship init fish | source
end

function dotfiles-rich
    set -eg DOTFILES_PLAIN
    set -g _dotfiles_eza_icons ''
    set -eg STARSHIP_CONFIG
    command -q starship; and starship init fish | source
end