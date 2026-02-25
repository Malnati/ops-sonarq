#!/usr/bin/env bash
set -e
set -o pipefail

echo "Detecting SonarQube host URL..."
sonar_url=""

if [ -n "${SONAR_HOST_URL:-}" ]; then
  echo "Using provided SONAR_HOST_URL: $SONAR_HOST_URL"
  sonar_url="$SONAR_HOST_URL"
fi

if [ -z "$sonar_url" ]; then
  for url in "http://sonarqube:9000" "http://localhost:9000" "http://127.0.0.1:9000" "http://host.docker.internal:9000"; do
    echo "Trying $url..."
    response=$(curl -sf --max-time 5 "$url/api/system/status" 2>/dev/null || echo "")
    if [ -n "$response" ]; then
      sonar_url="$url"
      echo "Found SonarQube at $url"
      break
    fi
  done
fi

if [ -z "$sonar_url" ]; then
  echo "SonarQube not immediately available, defaulting to localhost"
  sonar_url="http://localhost:9000"
fi

echo "SONAR_HOST_URL=$sonar_url" >> "$GITHUB_ENV"
echo "sonar_url=$sonar_url" >> "$GITHUB_OUTPUT"
echo "Using SonarQube URL: $sonar_url"
