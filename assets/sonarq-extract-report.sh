#!/usr/bin/env bash
set -e
set -o pipefail

scan_path="${SCAN_PATH:-${INPUT_PATH:-}}"
project_key="${PROJECT_KEY:-${INPUT_PROJECT_KEY:-}}"
sonar_user="${SONAR_USER:-admin}"
sonar_pass="${SONAR_PASS:-admin}"
if [ -z "$scan_path" ]; then
  scan_path="api"
fi
if [ -z "$project_key" ]; then
  project_key="project"
fi
report_dir="${scan_path}/.sonarq"

echo "Extracting reports to: $report_dir"
echo "Using SonarQube URL: $SONAR_HOST_URL"
cd "$report_dir"

echo "Fetching quality gate status..."
curl -sf -u "$sonar_user:$sonar_pass" "$SONAR_HOST_URL/api/qualitygates/project_status?projectKey=$project_key" -o quality-gate.json 2>/dev/null || echo '{"projectStatus":{"status":"NONE"}}' > quality-gate.json

echo "Fetching project metrics..."
curl -sf -u "$sonar_user:$sonar_pass" "$SONAR_HOST_URL/api/measures/component?component=$project_key&metricKeys=bugs,vulnerabilities,code_smells,coverage,duplicated_lines_density,ncloc,security_hotspots,reliability_rating,security_rating,sqale_rating" -o metrics.json 2>/dev/null || echo '{"component":{"measures":[]}}' > metrics.json

echo "Fetching issues..."
curl -sf -u "$sonar_user:$sonar_pass" "$SONAR_HOST_URL/api/issues/search?componentKeys=$project_key&ps=500&statuses=OPEN,CONFIRMED,REOPENED" -o issues.json 2>/dev/null || echo '{"issues":[],"total":0}' > issues.json

echo "Fetching security hotspots..."
curl -sf -u "$sonar_user:$sonar_pass" "$SONAR_HOST_URL/api/hotspots/search?projectKey=$project_key&ps=500" -o hotspots.json 2>/dev/null || echo '{"hotspots":[],"paging":{"total":0}}' > hotspots.json

echo "Fetching project analysis history..."
curl -sf -u "$sonar_user:$sonar_pass" "$SONAR_HOST_URL/api/project_analyses/search?project=$project_key" -o analyses.json 2>/dev/null || echo '{"analyses":[]}' > analyses.json

echo "Files extracted:"
ls -la

echo "Quality Gate content:"
cat quality-gate.json
echo ""
echo "Metrics content:"
cat metrics.json
