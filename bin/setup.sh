#!/bin/bash
# OpenClaw Tools Setup Script
# Run after installation

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Create config directories
CONFIG_DIR="${CONFIG_DIR:-$HOME/.config/openclaw-tools}"
LOG_DIR="$CONFIG_DIR/logs"
REPORT_DIR="$CONFIG_DIR/reports"

mkdir -p "$CONFIG_DIR" "$LOG_DIR" "$REPORT_DIR"

# Create default config if doesn't exist
CONFIG_FILE="$CONFIG_DIR/config.sh"
if [ ! -f "$CONFIG_FILE" ]; then
    cat > "$CONFIG_FILE" << 'EOF'
# OpenClaw Tools Configuration

# Directories
OCT_LOG_DIR="${OCT_LOG_DIR:-$HOME/.config/openclaw-tools/logs}"
OCT_REPORT_DIR="${OCT_REPORT_DIR:-$HOME/.config/openclaw-tools/reports}"

# Timezone
export TZ="${TZ:-America/Toronto}"

# Cost estimation (per 1K tokens)
OCT_COST_GPT4=0.03
OCT_COST_GPT35=0.0005
OCT_COST_CLAUDE3=0.003
EOF
fi

echo "✅ Setup complete!"
echo ""
echo "Config file: $CONFIG_FILE"
echo "Logs:        $LOG_DIR"
echo "Reports:     $REPORT_DIR"
