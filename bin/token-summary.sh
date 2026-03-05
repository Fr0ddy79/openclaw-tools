#!/bin/bash
# oct-token-summary: Aggregate token reports across date ranges
# Usage: oct-token-summary [--week|--month|--all]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/common.sh"

check_deps jq && ensure_dirs

PERIOD="${1:---week}"

case "$PERIOD" in
    --week)
        DAYS=7
        TITLE="Last 7 Days Token Summary"
        ;;
    --month)
        DAYS=30
        TITLE="Last 30 Days Token Summary"
        ;;
    --all)
        DAYS=365
        TITLE="All-Time Token Summary"
        ;;
    *)
        echo "Usage: $0 [--week|--month|--all]"
        exit 1
        ;;
esac

echo "📊 $TITLE"
echo "========================="
echo ""

TOTAL_SESSIONS=0
TOTAL_INPUT=0
TOTAL_OUTPUT=0
DAY_COUNT=0

# Look through log files
for ((i=0; i<DAYS; i++)); do
    CHECK_DATE=$(date -d "$i days ago" +%Y-%m-%d 2>/dev/null || date -v-${i}d +%Y-%m-%d)
    LOG_FILE="$OCT_LOG_DIR/tokens-${CHECK_DATE}.md"
    
    if [ -f "$LOG_FILE" ]; then
        ((DAY_COUNT++))
        
        # Extract numbers from markdown
        DAY_INPUT=$(grep "Input Tokens:" "$LOG_FILE" | grep -oE '[0-9]+' || echo "0")
        DAY_OUTPUT=$(grep "Output Tokens:" "$LOG_FILE" | grep -oE '[0-9]+' || echo "0")
        DAY_SESSIONS=$(grep "Total Sessions:" "$LOG_FILE" | grep -oE '[0-9]+' || echo "0")
        
        TOTAL_INPUT=$((TOTAL_INPUT + DAY_INPUT))
        TOTAL_OUTPUT=$((TOTAL_OUTPUT + DAY_OUTPUT))
        TOTAL_SESSIONS=$((TOTAL_SESSIONS + DAY_SESSIONS))
        
        printf "%s: %s sessions, %s tokens\n" "$CHECK_DATE" "$DAY_SESSIONS" "$((DAY_INPUT + DAY_OUTPUT))"
    fi
done

TOTAL=$((TOTAL_INPUT + TOTAL_OUTPUT))

echo ""
echo "📈 Aggregate Summary"
echo "-------------------"
printf "Days Tracked:   %d\n" "$DAY_COUNT"
printf "Total Sessions: %d\n" "$TOTAL_SESSIONS"
printf "Input Tokens:   %d\n" "$TOTAL_INPUT"
printf "Output Tokens:  %d\n" "$TOTAL_OUTPUT"
echo "-------------------"
printf "TOTAL TOKENS:   %d\n" "$TOTAL"

if [ "$DAY_COUNT" -gt 0 ]; then
    AVG_PER_DAY=$((TOTAL / DAY_COUNT))
    printf "Average/Day:    %d\n" "$AVG_PER_DAY"
fi

# Cost estimate (rough)
AVG_COST_PER_1K=0.005  # Average across models
EST_COST=$(awk -v tokens="$TOTAL" -v price="$AVG_COST_PER_1K" 'BEGIN{printf "%.2f", (tokens/1000) * price}')
echo ""
echo "💰 Estimated Cost: \$$EST_COST (at ~$${AVG_COST_PER_1K}/1K tokens)"
