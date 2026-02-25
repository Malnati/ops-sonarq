#!/usr/bin/env bash
set -e
set -o pipefail

scan_path="${SCAN_PATH:-${INPUT_PATH:-}}"
project_key="${PROJECT_KEY:-${INPUT_PROJECT_KEY:-}}"
project_name="${PROJECT_NAME:-${INPUT_PROJECT_NAME:-}}"
quality_profile="${QUALITY_PROFILE:-${INPUT_QUALITY_PROFILE:-}}"
quality_profile_language="${QUALITY_PROFILE_LANGUAGE:-${INPUT_QUALITY_PROFILE_LANGUAGE:-}}"
quality_gate="${QUALITY_GATE:-${INPUT_QUALITY_GATE:-}}"
if [ -z "$scan_path" ]; then
  scan_path="api"
fi
if [ -z "$project_key" ]; then
  project_key="project"
fi
if [ -z "$project_name" ]; then
  project_name="Project"
fi
if [ -z "$quality_profile" ]; then
  quality_profile="Sonar way"
fi
if [ -z "$quality_profile_language" ]; then
  quality_profile_language="js"
fi
if [ -z "$quality_gate" ]; then
  quality_gate="Sonar way"
fi

echo "Configuring project: $project_key"
mkdir -p "$scan_path"

echo "SCAN_PATH=$scan_path" >> "$GITHUB_ENV"
echo "PROJECT_KEY=$project_key" >> "$GITHUB_ENV"
echo "PROJECT_NAME=$project_name" >> "$GITHUB_ENV"
echo "QUALITY_PROFILE=$quality_profile" >> "$GITHUB_ENV"
echo "QUALITY_PROFILE_LANGUAGE=$quality_profile_language" >> "$GITHUB_ENV"
echo "QUALITY_GATE=$quality_gate" >> "$GITHUB_ENV"

export PROJECT_KEY="$project_key"
export PROJECT_NAME="$project_name"
export QUALITY_PROFILE="$quality_profile"
export QUALITY_PROFILE_LANGUAGE="$quality_profile_language"
export QUALITY_GATE="$quality_gate"

sonar_user="${SONAR_USER:-admin}"
sonar_pass="${SONAR_PASS:-admin}"

echo "Creating project in SonarQube (if not exists)..."
curl -sf -u "$sonar_user:$sonar_pass" \
  -X POST "$SONAR_HOST_URL/api/projects/create?name=$(printf '%s' "$project_name" | jq -sRr @uri)&project=$project_key" \
  2>/dev/null || echo "Project may already exist, continuing..."

if [ -n "$quality_profile" ] && [ -n "$quality_profile_language" ]; then
  assoc_ok=0
  tried_languages=()
  for lang in "$quality_profile_language" "js" "ts"; do
    skip=0
    for prev in "${tried_languages[@]}"; do
      if [ "$prev" = "$lang" ]; then
        skip=1
        break
      fi
    done
    if [ "$skip" -eq 1 ]; then
      continue
    fi
    tried_languages+=("$lang")
    echo "Associating Quality Profile: $quality_profile ($lang)"
    response=$(curl -sS -u "$sonar_user:$sonar_pass" \
      -X POST "$SONAR_HOST_URL/api/qualityprofiles/add_project?project=$(printf '%s' "$project_key" | jq -sRr @uri)&qualityProfile=$(printf '%s' "$quality_profile" | jq -sRr @uri)&language=$(printf '%s' "$lang" | jq -sRr @uri)" \
      -w "\n%{http_code}")
    http_code=$(printf '%s' "$response" | tail -n1)
    body=$(printf '%s' "$response" | sed '$d')
    if [ "$http_code" -ge 200 ] && [ "$http_code" -lt 300 ]; then
      assoc_ok=1
      break
    fi
    echo "WARN: Quality Profile association failed (HTTP $http_code). ${body:-No response body}"
  done
  if [ "$assoc_ok" -ne 1 ]; then
    echo "WARN: Failed to associate Quality Profile, continuing..."
  fi
fi

if [ -n "$quality_gate" ]; then
  echo "Associating Quality Gate: $quality_gate"
  if ! curl -sfS -u "$sonar_user:$sonar_pass" \
    -X POST "$SONAR_HOST_URL/api/qualitygates/select?projectKey=$(printf '%s' "$project_key" | jq -sRr @uri)&gateName=$(printf '%s' "$quality_gate" | jq -sRr @uri)"; then
    echo "WARN: Failed to associate Quality Gate, continuing..."
  fi
fi

cat > "$scan_path/sonar-project.properties" <<EOF
sonar.projectKey=$project_key
sonar.projectName=$project_name
sonar.projectVersion=1.0
sonar.sources=.
sonar.inclusions=**/*.ts,**/*.tsx,**/*.js,**/*.jsx
sonar.sourceEncoding=UTF-8
sonar.exclusions=.sonarq/**,.scannerwork/**,node_modules/**,dist/**,build/**,coverage/**,**/*.spec.ts,**/*.test.ts
sonar.eslint.reportPaths=.sonarq/eslint-report.json
sonar.host.url=$SONAR_HOST_URL
EOF
echo "Created sonar-project.properties:"
cat "$scan_path/sonar-project.properties"
