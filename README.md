# Dotfiles

> A portable shell configuration that allows me to quickly recreate
> my preferred environment on any system.

These are my personal dotfiles. They grow as I tinker,
and let me get my environment back up in minutes on any machine.

## Features

- Custom shell configuration
- `lsd` aliases with icon configuration
- `ble.sh` (Bash Line Editor) with syntax highlighting and autocomplete
- **starship** prompt with pastel-powerline preset
- Safe installation with automatic backups

<details>
<summary><h2 style="display: inline">Aliases</h2></summary>

When `lsd` is installed, the following aliases are available after installation:

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

</details>

## Installation

**Linux (Bash):**

```bash
git clone https://github.com/maldor0r/dotfiles && cd dotfiles && ./install.sh
```

**Windows (PowerShell):**

```powershell
git clone https://github.com/maldor0r/dotfiles; cd dotfiles; .\install.ps1
```

The installer auto-installs missing tools, configures starship with the
pastel-powerline preset, and wires up your shell profile — **all without
`sudo`**.

**Installer options (Linux):**

```bash
./install.sh -y                # assume yes: auto-install optional build deps,
                               # pick the default icon style — no prompts
./install.sh --skip-blesh      # skip building/installing ble.sh
./install.sh --with-nerd-font  # install JetBrainsMono Nerd Font (Linux only)
./install.sh -h                # show help
```

Non-interactive runs (no TTY, e.g. CI) automatically use defaults for the
icon-style and `ble.sh` dependency prompts instead of blocking.

**Windows (PowerShell) Nerd Font / icons:**

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

> **How it works:** tools are installed into your own user directory
> (`~/.local/bin`) so no admin/root access is required. This works even
> on fresh WSL distros or cloud VMs where you don't have (or don't want
> to grant) sudo rights. Downside: updates are manual — re-run the
> installer to fetch new versions. `~/.local/bin` is added to your
> `$PATH` automatically.
>
> **One optional sudo step:** installing `ble.sh` requires the `make`
> build tool. If `make` is missing, the installer will ask whether to
> install it with sudo — it will never use sudo without your consent.

## Configuration

Pre-configured templates are in `config/`:

- `config/lsd/` — `config-fancy.yaml`, `config-unicode.yaml`, `config-no-icons.yaml`
- `config/starship/starship.toml` — pastel-powerline preset

Copy the desired template to `~/.config/lsd/config.yaml` or `~/.config/starship.toml`,
or re-run the installer.

## Roadmap

- [x] Custom Bash configuration
- [x] Initial `lsd` aliases
- [x] Installation script
- [x] `ble.sh` integration
- [x] starship prompt
- [ ] Git configuration
- [ ] Bash functions
- [ ] Additional shell improvements

---

> My home for every machine.