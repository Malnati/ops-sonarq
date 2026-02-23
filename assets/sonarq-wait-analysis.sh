#!/usr/bin/env bash
set -e
set -o pipefail

echo "Waiting for SonarQube to process analysis results..."
sleep 30
project_key="${PROJECT_KEY:-${INPUT_PROJECT_KEY:-}}"
sonar_user="${SONAR_USER:-admin}"
sonar_pass="${SONAR_PASS:-admin}"
if [ -z "$project_key" ]; then
  project_key="project"
fi
max_attempts=20
attempt=1
while [ $attempt -le $max_attempts ]; do
  echo "Attempt $attempt/$max_attempts: Checking analysis status..."
  ce_status=$(curl -sf -u "$sonar_user:$sonar_pass" "$SONAR_HOST_URL/api/ce/component?component=$project_key" 2>/dev/null || echo "{}")
  echo "CE Status response: $ce_status"
  pending=$(echo "$ce_status" | grep -c '"status":"PENDING"' 2>/dev/null || true)
  in_progress=$(echo "$ce_status" | grep -c '"status":"IN_PROGRESS"' 2>/dev/null || true)
  pending=${pending:-0}
  in_progress=${in_progress:-0}
  if [ "$pending" -eq 0 ] && [ "$in_progress" -eq 0 ]; then
    echo "Analysis processing completed"
    break
  fi
  echo "Analysis still processing, waiting 10 seconds..."
  sleep 10
  attempt=$((attempt + 1))
done
