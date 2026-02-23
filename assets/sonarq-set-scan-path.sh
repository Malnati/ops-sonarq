#!/usr/bin/env bash
set -e
set -o pipefail

scan_path="${INPUT_PATH:-}"
if [ -z "$scan_path" ]; then
  scan_path="api"
fi

echo "scan_path=$scan_path" >> "$GITHUB_OUTPUT"
echo "SCAN_PATH=$scan_path" >> "$GITHUB_ENV"
echo "Scan path configured: $scan_path"
