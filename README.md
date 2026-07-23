# Dotfiles

> A portable Linux configuration that allows me to quickly recreate my preferred shell environment on any system.

This repository contains my personal shell configuration, tools and workflows for Linux systems.
It is designed to evolve as I learn, experiment and refine my Linux workflow.

The goal is simple:

Instead of configuring every new Linux installation from scratch,
I want to rebuild my preferred working environment in just a few minutes.

## Features

- Custom shell configuration
- `lsd` aliases
- Git version control
- Safe installation with automatic backups

## Installation

Clone the repository:

```bash
git clone https://github.com/maldor0r/dotfiles
```

Run the installer:

```bash
~/dotfiles/install.sh
```

Or:

```bash
cd dotfiles
./install.sh
```

The installer will:

- Create a backup of your existing `.bashrc`
- Create a new `.bashrc` if none exists
- Add the custom dotfiles configuration
- Avoid adding duplicate configuration blocks

## Roadmap

- [x] Custom Bash configuration
- [x] Initial `lsd` aliases
- [x] Installation script
- [ ] Git configuration
- [ ] Bash functions
- [ ] Additional shell improvements

---

> My home for every Linux machine.
