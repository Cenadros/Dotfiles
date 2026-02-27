# Dotfiles

Cross-platform dotfiles for **macOS**, **Linux** (Ubuntu/Debian, Fedora, Arch, openSUSE) and **WSL2**.

## What's included

- **Zsh** with [Prezto](https://github.com/sorin-ionescu/prezto) + Spaceship prompt
- **Docker** — on macOS you can choose between [OrbStack](https://orbstack.dev) and Docker Desktop
- **Homebrew** — works on macOS (Intel & Apple Silicon) and Linux
- **NVM** (Node Version Manager)
- **mkcert** for local HTTPS certificates
- Git aliases, Docker aliases, and more

## Installation

### One-liner

```bash
bash <(curl -s https://raw.githubusercontent.com/Cenadros/Dotfiles/main/installer)
```

### Manual

```bash
git clone --depth 1 https://github.com/Cenadros/Dotfiles.git ~/.dotfiles
bash ~/.dotfiles/scripts/install
```

## Updating

Once installed you'll have the alias `dot_update` which updates dotfiles and all dependencies:

```bash
dot_update
```

## Supported platforms

| Platform | Package manager | Notes |
|----------|----------------|-------|
| macOS (Apple Silicon) | Homebrew | OrbStack / Docker Desktop |
| macOS (Intel) | Homebrew | OrbStack / Docker Desktop |
| Ubuntu / Debian | apt | Docker CE from official repo |
| Fedora / RHEL | dnf | Docker CE from official repo |
| Arch / Manjaro | pacman | Docker from community repo |
| openSUSE | zypper | Docker from distro repo |
| WSL2 | (same as distro) | Includes `wsl.conf` setup |
