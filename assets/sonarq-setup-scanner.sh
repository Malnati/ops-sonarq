#!/usr/bin/env bash
set -e
set -o pipefail

sonar_scanner_version="${SONAR_SCANNER_VERSION:-5.0.1.3006}"

echo "Downloading SonarScanner CLI v$sonar_scanner_version..."
curl -fsSL -o /tmp/sonar-scanner.zip "https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-${sonar_scanner_version}-linux-x64.zip"
unzip -q /tmp/sonar-scanner.zip -d /tmp
scanner_dir="/tmp/sonar-scanner-${sonar_scanner_version}-linux-x64"
chmod +x "$scanner_dir/bin/sonar-scanner"

echo "SONAR_SCANNER_VERSION=$sonar_scanner_version" >> "$GITHUB_ENV"
echo "SONAR_SCANNER_HOME=$scanner_dir" >> "$GITHUB_ENV"
echo "PATH=$scanner_dir/bin:$PATH" >> "$GITHUB_ENV"

echo "SonarScanner installed at: $scanner_dir"
ls -la "$scanner_dir/bin/"
