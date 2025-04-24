#!/bin/bash
set -euo pipefail

PHASE="$1"
OUTPUT_DIR="$(dirname "$(pwd)")/outputs"
ALERT_DIR="$OUTPUT_DIR/alerts/$PHASE"
PHASE_JSON="$OUTPUT_DIR/$PHASE/output.json"

mkdir -p "$ALERT_DIR"

for KEYWORD in CRITICAL LEAK VULNERABILITY TAKEOVER; do
    OUT_JSON="$ALERT_DIR/${KEYWORD,,}.json"
    OUT_MD="$ALERT_DIR/${KEYWORD,,}.md"

    grep -i "\"$KEYWORD\"" "$PHASE_JSON" > "$OUT_JSON" || echo "No $KEYWORD entries found."
    
    jq -r "select(.type==\"$KEYWORD\") | \"- \(.source // \"unknown\") → \(.target // \"unknown\")\"" "$PHASE_JSON" > "$OUT_MD" 2>/dev/null || echo "No structured $KEYWORD entries found."
done
