#!/usr/bin/env bash
set -e
set -o pipefail

sonar_url="${SONAR_HOST_URL:-http://localhost:9000}"
echo "Waiting for SonarQube server at $sonar_url to be fully operational..."
max_attempts=60
attempt=1
while [ $attempt -le $max_attempts ]; do
  echo "Attempt $attempt/$max_attempts: Checking SonarQube status..."
  response=$(curl -sf --max-time 5 "$sonar_url/api/system/status" 2>/dev/null || echo "")
  if [ -n "$response" ]; then
    status=$(echo "$response" | grep -oE '"status"\s*:\s*"[^"]+"' | grep -oE '"[A-Z]+"$' | tr -d '"' || echo "UNKNOWN")
    echo "Response from $sonar_url - status: $status"
    if [ "$status" = "UP" ]; then
      echo "SonarQube is UP and ready at $sonar_url!"
      echo "SONAR_HOST_URL=$sonar_url" >> "$GITHUB_ENV"
      exit 0
    fi
  fi
  if [ $attempt -eq $max_attempts ]; then
    echo "ERROR: SonarQube failed to start after $max_attempts attempts"
    exit 1
  fi
  echo "Waiting 10 seconds before next check..."
  sleep 10
  attempt=$((attempt + 1))
done
