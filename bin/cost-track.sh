#!/bin/bash
# oct-cost-track: API cost tracking by model/provider
# Usage: oct-cost-track [--today|--week|--month]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/common.sh"

# Pricing per 1K tokens (approximate, update as needed)
declare -A PRICES=(
    ["gpt-4"]=0.03
    ["gpt-4-turbo"]=0.01
    ["gpt-3.5-turbo"]=0.0005
    ["claude-3-opus"]=0.015
    ["claude-3-sonnet"]=0.003
    ["claude-3-haiku"]=0.00025
    ["llama2"]=0.0
    ["mistral"]=0.0
    ["default"]=0.001
)

PERIOD="${1:---today}"

# Calculate date range
case "$PERIOD" in
    --today)
        START_DATE="$DATE"
        END_DATE="$DATE"
        TITLE="Today's API Costs"
        ;;
    --week)
        START_DATE=$(date -d '7 days ago' +%Y-%m-%d 2>/dev/null || date -v-7d +%Y-%m-%d)
        END_DATE="$DATE"
        TITLE="Last 7 Days API Costs"
        ;;
    --month)
        START_DATE=$(date -d '30 days ago' +%Y-%m-%d 2>/dev/null || date -v-30d +%Y-%m-%d)
        END_DATE="$DATE"
        TITLE="Last 30 Days API Costs"
        ;;
    *)
        echo "Usage: $0 [--today|--week|--month]"
        exit 1
        ;;
esac

echo "💰 $TITLE"
echo "======================"
echo ""

# Try to get data from OpenClaw if available
if command -v openclaw &>/dev/null; then
    log_info "Fetching session data from OpenClaw..."
    
    SESSIONS=$(openclaw sessions --json 2>/dev/null || echo '{"sessions":[]}')
    
    # Process by model
    echo "$SESSIONS" | jq -r '
        .sessions 
        | group_by(.model) 
        | map({
            model: .[0].model,
            provider: .[0].modelProvider,
            sessions: length,
            input: (map(.inputTokens // 0) | add),
            output: (map(.outputTokens // 0) | add)
        })
        | .[] 
        | "\(.model)|\(.provider)|\(.sessions)|\(.input)|\(.output)"
    ' 2>/dev/null | while IFS='|' read -r model provider sessions input output; do
        [ -z "$model" ] && continue
        
        total_tokens=$((input + output))
        
        # Estimate cost
        model_key=$(echo "$model" | sed 's/gpt-4-.*/gpt-4/; s/claude-3-.*/claude-3/')
        price_per_1k="${PRICES[$model_key]:-${PRICES[default]}}"
        estimated_cost=$(awk -v tokens="$total_tokens" -v price="$price_per_1k" 'BEGIN{printf "%.4f", (tokens/1000) * price}')
        
        echo "Model:     $model"
        echo "Provider:  $provider"
        echo "Sessions:  $sessions"
        echo "Tokens:    $total_tokens (in: $input, out: $output)"
        echo "Est. Cost: \$$estimated_cost"
        echo "---"
    done
    
    # Totals
    TOTAL_INPUT=$(echo "$SESSIONS" | jq '[.sessions[].inputTokens // 0] | add // 0')
    TOTAL_OUTPUT=$(echo "$SESSIONS" | jq '[.sessions[].outputTokens // 0] | add // 0')
    TOTAL=$((TOTAL_INPUT + TOTAL_OUTPUT))
    
    echo ""
    echo "📊 TOTALS"
    echo "---------"
    echo "Total Tokens: $TOTAL"
    echo "Total Sessions: $(echo "$SESSIONS" | jq '.sessions | length')"
    
else
    log_warn "OpenClaw CLI not available - showing estimates only"
    echo "Install OpenClaw for accurate cost tracking"
fi

# System resource costs (very rough estimate)
echo ""
echo "🖥️  System Resource Usage"
echo "------------------------"
UPTIME_HOURS=$(awk '{print int($1/3600)}' /proc/uptime)
# Rough estimate: $0.05/hour for a typical cloud instance
SYS_COST=$(awk -v hrs="$UPTIME_HOURS" 'BEGIN{printf "%.2f", hrs * 0.05}')
echo "System uptime: $UPTIME_HOURS hours"
echo "Est. compute: ~\$$SYS_COST"
