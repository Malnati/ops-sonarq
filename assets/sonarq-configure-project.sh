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

echo "Configuring project: $project_key"
mkdir -p "$scan_path"

echo "SCAN_PATH=$scan_path" >> "$GITHUB_ENV"
echo "PROJECT_KEY=$project_key" >> "$GITHUB_ENV"
echo "PROJECT_NAME=$project_name" >> "$GITHUB_ENV"

export PROJECT_KEY="$project_key"
export PROJECT_NAME="$project_name"

envsubst < "$GITHUB_WORKSPACE/assets/sonar-project.properties.template" > "$scan_path/sonar-project.properties"
echo "Created sonar-project.properties:"
cat "$scan_path/sonar-project.properties"
