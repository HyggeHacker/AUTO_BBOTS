#!/bin/bash
set -euo pipefail

PHASE=$1
CONFIG_FILE="configs/${PHASE}.yml"
OUTPUT_DIR="outputs/${PHASE}"
mkdir -p "$OUTPUT_DIR"

bbot -c "$CONFIG_FILE" -om json -o "$OUTPUT_DIR/output.json" 2>&1 | tee "$OUTPUT_DIR/scan.log"
