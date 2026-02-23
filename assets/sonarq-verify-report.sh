#!/usr/bin/env bash
set -e
set -o pipefail

scan_path="${SCAN_PATH:-${INPUT_PATH:-}}"
if [ -z "$scan_path" ]; then
  scan_path="api"
fi
report_dir="${scan_path}/.sonarq"

echo "Verifying report files in: $report_dir"
if [ ! -d "$report_dir" ]; then
  echo "ERROR: Report directory does not exist"
  exit 1
fi
echo "Report directory contents:"
ls -la "$report_dir"
if [ ! -f "$report_dir/REPORT.md" ]; then
  echo "ERROR: REPORT.md was not generated"
  exit 1
fi
echo "REPORT.md exists and contains:"
wc -l "$report_dir/REPORT.md"
echo "All report files verified successfully"
