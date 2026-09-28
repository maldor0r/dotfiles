# Dotfiles

> A portable shell configuration that allows me to quickly recreate
> my preferred environment on any system.

These are my personal dotfiles. They grow as I tinker,
and let me get my environment back up in minutes on any machine.

## Features

- Custom shell configuration for **Bash** and **Fish**
- Bash: `lsd` aliases + `ble.sh` line editor
- Fish: `eza` aliases + native line editing
- **starship** prompt with pastel-powerline preset
- **fastfetch** system-info banner on interactive shells
- Rich/plain mode for Linux virtual TTYs (no Nerd Font needed)
- Safe installation with automatic backups

## Installation

**Linux (Bash or Fish):**

```bash
git clone https://github.com/maldor0r/dotfiles && cd dotfiles && ./install.sh
```

The installer detects which shells you have and configures each one
(Bash wiring into `~/.bashrc`, Fish into `~/.config/fish/conf.d/`).

**Windows (PowerShell):**

```powershell
git clone https://github.com/maldor0r/dotfiles; cd dotfiles; .\install.ps1
```

The installer auto-installs missing tools, configures starship with the
pastel-powerline preset, and wires up your shell profile.

<details>
<summary>Installer options & details</summary>

**Linux options:**

```bash
./install.sh -y                # assume yes: auto-install optional build deps,
                               # pick the default icon style — no prompts
./install.sh --skip-blesh      # skip building/installing ble.sh
./install.sh --with-nerd-font  # install JetBrainsMono Nerd Font (Linux only)
./install.sh -h                # show help
```

Non-interactive runs (no TTY, e.g. CI) automatically use defaults for the
icon-style and `ble.sh` dependency prompts instead of blocking.

**Windows options:**

```powershell
.\install.ps1 -WithNerdFont                 # install JetBrainsMono Nerd Font on Windows
.\install.ps1 -Icons fancy                  # force lsd icons: fancy | unicode | none | auto
.\install.ps1 -Icons fancy -WithNerdFont    # install the font, then use fancy icons
```

**Nerd Fonts:** icon support needs a Nerd Font. On native Linux the installer
can install one for you (`--with-nerd-font`); under WSL a font must be
installed on the **Windows** side — installing it inside Linux is invisible to
the Windows terminal. The installer detects Nerd Fonts (including Windows-host
fonts, via `/mnt/c`) and picks the icon style automatically.

**How it works:** tools are installed into your own user directory
(`~/.local/bin`) so no admin/root access is required. This works even on fresh
WSL distros or cloud VMs where you don't have (or don't want to grant) sudo
rights. Downside: updates are manual — re-run the installer to fetch new
versions. `~/.local/bin` is added to your `$PATH` automatically.

**One optional sudo step:** installing `ble.sh` requires the `make` build
tool. If `make` is missing, the installer will ask whether to install it with
sudo — it will never use sudo without your consent.

</details>

<details open>
<summary><h2 style="display: inline">Aliases</h2></summary>

**Bash (`lsd`):** when `lsd` is installed, the following aliases are available:

| Alias | Command | Description |
|-------|---------|-------------|
| `ls` | `lsd --group-directories-first` | Basic listing, no hidden files |
| `la` | `lsd -a --group-directories-first` | Basic listing, with hidden files |
| `ll` | `lsd -l --group-directories-first` | Long listing, no hidden files |
| `lla` | `lsd -la --group-directories-first` | Long listing, with hidden files |
| `lt` | `lsd --tree --depth 3 --group-directories-first` | Tree view, no hidden files |
| `lta` | `lsd -a --tree --depth 3 --group-directories-first` | Tree view, with hidden files |
| `llt` | `lsd -l --tree --depth 3 --group-directories-first` | Tree + long, no hidden files |
| `llta` | `lsd -la --tree --depth 3 --group-directories-first` | Tree + long, with hidden files |

If `lsd` is not installed, basic fallback aliases are used for `ls`, `la`, `ll`, and `lla`.

**Fish (`eza`):** the same semantics are provided as Fish functions using `eza`
(replacing any distro/system defaults, e.g. CachyOS):

| Alias | Command | Description |
|-------|---------|-------------|
| `ls` | `eza --group-directories-first` | Basic listing, no hidden files |
| `la` | `eza -a --group-directories-first` | Basic listing, with hidden files |
| `ll` | `eza -l --group-directories-first` | Long listing, no hidden files |
| `lla` | `eza -la --group-directories-first` | Long listing, with hidden files |
| `lt` | `eza --tree --level=3 --group-directories-first` | Tree view, no hidden files |
| `lta` | `eza -a --tree --level=3 --group-directories-first` | Tree view, with hidden files |
| `llt` | `eza -l --tree --level=3 --group-directories-first` | Tree + long, no hidden files |
| `llta` | `eza -la --tree --level=3 --group-directories-first` | Tree + long, with hidden files |

If `eza` is not installed, Fish keeps its built-in `ls`.

**Safe file-operation defaults** (interactive shells only) to guard against
accidental overwrites and deletions — most useful while getting comfortable
with Linux. Bypass anytime with `\cp`, `\mv`, `\rm`, or `\ln`:

| Alias | Command | Description |
|-------|---------|-------------|
| `cp` | `cp -i` | Confirm before overwriting an existing file |
| `mv` | `mv -i` | Confirm before overwriting an existing file |
| `rm` | `rm -I` | Confirm once for 3+ files or any recursive delete |
| `ln` | `ln -i` | Confirm before unlinking/replacing a link |

These only affect interactive shells — scripts and the installer are untouched.

</details>

<details>
<summary><h2 style="display: inline">Configuration</h2></summary>

Pre-configured templates are in `config/`:

- `config/lsd/` — `config-fancy.yaml`, `config-unicode.yaml`, `config-no-icons.yaml`
- `config/starship/starship.toml` — pastel-powerline preset
- `config/fastfetch/config.jsonc` — pastel-powerline system-info banner

Copy the desired template to `~/.config/lsd/config.yaml`, `~/.config/starship.toml`
or `~/.config/fastfetch/config.jsonc`, or re-run the installer. Existing
`fastfetch` configs are **not** overwritten — only written on first install.

**Plain mode (Linux TTY):** On a raw virtual console (tty1/tty2/...) the Nerd
Font isn't available, so powerline glyphs and file icons can't render. The shell
config automatically switches to a no-Nerd-Font mode there:

- Starship uses `starship-plain.toml` (ASCII separators, no Nerd glyphs)
- Bash `lsd` disables icons (`--icon never`), Fish `eza` disables icons
  (`--icons=never`) — grouping, colors, long listings, hidden files, sorting, etc. remain

`~/.config/lsd/config.yaml`, `~/.config/starship.toml` and the Fish functions are
all configured at the shell level; nothing on disk is rewritten when switching.

Works the same in **Bash** and **Fish**:

- `dotfiles-plain` — switch the current shell to plain mode (Starship + no icons)
- `dotfiles-rich` — switch back to the rich Nerd Font prompt and icons
  (both take effect on the next press of Enter)
- `DOTFILES_PLAIN=1 bash` / `DOTFILES_PLAIN=1 fish` — force plain mode in any terminal

Note: Fish uses its own line editor — `ble.sh` is Bash-only and is never loaded
by Fish.

</details>

---

> My home for every machine.
