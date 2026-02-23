#!/usr/bin/env bash
set -e
set -o pipefail

script_dir=$(cd "$(dirname "$0")" && pwd)
repo_root=$(cd "$script_dir/.." && pwd)

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

passed=0
failed=0
results=()

run_scan() {
  local path="$1"
  local key="$2"
  local name="$3"

  echo ""
  echo -e "${YELLOW}========================================${NC}"
  echo -e "${YELLOW}  Scanning: $name ($path)${NC}"
  echo -e "${YELLOW}========================================${NC}"
  echo ""

  if bash "$repo_root/assets/run.sh" \
    --path "$path" \
    --project-key "$key" \
    --project-name "$name"; then

    report_dir="$repo_root/$path/.sonarq"
    if [ -f "$report_dir/REPORT.md" ] && [ -f "$report_dir/quality-gate.json" ]; then
      qg=$(grep -oP '"status"\s*:\s*"\K[^"]+' "$report_dir/quality-gate.json" 2>/dev/null | head -1 || echo "UNKNOWN")
      bugs=$(grep -oP '"metric"\s*:\s*"bugs"[^}]*"value"\s*:\s*"\K[^"]+' "$report_dir/metrics.json" 2>/dev/null | head -1 || echo "?")
      vulns=$(grep -oP '"metric"\s*:\s*"vulnerabilities"[^}]*"value"\s*:\s*"\K[^"]+' "$report_dir/metrics.json" 2>/dev/null | head -1 || echo "?")
      smells=$(grep -oP '"metric"\s*:\s*"code_smells"[^}]*"value"\s*:\s*"\K[^"]+' "$report_dir/metrics.json" 2>/dev/null | head -1 || echo "?")
      hotspots=$(grep -oP '"metric"\s*:\s*"security_hotspots"[^}]*"value"\s*:\s*"\K[^"]+' "$report_dir/metrics.json" 2>/dev/null | head -1 || echo "?")

      echo ""
      echo -e "${GREEN}[PASS]${NC} $name - QG=$qg bugs=$bugs vulns=$vulns smells=$smells hotspots=$hotspots"
      results+=("PASS|$name|$qg|$bugs|$vulns|$smells|$hotspots")
      passed=$((passed + 1))
    else
      echo -e "${RED}[FAIL]${NC} $name - report files missing"
      results+=("FAIL|$name|N/A|N/A|N/A|N/A|N/A")
      failed=$((failed + 1))
    fi
  else
    echo -e "${RED}[FAIL]${NC} $name - scan failed"
    results+=("FAIL|$name|N/A|N/A|N/A|N/A|N/A")
    failed=$((failed + 1))
  fi
}

echo "========================================"
echo "  ops-sonarq E2E Test Suite"
echo "========================================"

run_scan ".tests/api" "e2e-api" "E2E API"
run_scan ".tests/react" "e2e-react" "E2E React"

echo ""
echo "========================================"
echo "  E2E Results Summary"
echo "========================================"
echo ""
printf "%-6s | %-15s | %-4s | %-4s | %-5s | %-6s | %-8s\n" "Status" "Project" "QG" "Bugs" "Vulns" "Smells" "Hotspots"
printf "%-6s-+-%-15s-+-%-4s-+-%-4s-+-%-5s-+-%-6s-+-%-8s\n" "------" "---------------" "----" "----" "-----" "------" "--------"
for r in "${results[@]}"; do
  IFS='|' read -r status name qg bugs vulns smells hotspots <<< "$r"
  printf "%-6s | %-15s | %-4s | %-4s | %-5s | %-6s | %-8s\n" "$status" "$name" "$qg" "$bugs" "$vulns" "$smells" "$hotspots"
done
echo ""
echo "Passed: $passed  Failed: $failed  Total: $((passed + failed))"

if [ "$failed" -gt 0 ]; then
  echo -e "${RED}Some scans failed!${NC}"
  exit 1
fi
echo -e "${GREEN}All scans passed!${NC}"
