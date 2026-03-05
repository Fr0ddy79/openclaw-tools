#!/bin/bash
# oct-security-fast: Quick 30-second security health check
# Usage: oct-security-fast

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/common.sh"

log_info "Running fast security check..."
echo ""

WARNINGS=0
ERRORS=0

# 1. SSH Service Check
if systemctl is-active sshd &>/dev/null || systemctl is-active ssh &>/dev/null; then
    SSH_STATUS="${GREEN}running${NC}"
    # Check if root login is allowed
    if [ -f /etc/ssh/sshd_config ]; then
        if grep -q "^PermitRootLogin yes" /etc/ssh/sshd_config 2>/dev/null; then
            SSH_STATUS="${YELLOW}running (root login enabled)${NC}"
            ((WARNINGS++))
        fi
    fi
else
    SSH_STATUS="${GREEN}not running${NC} (local only)"
fi

# 2. Firewall Status
if command -v ufw &>/dev/null; then
    if ufw status | grep -q "Status: active"; then
        FW_STATUS="${GREEN}active${NC} (ufw)"
    else
        FW_STATUS="${YELLOW}inactive${NC} (ufw)"
        ((WARNINGS++))
    fi
elif command -v firewall-cmd &>/dev/null; then
    if firewall-cmd --state 2>/dev/null | grep -q "running"; then
        FW_STATUS="${GREEN}active${NC} (firewalld)"
    else
        FW_STATUS="${YELLOW}inactive${NC} (firewalld)"
        ((WARNINGS++))
    fi
else
    FW_STATUS="${YELLOW}unknown${NC}"
fi

# 3. Failed Logins (last hour)
FAILED_COUNT=0
if [ -r /var/log/auth.log ]; then
    FAILED_COUNT=$(grep "$(date '+%b %e %H')" /var/log/auth.log 2>/dev/null | \
        grep -c "Failed password" || echo "0")
fi

if [ "$FAILED_COUNT" -gt 10 ]; then
    LOGIN_STATUS="${RED}$FAILED_COUNT failed attempts${NC}"
    ((ERRORS++))
elif [ "$FAILED_COUNT" -gt 0 ]; then
    LOGIN_STATUS="${YELLOW}$FAILED_COUNT failed attempts${NC}"
    ((WARNINGS++))
else
    LOGIN_STATUS="${GREEN}none${NC}"
fi

# 4. Disk Usage
DISK_USAGE=$(df -h / | awk 'NR==2 {print $5}' | sed 's/%//')
if [ "$DISK_USAGE" -gt 90 ]; then
    DISK_STATUS="${RED}${DISK_USAGE}%${NC}"
    ((ERRORS++))
elif [ "$DISK_USAGE" -gt 80 ]; then
    DISK_STATUS="${YELLOW}${DISK_USAGE}%${NC}"
    ((WARNINGS++))
else
    DISK_STATUS="${GREEN}${DISK_USAGE}%${NC}"
fi

# 5. Updates Available
UPDATES=0
if command -v apt &>/dev/null; then
    UPDATES=$(apt list --upgradable 2>/dev/null | grep -c "upgradable" || echo "0")
elif command -v dnf &>/dev/null; then
    UPDATES=$(dnf check-update 2>/dev/null | grep -c "\." || echo "0")
fi

if [ "$UPDATES" -gt 50 ]; then
    UPDATE_STATUS="${RED}$UPDATES available${NC}"
    ((WARNINGS++))
elif [ "$UPDATES" -gt 0 ]; then
    UPDATE_STATUS="${YELLOW}$UPDATES available${NC}"
else
    UPDATE_STATUS="${GREEN}up to date${NC}"
fi

# Output
echo "┌─────────────────────────────────────┐"
echo "│     🔒 Security Health Check        │"
echo "├─────────────────────────────────────┤"
printf "│ SSH Service:    %-20s│\n" "$SSH_STATUS"
printf "│ Firewall:       %-20s│\n" "$FW_STATUS"
printf "│ Failed Logins:  %-20s│\n" "$LOGIN_STATUS"
printf "│ Disk Usage:     %-20s│\n" "$DISK_STATUS"
printf "│ Updates:        %-20s│\n" "$UPDATE_STATUS"
echo "└─────────────────────────────────────┘"
echo ""

if [ "$ERRORS" -gt 0 ]; then
    log_error "$ERRORS critical issue(s) detected"
    exit 1
elif [ "$WARNINGS" -gt 0 ]; then
    log_warn "$WARNINGS warning(s) - review recommended"
    exit 0
else
    log_success "All checks passed!"
    exit 0
fi
