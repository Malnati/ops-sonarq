#!/usr/bin/env bash
set -e
set -o pipefail

scan_path="${SCAN_PATH:-${INPUT_PATH:-}}"
project_key="${PROJECT_KEY:-${INPUT_PROJECT_KEY:-}}"
project_name="${PROJECT_NAME:-${INPUT_PROJECT_NAME:-}}"
if [ -z "$scan_path" ]; then
  scan_path="api"
fi
if [ -z "$project_key" ]; then
  project_key="project"
fi
if [ -z "$project_name" ]; then
  project_name="Project"
fi
report_dir="${scan_path}/.sonarq"
project_props="${scan_path}/sonar-project.properties"

export PROJECT_KEY="$project_key"
export PROJECT_NAME="$project_name"
export TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
export RUN_ID="${GITHUB_RUN_ID:-local}"
export RUN_NUMBER="${GITHUB_RUN_NUMBER:-local}"
export BRANCH="${GITHUB_REF_NAME:-local}"
export SHORT_SHA=$(echo "${GITHUB_SHA:-local}" | cut -c1-7)
export SCAN_PATH="$scan_path"
export QG_STATUS="NONE"
export SONAR_SOURCES="src"
export SONAR_INCLUSIONS="(none)"
export SONAR_EXCLUSIONS="(none)"
export SONAR_ESLINT_REPORT="(none)"

read_prop() {
  key="$1"
  file="$2"
  if [ -f "$file" ]; then
    val=$(grep -E "^${key}=" "$file" | head -1 | cut -d'=' -f2-)
    if [ -n "$val" ]; then
      echo "$val"
      return
    fi
  fi
  echo ""
}

if [ -f "$project_props" ]; then
  sources_val=$(read_prop "sonar.sources" "$project_props")
  inclusions_val=$(read_prop "sonar.inclusions" "$project_props")
  exclusions_val=$(read_prop "sonar.exclusions" "$project_props")
  eslint_val=$(read_prop "sonar.eslint.reportPaths" "$project_props")
  [ -n "$sources_val" ] && export SONAR_SOURCES="$sources_val"
  [ -n "$inclusions_val" ] && export SONAR_INCLUSIONS="$inclusions_val"
  [ -n "$exclusions_val" ] && export SONAR_EXCLUSIONS="$exclusions_val"
  [ -n "$eslint_val" ] && export SONAR_ESLINT_REPORT="$eslint_val"
fi

if [ -f "$report_dir/quality-gate.json" ]; then
  export QG_STATUS=$(grep -oP '"status"\s*:\s*"\K[^"]+' "$report_dir/quality-gate.json" 2>/dev/null | head -1 || echo "NONE")
fi
case "$QG_STATUS" in
  OK) export QG_ICON="PASSED" ;;
  ERROR) export QG_ICON="FAILED" ;;
  WARN) export QG_ICON="WARNING" ;;
  NONE) export QG_ICON="NOT_COMPUTED" ;;
  *) export QG_ICON="UNKNOWN" ;;
esac
extract_metric() {
  metric_key="$1"
  default_val="$2"
  if [ -f "$report_dir/metrics.json" ]; then
    val=$(grep -oP "\"metric\"\\s*:\\s*\"$metric_key\"[^}]*\"value\"\\s*:\\s*\"\\K[^\"]+" "$report_dir/metrics.json" 2>/dev/null | head -1)
    if [ -n "$val" ]; then
      echo "$val"
      return
    fi
  fi
  echo "$default_val"
}
export BUGS=$(extract_metric "bugs" "0")
export VULNERABILITIES=$(extract_metric "vulnerabilities" "0")
export CODE_SMELLS=$(extract_metric "code_smells" "0")
export COVERAGE=$(extract_metric "coverage" "0.0")
export DUPLICATED=$(extract_metric "duplicated_lines_density" "0.0")
export NCLOC=$(extract_metric "ncloc" "0")
export HOTSPOTS=$(extract_metric "security_hotspots" "0")
export TOTAL_ISSUES="0"
if [ -f "$report_dir/issues.json" ]; then
  export TOTAL_ISSUES=$(grep -oP '"total"\s*:\s*\K[0-9]+' "$report_dir/issues.json" 2>/dev/null | head -1 || echo "0")
