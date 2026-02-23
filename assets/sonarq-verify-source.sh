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
if [ ! -d "$scan_path/src" ]; then
  echo "WARNING: $scan_path/src does not exist, creating placeholder"
  mkdir -p "$scan_path/src"
  echo "// placeholder" > "$scan_path/src/placeholder.ts"
fi
echo "Directory contents:"
ls -la "$scan_path"
echo "Source files count:"
find "$scan_path/src" -type f -name "*.ts" 2>/dev/null | wc -l || echo "0"
