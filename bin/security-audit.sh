#!/bin/bash
# oct-security-audit: Enhanced security audit with pattern detection
# Usage: oct-security-audit [--full]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/common.sh"

check_deps jq && ensure_dirs

FULL_MODE=false
[ "${1:-}" = "--full" ] && FULL_MODE=true

HAS_SUDO=false
has_sudo && HAS_SUDO=true

REPORT_FILE="$OCT_REPORT_DIR/security-audit-${DATE}.md"
LOG_FILE=$(temp_file)

echo "🔒 OpenClaw Security Audit — $TIMESTAMP" > "$LOG_FILE"
[ "$HAS_SUDO" = false ] && echo "⚠️  Note: Some checks require sudo" >> "$LOG_FILE"
echo "" >> "$LOG_FILE"

# 1. SSH Brute Force Detection
echo "📊 SSH Brute Force Detection" >> "$LOG_FILE"
echo "=============================" >> "$LOG_FILE"

FAILED_IPS=""
if [ -r /var/log/auth.log ]; then
    FAILED_IPS=$(grep "Failed password" /var/log/auth.log 2>/dev/null | \
        grep -oE 'from [0-9.]+' | sed 's/from //' | sort | uniq -c | sort -rn | head -5 || echo "")
fi

if [ "$HAS_SUDO" = true ] && [ -z "$FAILED_IPS" ]; then
    FAILED_IPS=$(sudo grep "Failed password" /var/log/auth.log 2>/dev/null | \
        grep -oE 'from [0-9.]+' | sed 's/from //' | sort | uniq -c | sort -rn | head -5 || echo "")
fi

if [ -n "$FAILED_IPS" ]; then
    echo "Failed attempts by IP:" >> "$LOG_FILE"
    echo "$FAILED_IPS" >> "$LOG_FILE"
    
    ATTACKERS=$(echo "$FAILED_IPS" | awk '$1 >= 5 {print $2}')
    if [ -n "$ATTACKERS" ]; then
        echo "" >> "$LOG_FILE"
        echo "🚨 Potential brute force attacks detected:" >> "$LOG_FILE"
        echo "$ATTACKERS" | while read -r ip; do
            echo "   - $ip (5+ failed attempts)" >> "$LOG_FILE"
        done
    fi
else
    echo "✅ No failed SSH attempts found" >> "$LOG_FILE"
fi

echo "" >> "$LOG_FILE"

# 2. Failed Sudo Attempts
echo "🔐 Failed Sudo Attempts" >> "$LOG_FILE"
echo "=======================" >> "$LOG_FILE"

if [ "$HAS_SUDO" = true ]; then
    SUDO_FAILS=$(sudo grep "sudo:.*authentication failure" /var/log/auth.log 2>/dev/null | tail -10 || echo "")
    if [ -n "$SUDO_FAILS" ]; then
        echo "Recent sudo failures:" >> "$LOG_FILE"
        echo "$SUDO_FAILS" | tail -5 >> "$LOG_FILE"
    else
        echo "✅ No recent sudo failures" >> "$LOG_FILE"
    fi
else
    echo "⚠️  Sudo check skipped (no passwordless sudo)" >> "$LOG_FILE"
fi

echo "" >> "$LOG_FILE"

# 3. Suspicious Processes
echo "🔍 Suspicious Processes" >> "$LOG_FILE"
echo "=======================" >> "$LOG_FILE"

SUSPICIOUS=$(ps aux | grep -E '(nc -l|ncat -l|python.*http.server|ruby.*-run)' | grep -v grep || echo "")
if [ -n "$SUSPICIOUS" ]; then
    echo "⚠️  Suspicious listening processes:" >> "$LOG_FILE"
    echo "$SUSPICIOUS" >> "$LOG_FILE"
else
    echo "✅ No suspicious processes found" >> "$LOG_FILE"
fi

echo "" >> "$LOG_FILE"

# 4. Listening Ports
echo "🌐 Listening Ports" >> "$LOG_FILE"
echo "==================" >> "$LOG_FILE"

if command -v ss &> /dev/null; then
    ss -tlnp 2>/dev/null | head -20 >> "$LOG_FILE" || echo "Could not retrieve port info" >> "$LOG_FILE"
elif command -v netstat &> /dev/null; then
    netstat -tlnp 2>/dev/null | head -20 >> "$LOG_FILE" || echo "Could not retrieve port info" >> "$LOG_FILE"
fi

echo "" >> "$LOG_FILE"

# 5. Recent Package Installations
echo "📦 Recent Package Activity" >> "$LOG_FILE"
echo "==========================" >> "$LOG_FILE"

if [ -f /var/log/dpkg.log ]; then
    tail -10 /var/log/dpkg.log 2>/dev/null | grep "install " >> "$LOG_FILE" || echo "No recent installs" >> "$LOG_FILE"
elif command -v rpm &> /dev/null; then
    rpm -qa --last 2>/dev/null | head -10 >> "$LOG_FILE" || echo "No rpm info available" >> "$LOG_FILE"
else
    echo "Package manager not detected" >> "$LOG_FILE"
fi

echo "" >> "$LOG_FILE"

# 6. Cron Jobs Audit
echo "⏰ Cron Jobs" >> "$LOG_FILE"
echo "============" >> "$LOG_FILE"

echo "User cron jobs:" >> "$LOG_FILE"
crontab -l 2>/dev/null >> "$LOG_FILE" || echo "No user crontab" >> "$LOG_FILE"

if [ "$HAS_SUDO" = true ]; then
    echo "" >> "$LOG_FILE"
    echo "System cron jobs:" >> "$LOG_FILE"
    sudo find /etc/cron* -type f -exec echo "=== {} ===" \; -exec cat {} \; 2>/dev/null | head -50 >> "$LOG_FILE" || true
fi

echo "" >> "$LOG_FILE"
echo "---" >> "$LOG_FILE"
echo "Report generated: $TIMESTAMP" >> "$LOG_FILE"
echo "OpenClaw Tools v$OCT_VERSION" >> "$LOG_FILE"

# Save and display
cp "$LOG_FILE" "$REPORT_FILE"
cat "$LOG_FILE"
echo ""
log_info "Report saved: $REPORT_FILE"
