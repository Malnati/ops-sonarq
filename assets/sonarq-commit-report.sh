#!/usr/bin/env bash
set -e
set -o pipefail

scan_path="${SCAN_PATH:-${INPUT_PATH:-}}"
if [ -z "$scan_path" ]; then
  scan_path="api"
fi
report_dir="${scan_path}/.sonarq"
base_branch="${GITHUB_REF_NAME:-}"
timestamp=$(date -u +"%Y%m%d%H%M%S")
report_branch="sonarq/report-${base_branch}-${timestamp}"

git config user.name "github-actions[bot]"
git config user.email "github-actions[bot]@users.noreply.github.com"

git add "$report_dir"
if git diff --cached --quiet; then
  echo "No changes to commit"
else
  echo "Creating report branch: $report_branch"
  git checkout -b "$report_branch"
  git commit -m "ci(sonarqube): Add quality report for $scan_path [$timestamp]"
  git push -u origin "$report_branch"
  echo "Creating Pull Request..."
  pr_body="## SonarQube Quality Report"
  pr_body="${pr_body}\n\nThis PR contains the SonarQube analysis report for \`$scan_path\`."
  pr_body="${pr_body}\n\n### Generated Files"
  pr_body="${pr_body}\n- \`$report_dir/REPORT.md\` - Human-readable summary"
  pr_body="${pr_body}\n- \`$report_dir/quality-gate.json\` - Quality Gate status"
  pr_body="${pr_body}\n- \`$report_dir/metrics.json\` - Project metrics"
  pr_body="${pr_body}\n- \`$report_dir/issues.json\` - Detailed issues"
  pr_body="${pr_body}\n- \`$report_dir/hotspots.json\` - Security hotspots"
  pr_body="${pr_body}\n- \`$report_dir/analyses.json\` - Analysis history"
  pr_body="${pr_body}\n\n### Workflow Run"
  pr_body="${pr_body}\n- **Run ID:** ${GITHUB_RUN_ID:-}"
  pr_body="${pr_body}\n- **Run Number:** #${GITHUB_RUN_NUMBER:-}"
  pr_body="${pr_body}\n- **Branch:** $base_branch"
  pr_body="${pr_body}\n- **Commit:** ${GITHUB_SHA:-}"
  pr_body="${pr_body}\n\n---"
  pr_body="${pr_body}\n*Generated automatically by SonarQube Scan Workflow*"
  pr_url=$(echo -e "$pr_body" | gh pr create \
    --base "$base_branch" \
    --head "$report_branch" \
    --title "ci(sonarqube): Quality report for $scan_path" \
    --body-file - 2>/dev/null || echo "")
  if [ -n "$pr_url" ]; then
    echo "Pull Request created: $pr_url"
  else
    echo "Pull Request creation skipped (may already exist or label not available)"
    echo "Branch $report_branch pushed successfully - manual PR creation may be needed"
  fi
fi
