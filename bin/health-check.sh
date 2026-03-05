#!/bin/bash
# oct-health-check: Complete system health diagnostic
# Usage: oct-health-check [--verbose]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/common.sh"

check_deps jq && ensure_dirs

VERBOSE=false
[ "${1:-}" = "--verbose" ] && VERBOSE=true

ERRORS=0
WARNINGS=0

echo "🏥 OpenClaw System Health Check"
echo "==============================="
echo "Date: $TIMESTAMP"
echo ""

# 1. System Resources
echo "💾 Memory Check"
echo "---------------"
read -r TOTAL USED FREE <<< "$(free -m | awk '/^Mem:/{print $2, $3, $7}')"
PCT=$((USED * 100 / TOTAL))
printf "Usage: %d%% (%d MB / %d MB)\n" "$PCT" "$USED" "$TOTAL"

if [ "$PCT" -gt 95 ]; then
    log_error "CRITICAL: Memory usage critical (${PCT}%)"
    ((ERRORS++))
elif [ "$PCT" -gt 85 ]; then
    log_warn "WARNING: High memory usage (${PCT}%)"
    ((WARNINGS++))
else
    log_success "Memory OK (${PCT}%)"
fi
echo ""

# 2. Disk Space
echo "💿 Disk Check"
echo "-------------"
df -h / | tail -1 | while read -r fs size used avail pct mount; do
    PCT_NUM=$(echo "$pct" | tr -d '%')
    printf "Root: %s used (%s free)\n" "$pct" "$avail"
    
    if [ "$PCT_NUM" -gt 95 ]; then
        log_error "CRITICAL: Disk nearly full (${pct})"
        ((ERRORS++))
    elif [ "$PCT_NUM" -gt 85 ]; then
        log_warn "WARNING: Disk filling up (${pct})"
        ((WARNINGS++))
    else
        log_success "Disk OK (${pct})"
    fi
done
echo ""

# 3. Load Average
echo "⚡ CPU Load Check"
echo "----------------"
read -r LOAD1 LOAD5 LOAD15 <<< "$(cut -d' ' -f1-3 /proc/loadavg)"
CORES=$(nproc)
LOAD_PCT=$(awk -v l="$LOAD1" -v c="$CORES" 'BEGIN{printf "%.0f", (l/c)*100}')
printf "Load: %.2f (%d%% of %d cores)\n" "$LOAD1" "$LOAD_PCT" "$CORES"

if [ "${LOAD1%.*}" -ge "$CORES" ]; then
    log_warn "WARNING: High CPU load"
    ((WARNINGS++))
else
    log_success "Load OK"
fi
echo ""

# 4. Services
echo "🔧 Service Check"
echo "----------------"

# Check OpenClaw if installed
if command -v openclaw &>/dev/null; then
    if openclaw status &>/dev/null; then
        log_success "OpenClaw CLI: OK"
    else
        log_warn "OpenClaw CLI: Not responding"
        ((WARNINGS++))
    fi
else
    log_warn "OpenClaw CLI: Not installed"
fi

# Check Ollama
if pgrep -x "ollama" > /dev/null 2>&1; then
    if curl -s --max-time 2 http://localhost:11434/api/tags >/dev/null 2>&1; then
        log_success "Ollama: Running and responding"
    else
        log_warn "Ollama: Running but not responding"
        ((WARNINGS++))
    fi
else
    echo "Ollama: Not running (optional)"
fi
echo ""

# 5. Network
echo "🌐 Network Check"
echo "----------------"
if ping -c 1 -W 2 8.8.8.8 >/dev/null 2>&1; then
    log_success "Internet: Connected"
else
    log_warn "Internet: No connection"
    ((WARNINGS++))
fi
echo ""

# 6. Zombie Processes
echo "🧟 Process Check"
echo "----------------"
ZOMBIES=$(ps aux | awk '$8 ~ /^Z/ {print}' | wc -l)
if [ "$ZOMBIES" -gt 0 ]; then
    log_warn "WARNING: $ZOMBIES zombie process(es) detected"
    ((WARNINGS++))
else
    log_success "No zombie processes"
fi
echo ""

# Summary
echo "📋 Health Summary"
echo "-----------------"
if [ "$ERRORS" -gt 0 ]; then
    log_error "$ERRORS error(s), $WARNINGS warning(s) detected"
    echo "   Action required!"
    exit 2
elif [ "$WARNINGS" -gt 0 ]; then
    log_warn "$WARNINGS warning(s) detected"
    echo "   Review recommended"
    exit 1
else
    log_success "All systems healthy!"
    exit 0
fi
