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
sonarqube_started=0

cleanup() {
  if [ "$sonarqube_started" -eq 1 ]; then
    docker rm -f ops-sonarq-sonarqube >/dev/null 2>&1 || true
  fi
}
trap cleanup EXIT

ensure_sonarqube() {
  if curl -fsS "http://localhost:9000/api/system/status" >/dev/null 2>&1; then
    return 0
  fi

  if ! command -v docker >/dev/null 2>&1; then
    echo -e "${RED}ERROR:${NC} SonarQube is not running on http://localhost:9000 and docker is not available."
    echo "Start SonarQube manually or install docker, then rerun the tests."
    exit 1
  fi

  if docker ps --format '{{.Names}}' | grep -q '^ops-sonarq-sonarqube$'; then
    return 0
  fi

  docker rm -f ops-sonarq-sonarqube >/dev/null 2>&1 || true
  docker run -d --name ops-sonarq-sonarqube \
    -p 9000:9000 \
    -e SONAR_ES_BOOTSTRAP_CHECKS_DISABLE=true \
    sonarqube:lts-community >/dev/null
  sonarqube_started=1
}

run_scan() {
  local path="$1"
  local key="$2"
  local name="$3"
  local scanner_debug_flag=""

  echo ""
  echo -e "${YELLOW}========================================${NC}"
  echo -e "${YELLOW}  Scanning: $name ($path)${NC}"
  echo -e "${YELLOW}========================================${NC}"
  echo ""

  if [ "${SCANNER_DEBUG:-false}" = "true" ]; then
    scanner_debug_flag="--scanner-debug"
  fi

  if bash "$repo_root/assets/run.sh" \
    --path "$path" \
    --project-key "$key" \
    --project-name "$name" \
    $scanner_debug_flag; then

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

run_workflow_cli() {
  local workflow_name="Workflow test.yml"
  local act_dir="/tmp/act-bin"

  echo ""
  echo -e "${YELLOW}========================================${NC}"
  echo -e "${YELLOW}  Running: $workflow_name${NC}"
  echo -e "${YELLOW}========================================${NC}"
  echo ""

  if [ -x "$act_dir/act" ]; then
    export PATH="$act_dir:$PATH"
  fi

  if ! command -v act &>/dev/null; then
    echo "act not installed, attempting install..."
    act_version="${ACT_VERSION:-latest}"
    mkdir -p "$act_dir"
    if curl -fsSL "https://raw.githubusercontent.com/nektos/act/master/install.sh" | bash -s -- -b "$act_dir" "$act_version"; then
      export PATH="$act_dir:$PATH"
    fi
    if ! command -v act &>/dev/null; then
      echo -e "${RED}[FAIL]${NC} $workflow_name - act not installed"
      results+=("FAIL|$workflow_name|N/A|N/A|N/A|N/A|N/A")
      failed=$((failed + 1))
      return
    fi
    act --version || true
  fi

  rm -rf "$repo_root/.tests/api/.sonarq" "$repo_root/.tests/react/.sonarq"

  if ! act -W "$repo_root/.github/workflows/test.yml" workflow_dispatch \
    --bind \
    --env SONAR_HOST_URL=http://localhost:9000 \
    -P ubuntu-latest=ghcr.io/catthehacker/ubuntu:act-latest; then
    echo -e "${RED}[FAIL]${NC} $workflow_name - workflow failed"
    results+=("FAIL|$workflow_name|N/A|N/A|N/A|N/A|N/A")
    failed=$((failed + 1))
    return
  fi

  local ok=1
  local report_dir=""
  local qg=""
  local bugs=""
  local vulns=""
  local smells=""
  local hotspots=""

  report_dir="$repo_root/.tests/api/.sonarq"
  if [ -f "$report_dir/REPORT.md" ] && [ -f "$report_dir/quality-gate.json" ]; then
    qg=$(grep -oP '"status"\s*:\s*"\K[^"]+' "$report_dir/quality-gate.json" 2>/dev/null | head -1 || echo "UNKNOWN")
    bugs=$(grep -oP '"metric"\s*:\s*"bugs"[^}]*"value"\s*:\s*"\K[^"]+' "$report_dir/metrics.json" 2>/dev/null | head -1 || echo "?")
    vulns=$(grep -oP '"metric"\s*:\s*"vulnerabilities"[^}]*"value"\s*:\s*"\K[^"]+' "$report_dir/metrics.json" 2>/dev/null | head -1 || echo "?")
    smells=$(grep -oP '"metric"\s*:\s*"code_smells"[^}]*"value"\s*:\s*"\K[^"]+' "$report_dir/metrics.json" 2>/dev/null | head -1 || echo "?")
    hotspots=$(grep -oP '"metric"\s*:\s*"security_hotspots"[^}]*"value"\s*:\s*"\K[^"]+' "$report_dir/metrics.json" 2>/dev/null | head -1 || echo "?")
  else
    ok=0
  fi

  report_dir="$repo_root/.tests/react/.sonarq"
  if [ -f "$report_dir/REPORT.md" ] && [ -f "$report_dir/quality-gate.json" ]; then
    qg=$(grep -oP '"status"\s*:\s*"\K[^"]+' "$report_dir/quality-gate.json" 2>/dev/null | head -1 || echo "UNKNOWN")
    bugs=$(grep -oP '"metric"\s*:\s*"bugs"[^}]*"value"\s*:\s*"\K[^"]+' "$report_dir/metrics.json" 2>/dev/null | head -1 || echo "?")
    vulns=$(grep -oP '"metric"\s*:\s*"vulnerabilities"[^}]*"value"\s*:\s*"\K[^"]+' "$report_dir/metrics.json" 2>/dev/null | head -1 || echo "?")
    smells=$(grep -oP '"metric"\s*:\s*"code_smells"[^}]*"value"\s*:\s*"\K[^"]+' "$report_dir/metrics.json" 2>/dev/null | head -1 || echo "?")
    hotspots=$(grep -oP '"metric"\s*:\s*"security_hotspots"[^}]*"value"\s*:\s*"\K[^"]+' "$report_dir/metrics.json" 2>/dev/null | head -1 || echo "?")
  else
    ok=0
  fi

  if [ "$ok" -eq 1 ]; then
    echo ""
    echo -e "${GREEN}[PASS]${NC} $workflow_name - QG=$qg bugs=$bugs vulns=$vulns smells=$smells hotspots=$hotspots"
    results+=("PASS|$workflow_name|$qg|$bugs|$vulns|$smells|$hotspots")
    passed=$((passed + 1))
  else
    echo -e "${RED}[FAIL]${NC} $workflow_name - report files missing"
    results+=("FAIL|$workflow_name|N/A|N/A|N/A|N/A|N/A")
    failed=$((failed + 1))
  fi
}

echo "========================================"
echo "  ops-sonarq E2E Test Suite"
echo "========================================"

ensure_sonarqube

run_scan ".tests/api" "e2e-api" "E2E API"
run_scan ".tests/react" "e2e-react" "E2E React"
run_workflow_cli

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
