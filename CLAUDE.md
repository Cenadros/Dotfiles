# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Cross-platform dotfiles manager for macOS, Linux (Ubuntu/Debian, Fedora, Arch, openSUSE), and WSL2. The installer bootstraps a full development environment including Zsh/Prezto, Docker, Homebrew, NVM, mkcert, AI coding tools (Claude, Codex, OpenCode), and terminal/editor apps.

## Repository Structure

- `installer` — Remote bootstrap script (curl one-liner). Installs prerequisites (git, zsh, curl), clones the repo to `~/.dotfiles`, then delegates to `scripts/install`.
- `scripts/install` — Main installation orchestrator. Installs all tools in order: Homebrew, Docker, Prezto, NVM, build tools, mkcert, AI tools, terminals, editors, git config, and symlinks.
- `scripts/symlinks` — Creates symlinks from `~/` to `dotfiles/` directory files. The list of symlinked files is hardcoded in the `FILES_TO_SYMLINK` array.
- `scripts/update` — Pulls latest dotfiles, prezto, nvm, and runs brew upgrade + re-symlinks. Exposed to the user as the `dot_update` alias.
- `scripts/utils.bash` — Shared shell utilities: OS/arch detection (`get_os`, `get_arch`, `is_wsl`), cross-platform package helpers (`pkg_install`, `pkg_update`), portable `sed_i`, user prompts, spinners, and print helpers.
- `dotfiles/` — The actual dotfiles that get symlinked into `$HOME`:
  - `.zshrc` — Sources exports, aliases, prezto, and nvm
  - `.zpreztorc` — Prezto module config (Spaceship prompt theme)
  - `.exports` — Environment variables (NVM_DIR, PATH, XDG dirs)
  - `.aliases` — Git, Docker, Vagrant, and dotfiles aliases
  - `.zprofile` — Homebrew shellenv, editor/browser/pager defaults
  - `.gitconfig` — Placeholder email/name (replaced during install)
- `wsl.conf` — WSL2 configuration (copied to `/etc/wsl.conf` during install)

## Key Patterns

- **All scripts are Bash** (`#!/bin/bash` with `set -e`), except dotfiles which are Zsh (`#!/usr/bin/env zsh`).
- **OS branching uses `get_os()`** from `utils.bash`, returning: `macos`, `debian`, `fedora`, `arch`, `suse`, or `linux`. All new platform-specific code should follow the existing `case "$OS" in` pattern.
- **`DOTFILES_PATH`** is always `$HOME/.dotfiles` — the repo is cloned there during installation, not run from the development checkout.
- **Symlinks are the deployment mechanism** — `dotfiles/` files are symlinked to `$HOME`. To add a new dotfile, add the file to `dotfiles/` and append its relative path to the `FILES_TO_SYMLINK` array in `scripts/symlinks`.
- **`pkg_install`/`pkg_update`** in `utils.bash` abstract cross-platform package installation. Use these instead of calling apt/dnf/pacman directly.
- **`sed_i`** handles the GNU vs BSD sed difference — always use it instead of raw `sed -i`.

## Testing

There are no automated tests. Verify changes by running the relevant script on the target platform. The `installer` script can be tested end-to-end via:

```bash
bash installer                  # full bootstrap (clones to ~/.dotfiles)
bash scripts/install            # run install from local checkout
bash scripts/symlinks           # just re-create symlinks
bash scripts/update             # pull + upgrade dependencies
```
