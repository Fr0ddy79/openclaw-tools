#!/bin/bash
# oct-daily-audit: Daily system optimization audit
# Usage: oct-daily-audit [--save]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/common.sh"

check_deps jq && ensure_dirs

SAVE_REPORT=false
[ "${1:-}" = "--save" ] && SAVE_REPORT=true

REPORT_FILE="$OCT_REPORT_DIR/daily-audit-${DATE}.md"

echo "📊 Daily System Audit — $TIMESTAMP"
echo "================================"
echo ""

# System Info
echo "🖥️  System Information"
echo "----------------------"
printf "OS:        %s\n" "$(get_os_info)"
printf "Hostname:  %s\n" "$(hostname)"
printf "Uptime:    %s\n" "$(uptime -p 2>/dev/null || uptime | awk -F',' '{print $1}')"
echo ""

# Memory
echo "💾 Memory Usage"
echo "---------------"
read -r TOTAL_RAM USED_RAM FREE_RAM <<< "$(free -m | awk '/^Mem:/{print $2, $3, $7}')"
RAM_PCT=$((USED_RAM * 100 / TOTAL_RAM))

printf "Total:     %s MB\n" "$TOTAL_RAM"
printf "Used:      %s MB (%s%%)\n" "$USED_RAM" "$RAM_PCT"
printf "Free:      %s MB\n" "$FREE_RAM"

if [ "$RAM_PCT" -gt 90 ]; then
    echo -e "${RED}⚠️  CRITICAL: High memory usage${NC}"
elif [ "$RAM_PCT" -gt 75 ]; then
    echo -e "${YELLOW}⚠️  Warning: Elevated memory usage${NC}"
fi
echo ""

# Disk Usage
echo "💿 Disk Usage"
echo "-------------"
df -h / | awk 'NR==2 {printf "Root:  %s used of %s (%s free)\n", $3, $2, $4}'
echo ""

# Ollama Status
echo "🤖 Ollama / Local AI"
echo "-------------------"
if pgrep -x "ollama" > /dev/null 2>&1; then
    echo -e "Status:    ${GREEN}running${NC}"
    MODELS=$(curl -s --max-time 2 http://localhost:11434/api/tags 2>/dev/null | \
        jq -r '.models | map(.name) | join(", ")' 2>/dev/null || echo "N/A")
    printf "Models:    %s\n" "$MODELS"
else
    echo -e "Status:    ${YELLOW}not running${NC}"
fi
echo ""

# Load Average
echo "⚡ Load Average"
echo "---------------"
read -r LOAD1 LOAD5 LOAD15 <<< "$(cut -d' ' -f1-3 /proc/loadavg)"
CORES=$(nproc)
printf "1 min:     %.2f (%s cores)\n" "$LOAD1" "$CORES"
printf "5 min:     %.2f\n" "$LOAD5"
printf "15 min:    %.2f\n" "$LOAD15"
echo ""

# Processes
echo "🔧 Top Processes (by CPU)"
echo "-------------------------"
ps aux --sort=-%cpu | head -6 | tail -5 | awk '{printf "%-10s %5s%% %s\n", $1, $3, $11}'
echo ""

# Network Connections
echo "🌐 Network Connections"
echo "----------------------"
if command -v ss &>/dev/null; then
    printf "Established: %s\n" "$(ss -s | grep estab | awk '{print $2}')"
    printf "Listening:   %s\n" "$(ss -lnt | wc -l)"
else
    printf "Connections: %s\n" "$(netstat -an 2>/dev/null | grep ESTABLISHED | wc -l)"
fi
echo ""

# Summary
echo "📋 Summary"
echo "----------"
if [ "$RAM_PCT" -lt 75 ] && [ "$LOAD1" -lt "$CORES" ]; then
    echo -e "${GREEN}✅ System healthy${NC}"
else
    echo -e "${YELLOW}⚠️  Attention needed${NC}"
fi
echo ""

# Save report if requested
if [ "$SAVE_REPORT" = true ]; then
    {
        echo "# Daily System Audit — $DATE"
        echo ""
        echo "Generated: $TIMESTAMP"
        echo ""
        echo "## System Info"
        echo "- OS: $(get_os_info)"
        echo "- Hostname: $(hostname)"
        echo "- Uptime: $(uptime -p 2>/dev/null || uptime | awk -F',' '{print $1}')"
        echo ""
        echo "## Memory"
        echo "- Total: ${TOTAL_RAM}MB"
        echo "- Used: ${USED_RAM}MB (${RAM_PCT}%)"
        echo "- Free: ${FREE_RAM}MB"
        echo ""
        echo "## Disk"
        df -h / | awk 'NR==2 {print "- Used: " $3 " of " $2 " (" $5 ")"}'
        echo ""
        echo "## Recommendations"
        if [ "$RAM_PCT" -gt 75 ]; then
            echo "- Consider freeing memory or adding RAM"
        fi
        if [ "$LOAD1" > "$CORES" ]; then
            echo "- High CPU load detected - check running processes"
        fi
    } > "$REPORT_FILE"
    log_success "Report saved: $REPORT_FILE"
fi
