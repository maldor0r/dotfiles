# ==========================================================
# dotfiles - managed Fish integration
#
# Managed by install.sh - this file is safe to delete and is
# regenerated on every install run. Loaded as part of fish's
# conf.d startup.
#
# Responsibilities:
#   - rich/plain terminal mode detection (Linux virtual TTYs)
#   - _dotfiles_eza_icons global consumed by the eza functions
#   - Starship prompt via native fish init
#   - dotfiles-plain / dotfiles-rich session toggles
#
# The eza-based ls/la/ll/lla/lt/lta/llt/llta are autoloadable
# function files installed to ~/.config/fish/functions/.
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

# eza icons flag: "--icons=always" in rich mode, "--icons=never" in plain
# mode. Always set to one of the two so the eza functions (*.fish) explicitly
# enable or disable icons.
if test "$__dotfiles_use_plain" -eq 1
    set -g _dotfiles_eza_icons '--icons=never'
    set -gx STARSHIP_CONFIG "$__dotfiles_plain_cfg"
else
    set -g _dotfiles_eza_icons '--icons=always'
    set -eg STARSHIP_CONFIG
end

# eza-based ls/la/ll/lla/lt/lta/llt/llta are provided as autoloadable
# function files installed into the user functions dir
# (~/.config/fish/functions/), which is first in fish_function_path. That
# makes them override any system/distro autoloaded definitions (e.g. CachyOS
# ls.fish) - defining functions here in conf.d would NOT win against a
# system autoload file, since fish autoloads the file on first use and it
# replaces an in-memory definition.
#
# This file handles: rich/plain detection, the _dotfiles_eza_icons global,
# Starship init, and the dotfiles-plain / dotfiles-rich toggles.

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
    set -g _dotfiles_eza_icons '--icons=always'
    set -eg STARSHIP_CONFIG
    command -q starship; and starship init fish | source
end