fi
export BLOCKER_ISSUES="0"
export CRITICAL_ISSUES="0"
export MAJOR_ISSUES="0"
export MINOR_ISSUES="0"
if [ -f "$report_dir/issues.json" ]; then
  BLOCKER_ISSUES=$(grep -c '"severity":"BLOCKER"' "$report_dir/issues.json" 2>/dev/null || true)
  CRITICAL_ISSUES=$(grep -c '"severity":"CRITICAL"' "$report_dir/issues.json" 2>/dev/null || true)
  MAJOR_ISSUES=$(grep -c '"severity":"MAJOR"' "$report_dir/issues.json" 2>/dev/null || true)
  MINOR_ISSUES=$(grep -c '"severity":"MINOR"' "$report_dir/issues.json" 2>/dev/null || true)
  [ -z "$BLOCKER_ISSUES" ] && BLOCKER_ISSUES="0"
  [ -z "$CRITICAL_ISSUES" ] && CRITICAL_ISSUES="0"
  [ -z "$MAJOR_ISSUES" ] && MAJOR_ISSUES="0"
  [ -z "$MINOR_ISSUES" ] && MINOR_ISSUES="0"
  export BLOCKER_ISSUES CRITICAL_ISSUES MAJOR_ISSUES MINOR_ISSUES
fi

cat > "$report_dir/REPORT.md" <<EOF
# SonarQube Quality Report

## Summary

| Item | Value |
|------|-------|
| **Project** | ${PROJECT_NAME} |
| **Project Key** | ${PROJECT_KEY} |
| **Quality Gate** | ${QG_ICON} (${QG_STATUS}) |
| **Generated** | ${TIMESTAMP} |
| **Branch** | ${BRANCH} |
| **Commit** | ${SHORT_SHA} |
| **Workflow Run** | #${RUN_NUMBER} (ID: ${RUN_ID}) |

## Quality Gate Status

**Status: ${QG_ICON}**

The Quality Gate status indicates whether the project meets the defined quality standards.

## Code Metrics

### Overview

| Metric | Value | Description |
|--------|-------|-------------|
| Lines of Code | ${NCLOC} | Total lines of code analyzed |
| Bugs | ${BUGS} | Reliability issues |
| Vulnerabilities | ${VULNERABILITIES} | Security issues |
| Security Hotspots | ${HOTSPOTS} | Security-sensitive code to review |
| Code Smells | ${CODE_SMELLS} | Maintainability issues |
| Coverage | ${COVERAGE}% | Test coverage percentage |
| Duplications | ${DUPLICATED}% | Duplicated lines percentage |

### Issues by Severity

| Severity | Count |
|----------|-------|
| Blocker | ${BLOCKER_ISSUES} |
| Critical | ${CRITICAL_ISSUES} |
| Major | ${MAJOR_ISSUES} |
| Minor | ${MINOR_ISSUES} |
| **Total** | **${TOTAL_ISSUES}** |

## Analysis Details

### Scan Configuration

- **Scan Path:** ${SCAN_PATH}
- **Sources:** ${SONAR_SOURCES}
- **Inclusions:** ${SONAR_INCLUSIONS}
- **Exclusions:** ${SONAR_EXCLUSIONS}
- **ESLint Report:** ${SONAR_ESLINT_REPORT}

### SonarQube Server

- **Version:** LTS Community Edition (9.9.x)
- **Mode:** Ephemeral (in-workflow container)

## Raw Data Files

The following JSON files contain the complete analysis data:

- \`quality-gate.json\` - Quality Gate status and conditions
- \`metrics.json\` - All project metrics
- \`issues.json\` - Detailed issue list
- \`hotspots.json\` - Security hotspots
- \`analyses.json\` - Analysis history

---

*Report generated automatically by SonarQube Scan Workflow*
*Workflow: .github/workflows/sonarq.yml*
EOF
echo "Generated REPORT.md:"
cat "$report_dir/REPORT.md"
