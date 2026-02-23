<!-- README.md -->
<h1 align="center">Malnati/ops-literal</h1>

<p align="center">
  <b>Turn files into safe, reusable GitHub Actions outputs (multiline-ready), without leaking logs.</b>
</p>

<p align="center">
  <a href="https://github.com/Malnati/ops-literal/releases">
    <img alt="Release" src="https://img.shields.io/github/v/release/Malnati/ops-literal?include_prereleases" />
  </a>
  <a href="https://github.com/Malnati/ops-literal/blob/main/LICENSE">
    <img alt="License" src="https://img.shields.io/badge/license-MIT-green" />
  </a>
  <img alt="Marketplace" src="https://img.shields.io/badge/marketplace-coming%20soon-lightgrey" />
</p>

<p align="center">
  <a href="https://github.com/Malnati/ops-literal"><b>Repository</b></a>
  •
  <a href="https://malnati.github.io/ops-literal/"><b>Landing Page</b></a>
  •
  <a href="https://github.com/marketplace/actions/ops-literal"><b>Marketplace</b></a>
  •
  <a href="https://github.com/Malnati/ops-literal/issues"><b>Issues</b></a>
</p>

<p align="center">
  <a href="https://github.com/Malnati/ops-literal">
    <img alt="Ops-literal" src="assets/ops-literal-splash-large.png" />
  </a>
</p>

<hr/>

## What it is

**ops-literal** is a GitHub Action that reads a file (or a raw string) and exports it as a **safe, multiline output** for downstream steps.

It is designed for IssueOps / PR automation flows where you need to reuse generated artifacts (reports, markdown, JSON) in:
- PR bodies
- timeline comments
- job summaries
- other actions inputs

…without printing full content to logs.

<p align="center">
  <a href="https://github.com/Malnati/ops-literal">
    <img alt="Ops-literal" src="assets/ops-literal-whatisit-large.png" />
  </a>
</p>

## Why

GitHub Actions has a few sharp edges around:
- multiline values
- output escaping
- accidentally leaking logs
- having to “re-implement file reading” in every workflow

This action standardizes the “read → sanitize → optionally truncate → export” workflow.

## Features

- ✅ Read from `path` (recommended) or from `text`
- ✅ Multiline-safe outputs (ready for Markdown/JSON)
- ✅ Optional size limit + truncation indicator
- ✅ Optional hashing (for traceability)
- ✅ No default content printing to logs

## Quick start

#### Example: 

