<!-- docs/README.md -->
<h1 align="center">ops-literal</h1>

<p align="center">
  <b>Documentation for GitHub users who prefer reading docs inside the repository.</b>
</p>

<p align="center">
  <a href="https://github.com/Malnati/ops-literal"><b>Repository</b></a>
  •
  <a href="https://malnati.github.io/ops-literal/"><b>Landing Page</b></a>
  •
  <a href="https://github.com/marketplace/actions/ops-literal"><b>Marketplace</b></a>
</p>

<hr/>

## What is ops-literal?

**ops-literal** is a GitHub Action that reads a file (or raw text) and exports it as a **safe, multiline-ready output**.

It is meant for automation flows where you need to move content across steps reliably:
- PR bodies
- timeline comments
- job summaries
- other action inputs

## When to use

Use **ops-literal** when you need:
- a stable way to export **multiline** output values
- to avoid accidental log leakage
- to reuse file-based artifacts (reports, markdown, json) downstream

## Quick start

### Export file content (recommended)

```yml
- name: "📦 Export report as literal"
  id: literal
  uses: Malnati/ops-literal@v1
  with:
    path: .reports/20251215-1530_hardcode.json
    output_name: report
    max_bytes: 80000

- name: "🧾 Use in Job Summary"
  shell: bash
  run: |
    printf '%s\n' "${{ steps.literal.outputs.report }}" >> "$GITHUB_STEP_SUMMARY"

Export filename only (basename)

- name: "📦 Export filename"
  id: literal_name
  uses: Malnati/ops-literal@v1
  with:
    path: .reports/20251215-1530_hardcode.json
    output_name: filename
    mode: basename

- name: "🔎 Show filename"
  run: echo "${{ steps.literal_name.outputs.filename }}"

Export a sha256 hash (traceability)

- name: "🔐 Export SHA256"
  id: literal_hash
  uses: Malnati/ops-literal@v1
  with:
    path: .reports/20251215-1530_hardcode.json
    output_name: report_sha
    mode: sha256

- name: "🔎 Show hash"
  run: echo "${{ steps.literal_hash.outputs.report_sha }}"

Export raw text (no file)

- name: "🧱 Export raw text"
  id: literal_text
  uses: Malnati/ops-literal@v1
  with:
    text: |
      Hello
      Multiline
      World
    output_name: message

- name: "🔎 Show"
  run: echo "${{ steps.literal_text.outputs.message }}"

Inputs

Input	Required	Default	Description
path	no*	—	File path to read (preferred).
text	no*	—	Raw text to export as output.
output_name	no	literal	Output key name.
mode	no	content	content | basename | sha256
max_bytes	no	0	If > 0, truncates output to this size (bytes).
trim	no	true	Trim trailing whitespace/newlines.
fail_on_missing	no	true	Fail if path does not exist (when path is used).

* Provide either path or text.

Outputs

Output	Description
<output_name>	The exported value (content/basename/hash depending on mode).
bytes	Byte size of the original content.
truncated	true if truncation happened.

Notes about limits
	•	Keep max_bytes within a safe range if you plan to pass the output to other actions or to PR comments.
	•	Prefer $GITHUB_STEP_SUMMARY for large payloads instead of printing to logs.

Security
	•	Do not export secrets as literals.
	•	Avoid posting private content to PR comments on public repositories.
	•	This action should avoid printing the full content by default.

License

MIT. See LICENSE￼.

