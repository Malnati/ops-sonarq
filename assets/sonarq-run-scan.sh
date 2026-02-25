#!/usr/bin/env bash
set -e
set -o pipefail

scan_path="${SCAN_PATH:-${INPUT_PATH:-}}"
project_key="${PROJECT_KEY:-${INPUT_PROJECT_KEY:-}}"
sonar_user="${SONAR_USER:-admin}"
sonar_pass="${SONAR_PASS:-admin}"
sonar_token="${SONAR_TOKEN:-${INPUT_SONAR_TOKEN:-}}"
scanner_debug="${SCANNER_DEBUG:-${INPUT_SCANNER_DEBUG:-false}}"

if [ -z "$scan_path" ]; then
  scan_path="api"
fi

abs_scan_path="$GITHUB_WORKSPACE/$scan_path"
cd "$abs_scan_path"

if [ -z "$project_key" ]; then
  project_key="project"
fi
echo "Starting SonarQube scan for project: $project_key"
echo "Scan path: $abs_scan_path"
echo "SonarQube URL: $SONAR_HOST_URL"

if [ ! -f "package.json" ]; then
  echo '{"name":"scan-target","version":"1.0.0","private":true}' > package.json
fi

npm install --save-dev eslint@8.57.1 @typescript-eslint/parser@7.18.0 @typescript-eslint/eslint-plugin@7.18.0 eslint-plugin-sonarjs@0.25.1 --no-package-lock --force 2>&1 | tail -5

cp "$GITHUB_WORKSPACE/assets/eslint.config.cjs.template" ./eslint.config.cjs

mkdir -p .sonarq
npx eslint . \
  --format json \
  --output-file .sonarq/eslint-report.json \
  --ignore-pattern eslint.config.cjs || true

if [ ! -f ".sonarq/eslint-report.json" ]; then
  echo "[]" > .sonarq/eslint-report.json
fi

scanner_flags=()
if [ "$scanner_debug" = "true" ]; then
  scanner_flags+=("-X")
fi

auth_flags=()
if [ -n "$sonar_token" ]; then
  auth_flags+=("-Dsonar.login=$sonar_token")
else
  auth_flags+=("-Dsonar.login=$sonar_user" "-Dsonar.password=$sonar_pass")
fi

sonar-scanner \
  "${scanner_flags[@]}" \
  -Dsonar.projectKey="$project_key" \
  -Dsonar.host.url="$SONAR_HOST_URL" \
  "${auth_flags[@]}" \
  -Dsonar.projectBaseDir="$PWD" \
  -Dsonar.qualitygate.wait=false

echo "SonarQube scan completed"