```yml
# .github/workflows/hardcode.yml
name: "🪲 Hard-code sentinel"

on:
  workflow_dispatch:
    inputs:
      path:
        description: Path to scan
        required: true
        type: string

permissions:
  contents: write
  security-events: write
  pull-requests: write

jobs:
  hardcode:
    runs-on: ubuntu-latest
    env:
      GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}

    steps:
      - name: Checkout Source Code
        uses: actions/checkout@v4
        with:
          fetch-depth: 0
          persist-credentials: true
          
      - name: Set scan path
        id: config
        run: |
          scan_path="${{ inputs.path }}"
          if [ -z "$scan_path" ]; then
            scan_path="api"
          fi
          echo "scan_path=$scan_path" >> "$GITHUB_OUTPUT"
          echo "Scan path configured: $scan_path"

      - name: "🦮 Hardcode Sentinel"
        id: hardcode
        uses: Malnati/ops-literal@v1.0.0
        with:
          target_path: "${{ steps.config.outputs.scan_path }}"
          token: ${{ secrets.GITHUB_TOKEN }}
      
      - name: "🔎 Scan results summary"
        shell: bash
        run: |
          printf '%s\n' "${{ steps.hardcode.outputs.report }}" >> "$GITHUB_STEP_SUMMARY"
          echo "${{ steps.hardcode.outputs.json }}"
          echo "${{ steps.hardcode.outputs.status }}"
          echo "${{ steps.hardcode.outputs.count }}"
          
      - name: Create Report Directory
        id: directorier
        run: |
          scan_path="${{ steps.config.outputs.scan_path }}"
          report_dir="${scan_path}/.hardcode"
          echo "Creating report directory: $report_dir"
          mkdir -p "$report_dir"
          echo "Report directory created successfully"
          echo "report_dir=$report_dir" >> "$GITHUB_OUTPUT"

      - name: Copy Report to Directory
        id: copeer
        run: |
          from="${{ steps.hardcode.outputs.json }}"
          to="${{ steps.directorier.outputs.report_dir }}"
          cp $from $to
          echo "Created a copy of  ${{ steps.hardcode.outputs.json }} at ${{ steps.directorier.outputs.report_dir }}"

      - name: Show Report Directory
        run: |
          echo "Report directory listes below"
          ls -la "${{ steps.directorier.outputs.report_dir }}"
          
      - name: Commit Report via Pull Request
        env:
          GH_TOKEN: ${{ github.token }}
        run: |
          scan_path="${{ steps.config.outputs.scan_path }}"
          report_dir="${{ steps.directorier.outputs.report_dir }}"
          base_branch="${{ github.ref_name }}"
          timestamp=$(date -u +"%Y%m%d%H%M%S")
          report_branch="hardcode/report-${base_branch}-${timestamp}"
          git config user.name "github-actions[bot]"
          git config user.email "github-actions[bot]@users.noreply.github.com"
          git add "$report_dir"
          if git diff --cached --quiet; then
            echo "No changes to commit"
          else
            echo "Creating report branch: $report_branch"
            git checkout -b "$report_branch"
            git commit -m "ci(hardcode): Add quality report for $scan_path [$timestamp]"
            git push -u origin "$report_branch"
            echo "Creating Pull Request..."
            pr_body="## Sentinel Quality Report"
            pr_body="${pr_body}\n\nThis PR contains the hardcode analysis report for \`$scan_path\`."
            pr_body="${pr_body}\n\n### Generated Files"
            pr_body="${pr_body}\n- \`${{ steps.directorier.outputs.report_dir }}\` - Hardcode JSON report"
            pr_body="${pr_body}\n\n### Workflow Run"
            pr_body="${pr_body}\n- **Run ID:** ${{ github.run_id }}"
            pr_body="${pr_body}\n- **Run Number:** #${{ github.run_number }}"
            pr_body="${pr_body}\n- **Branch:** $base_branch"
            pr_body="${pr_body}\n- **Commit:** ${{ github.sha }}"
            pr_body="${pr_body}\n\n---"
            pr_body="${pr_body}\n*Generated automatically by hardcode Workflow*"
            pr_url=$(echo -e "$pr_body" | gh pr create \
              --base "$base_branch" \
              --head "$report_branch" \
              --title "ci(hardcode): Quality report for $scan_path" \
              --body-file - 2>/dev/null || echo "")
            if [ -n "$pr_url" ]; then
              echo "Pull Request created: $pr_url"
            else
              echo "Pull Request creation skipped (may already exist or label not available)"
              echo "Branch $report_branch pushed successfully - manual PR creation may be needed"
            fi
          fi

      - name: Upload Report Artifacts
        uses: actions/upload-artifact@v4
        with:
          name: hardcode-report
          path: |
            ${{ steps.config.outputs.scan_path }}/.hardcode/
          retention-days: 30  
```

#### Inputs

##### Input	Required	Default	Description
- path	no*	—	File path to read (preferred).
- text	no*	—	Raw text to export as output.
- output_name	no	literal	Output key name.
- mode	no	content	content | basename | sha256
- max_bytes	no	0	If > 0, truncates output to this size (bytes).
- trim	no	true	Trim trailing whitespace/newlines.
- fail_on_missing	no	true	Fail if path does not exist (when path is used).

* Provide either path or text.

#### Outputs

##### Output	Description
- `<output_name>`	The exported value (content/basename/hash depending on mode).
- bytes	Byte size of the original content.
- truncated	true if truncation happened.

###### Use with reports (avoid printing content)
- Prefer max_bytes to keep outputs predictable.
- Prefer writing to $GITHUB_STEP_SUMMARY over echoing large payloads to the log.

###### Security notes
- This action should not print file content by default.
- Never feed secrets into text or path content that might be posted publicly (PR comments, summaries, artifacts).
- Use GitHub permissions minimally (this action does not need extra permissions by itself).

#### Versioning

###### This project uses semantic versioning.
- Pin to a major version: Malnati/ops-literal@v1
- Or pin to an exact tag: Malnati/ops-literal@v1.0.0

### License

MIT. See LICENSE￼.
