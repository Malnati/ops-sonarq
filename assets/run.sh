#!/usr/bin/env bash
set -e
set -o pipefail

usage() {
  cat <<'USAGE'
Usage: assets/run.sh [options]

Options:
  --path <path>                 Path to scan (default: api)
  --project-key <key>           Project key (default: project)
  --project-name <name>         Project name (default: Project)
  --sonar-host-url <url>        SonarQube URL (default: http://localhost:9000)
  --sonar-scanner-version <ver> SonarScanner CLI version (default: 5.0.1.3006)
  --sonar-user <user>           SonarQube user (default: admin)
  --sonar-pass <pass>           SonarQube password (default: admin)
  -h, --help                    Show this help
USAGE
}

SCAN_PATH="api"
PROJECT_KEY="project"
PROJECT_NAME="Project"
SONAR_HOST_URL="http://localhost:9000"
SONAR_SCANNER_VERSION="5.0.1.3006"
SONAR_USER="admin"
SONAR_PASS="admin"

while [ $# -gt 0 ]; do
  case "$1" in
    --path)
      SCAN_PATH="$2"
      shift 2
      ;;
    --project-key)
      PROJECT_KEY="$2"
      shift 2
      ;;
    --project-name)
      PROJECT_NAME="$2"
      shift 2
      ;;
    --sonar-host-url)
      SONAR_HOST_URL="$2"
      shift 2
      ;;
    --sonar-scanner-version)
      SONAR_SCANNER_VERSION="$2"
      shift 2
      ;;
    --sonar-user)
      SONAR_USER="$2"
      shift 2
      ;;
    --sonar-pass)
      SONAR_PASS="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      usage
      exit 1
      ;;
  esac
 done

script_dir=$(cd "$(dirname "$0")" && pwd)
repo_root=$(cd "$script_dir/.." && pwd)

export GITHUB_WORKSPACE="$repo_root"
export INPUT_PATH="$SCAN_PATH"
export INPUT_PROJECT_KEY="$PROJECT_KEY"
export INPUT_PROJECT_NAME="$PROJECT_NAME"
export SCAN_PATH PROJECT_KEY PROJECT_NAME
export SONAR_HOST_URL SONAR_SCANNER_VERSION SONAR_USER SONAR_PASS

export GITHUB_ENV
export GITHUB_OUTPUT
GITHUB_ENV=$(mktemp)
GITHUB_OUTPUT=$(mktemp)

load_env() {
  if [ -f "$GITHUB_ENV" ]; then
    while IFS= read -r line; do
      [ -z "$line" ] && continue
      export "$line"
    done < "$GITHUB_ENV"
  fi
}

run_step() {
  echo "==> $1"
  bash "$repo_root/$2"
  load_env
}

run_step "Set scan path" "assets/sonarq-set-scan-path.sh"
run_step "Detect SonarQube host" "assets/sonarq-detect-host.sh"
run_step "Wait for SonarQube ready" "assets/sonarq-wait-ready.sh"
run_step "Configure project" "assets/sonarq-configure-project.sh"
run_step "Setup SonarScanner" "assets/sonarq-setup-scanner.sh"
run_step "Verify source directory" "assets/sonarq-verify-source.sh"
run_step "Run SonarQube scan" "assets/sonarq-run-scan.sh"
run_step "Wait for analysis" "assets/sonarq-wait-analysis.sh"
run_step "Create report directory" "assets/sonarq-create-report-dir.sh"
run_step "Extract report" "assets/sonarq-extract-report.sh"
run_step "Generate report" "assets/sonarq-generate-report.sh"
run_step "Verify report" "assets/sonarq-verify-report.sh"

echo "Done. Report directory: ${SCAN_PATH}/.sonarq"
