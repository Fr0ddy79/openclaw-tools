#!/bin/bash
# oct-monitor: Real-time system monitor
# Usage: oct-monitor [--once]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/common.sh"

ONCE=false
[ "${1:-}" = "--once" ] && ONCE=true

get_cpu_usage() {
    local cpu_line
    cpu_line=$(grep '^cpu ' /proc/stat)
    local user nice system idle iowait irq softirq
    read -r _ user nice system idle iowait irq softirq _ <<< "$cpu_line"
    local total=$((user + nice + system + idle + iowait + irq + softirq))
    local used=$((total - idle))
    echo "$((used * 100 / total))"
}

get_mem_usage() {
    free | awk '/^Mem:/{printf "%.0f", $3/$2 * 100}'
}

get_load() {
    cut -d' ' -f1 /proc/loadavg
}

get_net_stats() {
    local interface="${1:-eth0}"
    [ ! -d "/sys/class/net/$interface" ] && interface=$(ls /sys/class/net/ | grep -v lo | head -1)
    
    local rx tx
    rx=$(cat "/sys/class/net/$interface/statistics/rx_bytes" 2>/dev/null || echo "0")
    tx=$(cat "/sys/class/net/$interface/statistics/tx_bytes" 2>/dev/null || echo "0")
    printf "%s %s" "$rx" "$tx"
}

print_monitor() {
    clear
    echo "╔══════════════════════════════════════════════════════╗"
    echo "║         🔍 OpenClaw System Monitor                   ║"
    echo "╠══════════════════════════════════════════════════════╣"
    
    # CPU
    local cpu=$(get_cpu_usage)
    local cpu_bar=""
    local cpu_color="$GREEN"
    [ "$cpu" -gt 70 ] && cpu_color="$YELLOW"
    [ "$cpu" -gt 90 ] && cpu_color="$RED"
    
    for ((i=0; i<cpu/5; i++)); do cpu_bar+="█"; done
    for ((i=cpu/5; i<20; i++)); do cpu_bar+="░"; done
    printf "║ CPU:  %s%-3d%%${NC} %s                    ║\n" "$cpu_color" "$cpu" "$cpu_bar"
    
    # Memory
    local mem=$(get_mem_usage)
    local mem_bar=""
    local mem_color="$GREEN"
    [ "$mem" -gt 70 ] && mem_color="$YELLOW"
    [ "$mem" -gt 90 ] && mem_color="$RED"
    
    for ((i=0; i<mem/5; i++)); do mem_bar+="█"; done
    for ((i=mem/5; i<20; i++)); do mem_bar+="░"; done
    printf "║ MEM:  %s%-3d%%${NC} %s                    ║\n" "$mem_color" "$mem" "$mem_bar"
    
    # Load
    local load=$(get_load)
    local cores=$(nproc)
    printf "║ LOAD: %.2f (cores: %d)                          ║\n" "$load" "$cores"
    
    echo "╠══════════════════════════════════════════════════════╣"
    
    # Disk
    echo "║ 💿 DISK:                                             ║"
    df -h | grep -E '^/dev' | while read -r fs size used avail pct mount; do
        printf "║   %-10s %5s used of %-6s (%s)        ║\n" "$mount" "$used" "$size" "$pct"
    done
    
    echo "╠══════════════════════════════════════════════════════╣"
    
    # Top processes
    echo "║ 🔧 TOP PROCESSES (CPU):                              ║"
    ps aux --sort=-%cpu | head -6 | tail -5 | awk '{
            cmd=$11
            gsub(/\/.*\//, "", cmd)
            printf "║   %-10s %5s%% %-20s      ║\n", $1, $3, cmd
        }'
    
    echo "╠══════════════════════════════════════════════════════╣"
    echo "║ Press Ctrl+C to exit  |  $(date '+%Y-%m-%d %H:%M:%S')           ║"
    echo "╚══════════════════════════════════════════════════════╝"
}

if [ "$ONCE" = true ]; then
    print_monitor
else
    trap 'echo -e "\n\n👋 Monitor stopped"; exit 0' INT
    while true; do
        print_monitor
        sleep 2
    done
fi
