# AGENTS.md

Personal dotfiles repo (Linux/macOS Bash + Windows PowerShell). No build system, no tests, no linter config — the root files ARE the deliverable. `install.sh`/`install.ps1` install, configure, and wire up the shell on a fresh machine.

## Entrypoints
- `install.sh` — Linux/Bash installer (main deliverable). Idempotent-ish: backs up `~/.bashrc` (timestamped) before editing; only appends a `source .bashrc_custom` block if not already present.
- `install.ps1` — Windows/PowerShell installer.
- `.bashrc_custom` — user-local shell config sourced from `~/.bashrc` (PATH, lsd aliases, starship).
- `config/` — templates copied verbatim: `config/lsd/config-{fancy,unicode,no-icons}.yaml`, `config/starship/starship.toml`.

## Key gotchas
- **No sudo by design (Linux only).** `install.sh` installs `lsd`/`starship`/`ble.sh` into `~/.local/bin` (added to PATH). The single optional sudo step is installing `make` for ble.sh and it always prompts first — never auto-sudo. Do not reintroduce package-manager or `curl | sudo sh` installs.
- **Linux ≠ Windows install model.** `install.ps1` still uses `winget` (system-wide), NOT user-local, and does NOT do the no-sudo/`make`-prompt logic. Do not assume parity — the two installers intentionally differ in how they fetch tools.
- **Alias symmetry:** the 8 lsd aliases (`ls/la/ll/lla/lt/lta/llt/llta`) live as `alias` in `.bashrc_custom` and as `function` definitions in `install.ps1`'s profile block. Changing the set means updating both files plus the README alias table. `install.sh` itself defines no aliases — it only wires `.bashrc` → `.bashrc_custom`.
- `install.sh` edits `~/.bashrc` (not `.bash_profile`), appending a guarded `source <escaped abs path to .bashrc_custom>`.
- `.bashrc_custom` has `if command -v lsd` fallback aliases (plain `ls`) so `ls`-family never breaks when lsd is absent.
- **Verification:** no tests exist. Check with `bash -n install.sh`. For behavior, run it against a throwaway fake `HOME` (`HOME=/tmp/dottest ./install.sh`) — never run it against the real home in a session. Real-world smoke test uses a fresh cloud VM/WSL.

## README parity
Keep the README "Aliases" table and the feature/roadmap checklists in sync with actual installer behavior. README and installers are the only surfaces a user sees; a claim in the README that isn't in the code is a bug.
