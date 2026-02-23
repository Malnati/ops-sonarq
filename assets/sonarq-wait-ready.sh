#!/usr/bin/env bash
set -e
set -o pipefail

echo "Waiting for SonarQube server at $SONAR_HOST_URL to be fully operational..."
max_attempts=60
attempt=1
while [ $attempt -le $max_attempts ]; do
  echo "Attempt $attempt/$max_attempts: Checking SonarQube status..."
  for url in "$SONAR_HOST_URL" "http://localhost:9000" "http://sonarqube:9000" "http://host.docker.internal:9000"; do
    response=$(curl -sf --max-time 5 "$url/api/system/status" 2>/dev/null || echo "")
    if [ -n "$response" ]; then
      status=$(echo "$response" | grep -oE '"status"\s*:\s*"[^"]+"' | grep -oE '"[A-Z]+"$' | tr -d '"' || echo "UNKNOWN")
      echo "Response from $url - status: $status"
      if [ "$status" = "UP" ]; then
        echo "SonarQube is UP and ready at $url!"
        echo "SONAR_HOST_URL=$url" >> "$GITHUB_ENV"
        exit 0
      fi
      break
    fi
  done
  if [ $attempt -eq $max_attempts ]; then
    echo "ERROR: SonarQube failed to start after $max_attempts attempts"
    exit 1
  fi
  echo "Waiting 10 seconds before next check..."
  sleep 10
  attempt=$((attempt + 1))
done
