# OpenClaw Tools - Installation Guide

## Quick Install (Recommended)

```bash
curl -fsSL https://get.openclaw.tools | bash
```

## Manual Installation

### 1. Download the Release

```bash
wget https://github.com/fredbeddows/openclaw-tools/releases/download/v1.0.0/openclaw-tools-v1.0.0.tar.gz
tar -xzf openclaw-tools-v1.0.0.tar.gz
cd openclaw-tools
```

### 2. Run the Installer

```bash
./install.sh
```

Or with custom options:

```bash
INSTALL_DIR=/opt/openclaw-tools BIN_DIR=/usr/local/bin ./install.sh
```

### 3. Verify Installation

```bash
oct-security-fast
```

## Requirements

- **Operating System**: Linux, macOS, or WSL
- **Shell**: Bash 4.0 or later
- **Dependencies**: `curl`, `jq` (install via package manager)

### Installing Dependencies

**Ubuntu/Debian:**
```bash
sudo apt update
sudo apt install curl jq
```

**macOS:**
```bash
brew install curl jq
```

**Fedora/RHEL:**
```bash
sudo dnf install curl jq
```

## Post-Installation

### Add to PATH (if needed)

If `oct-*` commands are not found, add this to your `~/.bashrc` or `~/.zshrc`:

```bash
export PATH="$PATH:$HOME/.local/bin"
```

Then reload:
```bash
source ~/.bashrc  # or ~/.zshrc
```

### First Run

Run the setup script to create config directories:

```bash
oct-setup
```

### Test All Tools

```bash
# Quick security check
oct-security-fast

# Full system health
oct-health-check

# Daily audit with save
oct-daily-audit --save

# Start monitor
oct-monitor
```

## Updating

To update to the latest version:

```bash
curl -fsSL https://get.openclaw.tools | bash
```

## Uninstalling

```bash
rm -rf ~/.local/share/openclaw-tools
rm -f ~/.local/bin/oct-*
rm -rf ~/.config/openclaw-tools
```

## Troubleshooting

### Command not found
- Ensure `~/.local/bin` is in your PATH
- Try running with full path: `~/.local/bin/oct-security-fast`

### Permission denied
- Make sure scripts are executable: `chmod +x ~/.local/bin/oct-*`

### Missing dependencies
- Install `jq`: `sudo apt install jq` (Ubuntu/Debian)

### Reports not saving
- Check that `~/.config/openclaw-tools/reports` exists and is writable

## Configuration

Edit `~/.config/openclaw-tools/config.sh` to customize:

```bash
# Custom directories
OCT_LOG_DIR=/var/log/openclaw
OCT_REPORT_DIR=/var/reports/openclaw

# Timezone
export TZ="America/New_York"
```

## Support

- Issues: https://github.com/fredbeddows/openclaw-tools/issues
- Discussions: https://github.com/fredbeddows/openclaw-tools/discussions
