#!/bin/bash
set -euo pipefail

# === Config ===
TARGET=${1:?Usage: $0 <target-domain>}
ROOT_DIR="$(dirname "$(pwd)")"
CONFIG_DIR="$ROOT_DIR/configs"
OUTPUT_DIR="$ROOT_DIR/outputs"
LOG_DIR="$OUTPUT_DIR/logs"
PHASES=(phase1_passive phase2_cloud phase3_active phase4_credentials phase5_validation)
SLEEP_BETWEEN_PHASES=300  # 5 minutes (adjustable)

mkdir -p "$LOG_DIR"

log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_DIR/master.log"
}

# === Start Neo4j (if not already running or stuck) ===
setup_neo4j() {
    CONTAINER_NAME="bbot-neo4j"

    # Check if ports are already in use
    if lsof -i :7474 -sTCP:LISTEN -t >/dev/null || lsof -i :7687 -sTCP:LISTEN -t >/dev/null; then
        log "❌ Ports 7474 or 7687 already in use. Possibly another Neo4j instance is running. Aborting Neo4j startup."
        return 1
    fi

    # If container exists and is running
    if docker ps --filter "name=$CONTAINER_NAME" --filter "status=running" | grep -q "$CONTAINER_NAME"; then
        log "✅ Neo4j container '$CONTAINER_NAME' is already running."
        return 0
    fi

    # If container exists but is exited
    if docker ps -a --filter "name=$CONTAINER_NAME" | grep -q "$CONTAINER_NAME"; then
        log " Restarting existing Neo4j container '$CONTAINER_NAME'..."
        docker start "$CONTAINER_NAME"
    else
        log " Starting new Neo4j container '$CONTAINER_NAME'..."
        docker run -d \
          --name "$CONTAINER_NAME" \
          -p 7474:7474 -p 7687:7687 \
          -v "$ROOT_DIR/neo4j/data:/data" \
          -e NEO4J_AUTH=neo4j/bbotislife \
          -e 'NEO4JLABS_PLUGINS=["apoc"]' \
          -e 'NEO4J_dbms_security_procedures_unrestricted=apoc.*' \
          -e 'NEO4J_apoc_import_file_enabled=true' \
          neo4j
    fi

    # Wait and verify Neo4j has started properly
    log "⏳ Waiting for Neo4j to become ready..."
    sleep 20
    if ! docker logs "$CONTAINER_NAME" 2>&1 | grep -q "Remote interface available at"; then
        log "❌ Neo4j failed to start correctly. Check logs with: docker logs $CONTAINER_NAME"
        exit 1
    fi

    log "✅ Neo4j is ready."
}
# === Run a phase ===
run_phase() {
    local phase=$1
    local config="$CONFIG_DIR/${phase}.yml"
    local output="$OUTPUT_DIR/$phase"
    local logfile="$LOG_DIR/${phase}.log"

    log ">> Starting $phase"
    mkdir -p "$output"
    bbot -c "$config" -om json -o "$output/output.json" 2>&1 | tee "$logfile"
    log ">> Completed $phase"
}

# === Summary generation ===
create_summary() {
    log "Creating summary..."
    echo "# BBot Summary Report" > "$OUTPUT_DIR/SUMMARY.md"
    echo "- Target: $TARGET" >> "$OUTPUT_DIR/SUMMARY.md"
    echo "- Date: $(date)" >> "$OUTPUT_DIR/SUMMARY.md"
    echo "" >> "$OUTPUT_DIR/SUMMARY.md"

    for phase in "${PHASES[@]}"; do
        echo "## $phase Results" >> "$OUTPUT_DIR/SUMMARY.md"
        grep -o '"type": *"[^"]*"' "$OUTPUT_DIR/$phase/output.json" | sort | uniq -c >> "$OUTPUT_DIR/SUMMARY.md" || echo "No data" >> "$OUTPUT_DIR/SUMMARY.md"
        echo "" >> "$OUTPUT_DIR/SUMMARY.md"
    done

    log "Summary created at $OUTPUT_DIR/SUMMARY.md"
}

# === Main Execution ===
log "Starting BBot automated multi-phase run for $TARGET"
setup_neo4j

for phase in "${PHASES[@]}"; do
    run_phase "$phase"
    log "Sleeping $((SLEEP_BETWEEN_PHASES / 60)) min before next phase..."
    sleep "$SLEEP_BETWEEN_PHASES"
done

create_summary
log "BBot recon complete ✅"
