#!/usr/bin/env bash
set -e
set -o pipefail

scan_path="${SCAN_PATH:-${INPUT_PATH:-}}"
if [ -z "$scan_path" ]; then
  scan_path="api"
fi

echo "Checking source directory: $scan_path"
if [ ! -d "$scan_path" ]; then
  echo "ERROR: Directory $scan_path does not exist"
  exit 1
fi

echo "Directory contents:"
ls -la "$scan_path"
echo "Source files count:"
source_count=$(find "$scan_path" \
  \( -path "$scan_path/node_modules" -o -path "$scan_path/.sonarq" -o -path "$scan_path/.scannerwork" -o -path "$scan_path/dist" -o -path "$scan_path/build" -o -path "$scan_path/coverage" \) -prune -false \
  -o -type f \( -name "*.ts" -o -name "*.tsx" -o -name "*.js" -o -name "*.jsx" \) -print \
  | wc -l)
echo "$source_count"
if [ "$source_count" -eq 0 ]; then
  echo "ERROR: No source files found under $scan_path"
  exit 1
fi
