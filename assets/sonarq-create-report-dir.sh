#!/usr/bin/env bash
set -e
set -o pipefail

scan_path="${SCAN_PATH:-${INPUT_PATH:-}}"
if [ -z "$scan_path" ]; then
  scan_path="api"
fi

report_dir="${scan_path}/.sonarq"
echo "Creating report directory: $report_dir"
mkdir -p "$report_dir"
echo "Report directory created successfully"
ls -la "$scan_path"
