#!/bin/bash
# OpenClaw Tools v1.0.0
# One-line installer: curl -fsSL https://get.openclaw.tools | bash

set -euo pipefail

VERSION="1.0.0"
INSTALL_DIR="${INSTALL_DIR:-$HOME/.local/share/openclaw-tools}"
BIN_DIR="${BIN_DIR:-$HOME/.local/bin}"
GITHUB_REPO="openclaw-tools"

echo "🔧 OpenClaw Tools Installer v$VERSION"
echo "=================================="

# Detect OS
OS=$(uname -s | tr '[:upper:]' '[:lower:]')
ARCH=$(uname -m)

case "$ARCH" in
    x86_64) ARCH="amd64" ;;
    aarch64|arm64) ARCH="arm64" ;;
esac

echo "📦 Detected: $OS/$ARCH"

# Check dependencies
check_dep() {
    if ! command -v "$1" &> /dev/null; then
        echo "❌ Required: $1"
        return 1
    fi
    echo "✓ $1 installed"
}

echo ""
echo "Checking dependencies..."
REQUIRED="bash curl jq"
for dep in $REQUIRED; do
    check_dep "$dep" || MISSING=1
done

if [ "${MISSING:-0}" = "1" ]; then
    echo ""
    echo "Please install missing dependencies and retry."
    exit 1
fi

# Create directories
echo ""
echo "📁 Creating directories..."
mkdir -p "$INSTALL_DIR"/{bin,lib,docs}
mkdir -p "$BIN_DIR"

# Download latest release
echo ""
echo "⬇️  Downloading OpenClaw Tools..."
DOWNLOAD_URL="https://github.com/fredbeddows/${GITHUB_REPO}/releases/download/v${VERSION}/openclaw-tools-v${VERSION}.tar.gz"

if curl -fsSL "$DOWNLOAD_URL" -o "/tmp/openclaw-tools.tar.gz"; then
    echo "✓ Download complete"
else
    echo "⚠️  Download failed, using local copy..."
    # Fallback for development
    cp -r "$(dirname "$0")"/* "$INSTALL_DIR/"
fi

# Extract
echo "📦 Extracting..."
tar -xzf "/tmp/openclaw-tools.tar.gz" -C "$INSTALL_DIR" --strip-components=1 2>/dev/null || true

# Create symlinks
echo ""
echo "🔗 Creating symlinks..."
for tool in "$INSTALL_DIR"/bin/*.sh; do
    if [ -f "$tool" ]; then
        name=$(basename "$tool" .sh)
        ln -sf "$tool" "$BIN_DIR/oct-$name"
        echo "  oct-$name → $tool"
    fi
done

# Add to PATH if needed
if [[ ":$PATH:" != *":$BIN_DIR:"* ]]; then
    echo ""
    echo "⚠️  $BIN_DIR is not in your PATH"
    echo "   Add this to your ~/.bashrc or ~/.zshrc:"
    echo "   export PATH=\"\$PATH:$BIN_DIR\""
fi

# Run first-time setup
echo ""
echo "🔧 Running first-time setup..."
"$INSTALL_DIR/bin/setup.sh" 2>/dev/null || true

echo ""
echo "✅ OpenClaw Tools v$VERSION installed successfully!"
echo ""
echo "Available commands:"
echo "  oct-security-audit     - Full security audit with pattern detection"
echo "  oct-security-fast      - Quick security health check"
echo "  oct-daily-audit        - Daily system optimization audit"
echo "  oct-monitor            - Real-time system monitor"
echo "  oct-cost-track         - API cost tracking"
echo "  oct-token-track        - Daily token usage tracking"
echo "  oct-token-summary      - Token usage summary reports"
echo "  oct-health-check       - Complete system health check"
echo ""
echo "Get started: oct-security-fast"
echo "Documentation: $INSTALL_DIR/docs/README.md"
