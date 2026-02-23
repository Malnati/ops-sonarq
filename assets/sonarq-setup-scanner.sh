#!/usr/bin/env bash
set -e
set -o pipefail

sonar_scanner_version="${SONAR_SCANNER_VERSION:-6.2.1.4610}"

extract_zip() {
  local zip_file="$1"
  local dest_dir="$2"
  if command -v unzip &>/dev/null; then
    unzip -qo "$zip_file" -d "$dest_dir"
  elif command -v python3 &>/dev/null; then
    python3 -c "
import zipfile, sys, os
with zipfile.ZipFile('$zip_file', 'r') as z:
    z.extractall('$dest_dir')
    for info in z.infolist():
        extracted = os.path.join('$dest_dir', info.filename)
        if not info.is_dir():
            perm = info.external_attr >> 16
            if perm:
                os.chmod(extracted, perm)
"
  elif busybox unzip 2>&1 | grep -q "Usage"; then
    busybox unzip -qo "$zip_file" -d "$dest_dir"
  else
    echo "ERROR: No zip extraction tool available (unzip, python3, or busybox unzip)."
    exit 1
  fi
}

scanner_dir="/tmp/sonar-scanner-${sonar_scanner_version}-linux-x64"
if [ -x "$scanner_dir/bin/sonar-scanner" ]; then
  echo "SonarScanner v$sonar_scanner_version already installed, skipping download."
else
  echo "Downloading SonarScanner CLI v$sonar_scanner_version..."
  curl -fsSL -o /tmp/sonar-scanner.zip "https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-${sonar_scanner_version}-linux-x64.zip"
  extract_zip /tmp/sonar-scanner.zip /tmp
  chmod +x "$scanner_dir/bin/sonar-scanner"
  rm -f /tmp/sonar-scanner.zip
fi

echo "SONAR_SCANNER_VERSION=$sonar_scanner_version" >> "$GITHUB_ENV"
echo "SONAR_SCANNER_HOME=$scanner_dir" >> "$GITHUB_ENV"
echo "PATH=$scanner_dir/bin:$PATH" >> "$GITHUB_ENV"

echo "SonarScanner installed at: $scanner_dir"
ls -la "$scanner_dir/bin/"
