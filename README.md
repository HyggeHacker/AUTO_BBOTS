# BBot Engagement Framework

This structure provides a phased, durable, and query-ready setup for running BBot scans.

## Usage

1. Place your target configs in `configs/`
2. Run a phase using:
   ```bash
   ./scripts/run_phase.sh phase1_passive
   ```
3. Or run auto_run_phase.sh target.com
4. Results are saved in `outputs/`, per phase
5. Use Neo4j or SQLite/Datasette to explore results
