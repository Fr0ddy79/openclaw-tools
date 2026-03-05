#!/bin/bash
# OpenClaw Tools - Common Library
# Shared functions for all tools

set -euo pipefail

# Version
OCT_VERSION="1.0.0"

# Default paths
OCT_DIR="${OCT_DIR:-$HOME/.local/share/openclaw-tools}"
OCT_CONFIG_DIR="${OCT_CONFIG_DIR:-$HOME/.config/openclaw-tools}"
OCT_LOG_DIR="${OCT_LOG_DIR:-$OCT_CONFIG_DIR/logs}"
OCT_REPORT_DIR="${OCT_REPORT_DIR:-$OCT_CONFIG_DIR/reports}"

# Date/time
DATE=$(date +%Y-%m-%d)
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Ensure directories exist
ensure_dirs() {
    mkdir -p "$OCT_LOG_DIR" "$OCT_REPORT_DIR" "$OCT_CONFIG_DIR"
}

# Check dependencies
check_deps() {
    local missing=()
    for dep in "$@"; do
        if ! command -v "$dep" &> /dev/null; then
            missing+=("$dep")
        fi
    done
    
    if [ ${#missing[@]} -gt 0 ]; then
        echo -e "${RED}❌ Missing dependencies: ${missing[*]}${NC}" >&2
        return 1
    fi
}

# Log functions
log_info() { echo -e "${BLUE}ℹ️  $*${NC}"; }
log_success() { echo -e "${GREEN}✅ $*${NC}"; }
log_warn() { echo -e "${YELLOW}⚠️  $*${NC}" >&2; }
log_error() { echo -e "${RED}❌ $*${NC}" >&2; }

# Check if running in OpenClaw environment
is_openclaw_env() {
    [ -n "${OPENCLAW_HOME:-}" ] && [ -d "$OPENCLAW_HOME" ]
}

# Get system info
get_os_info() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        echo "$NAME $VERSION_ID"
    elif command -v sw_vers &> /dev/null; then
        sw_vers -productName
    else
        uname -s
    fi
}

# Check sudo availability (non-interactive)
has_sudo() {
    sudo -n true 2>/dev/null
}

# Create temp file with cleanup
temp_file() {
    local tmp
    tmp=$(mktemp "${TMPDIR:-/tmp}/oct-XXXXXX")
    trap "rm -f '$tmp'" EXIT
    echo "$tmp"
}

# Progress spinner
spinner() {
    local pid=$1
    local delay=0.1
    local spinstr='|/-\'
    while ps -p "$pid" > /dev/null 2>&1; do
        local temp=${spinstr#?}
        printf " [%c]  " "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b"
    done
    printf "    \b\b\b\b"
}

# Export functions for use in other scripts
export -f log_info log_success log_warn log_error
export -f check_deps ensure_dirs has_sudo
export OCT_VERSION OCT_DIR OCT_CONFIG_DIR OCT_LOG_DIR OCT_REPORT_DIR
export DATE TIMESTAMP
