# Dotfiles

> A portable Linux configuration that allows me to quickly recreate my preferred shell environment on any system.

This repository contains my personal shell configuration, tools and workflows for Linux systems.
It evolves as I learn and tinker with Bash and Linux.

The goal is simple:

Instead of configuring every new Linux installation from scratch,
I want to rebuild my preferred working environment in just a few minutes.

## Features

- Custom shell configuration
- `lsd` aliases with icon configuration
- Git version control
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

Clone the repository:

```bash
git clone https://github.com/maldor0r/dotfiles
```

Run the installer from the cloned folder:

```bash
cd dotfiles
./install.sh
```

The repository does not have to be cloned directly into your home directory; the installer uses its own location.

The installer will:

- Create a backup of your existing `.bashrc`
- Create a new `.bashrc` if none exists
- Add the custom dotfiles configuration
- Point `.bashrc` to this cloned repository's `.bashrc_custom`
- Avoid adding duplicate configuration blocks
- Warn if `lsd` is not installed and offer to install
- Configure lsd icons (fancy, unicode, or none)

## Configuration

The repository includes pre-configured templates for `lsd` in `config/lsd/`:

- `config-fancy.yaml` — Nerd Font icons (default)
- `config-unicode.yaml` — Unicode icons (works on any terminal)
- `config-no-icons.yaml` — No icons

The installer copies the chosen template to `~/.config/lsd/config.yaml`.
You can re-run the installer or edit that file directly to change later.

## Roadmap

- [x] Custom Bash configuration
- [x] Initial `lsd` aliases
- [x] Installation script
- [ ] Git configuration
- [ ] Bash functions
- [ ] Additional shell improvements

---

> My home for every Linux machine.
