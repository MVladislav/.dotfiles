#!/usr/bin/env bash
#
# gsettings Tracker Script
#
# This script captures a snapshot of your current gsettings values,
# waits for you to make UI changes, captures a new snapshot,
# and then compares the two states.
#
# Requirements: gsettings, diff, bash
#
# Usage:
#   ./gsettings_tracker.sh [--help]
#
# Options:
#   -h, --help    Show this help message and exit

set -euo pipefail

# Check for required commands
for cmd in gsettings diff date; do
  command -v "$cmd" >/dev/null 2>&1 || {
    echo "Error: '$cmd' is not installed. Exiting."
    exit 1
  }
done

# Default output directory
OUTPUT_DIR="gsettings_states"
mkdir -p "$OUTPUT_DIR"

# Timestamp for unique file names
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BEFORE_FILE="${OUTPUT_DIR}/gsettings_before_${TIMESTAMP}.txt"
AFTER_FILE="${OUTPUT_DIR}/gsettings_after_${TIMESTAMP}.txt"
DIFF_FILE="${OUTPUT_DIR}/gsettings_changes_${TIMESTAMP}.diff"

# Logging function
log() {
  echo "[ $(date +'%Y-%m-%d %H:%M:%S') ] $*"
}

# Usage function
usage() {
  echo "Usage: $0 [--help]"
  echo "This script captures the current gsettings values before and after UI changes and compares them."
}

if [[ ${1:-} == "--help" || ${1:-} == "-h" ]]; then
  usage
  exit 0
fi

# Function to capture current gsettings values
capture_gsettings() {
  # List all schemas in sorted order for consistency
  gsettings list-schemas | sort | while read -r schema; do
    echo "Schema: $schema"
    # List keys for the schema (sorted) and print their values
    gsettings list-keys "$schema" | sort | while read -r key; do
      value=$(gsettings get "$schema" "$key" 2>/dev/null || echo "Error retrieving key")
      echo "$schema $key: $value"
    done
  done
}

# Capture the initial state
log "Capturing initial gsettings state..."
capture_gsettings >"$BEFORE_FILE"
log "Initial state saved to: $BEFORE_FILE"

echo "Make your UI changes now..."
read -rp "Press ENTER after you've made changes..."

# Capture the changed state
log "Capturing changed gsettings state..."
capture_gsettings >"$AFTER_FILE"
log "Changed state saved to: $AFTER_FILE"

# Compare the two states
log "Comparing the two states..."
# diff returns non-zero if differences are found so we use || true to avoid exit on diff
diff --color=auto -u "$BEFORE_FILE" "$AFTER_FILE" >"$DIFF_FILE" || true

if [[ -s "$DIFF_FILE" ]]; then
  log "Differences detected. Diff file saved to: $DIFF_FILE"
  echo "Differences found. You can view the changes with: cat $DIFF_FILE"
else
  log "No differences detected between the states."
fi

exit 0
