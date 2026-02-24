# SonarQube Quality Report

## Summary

| Item | Value |
|------|-------|
| **Project** | E2E React |
| **Project Key** | e2e-react |
| **Quality Gate** | PASSED (OK) |
| **Generated** | 2026-02-24T16:18:41Z |
| **Branch** | local |
| **Commit** | local |
| **Workflow Run** | #local (ID: local) |

## Quality Gate Status

**Status: PASSED**

The Quality Gate status indicates whether the project meets the defined quality standards.

## Code Metrics

### Overview

| Metric | Value | Description |
|--------|-------|-------------|
| Lines of Code | 380 | Total lines of code analyzed |
| Bugs | 0 | Reliability issues |
| Vulnerabilities | 0 | Security issues |
| Security Hotspots | 2 | Security-sensitive code to review |
| Code Smells | 14 | Maintainability issues |
| Coverage | 0.0% | Test coverage percentage |
| Duplications | 0.0% | Duplicated lines percentage |

### Issues by Severity

| Severity | Count |
|----------|-------|
| Blocker | 1 |
| Critical | 1 |
| Major | 1 |
| Minor | 1 |
| **Total** | **14** |

## Analysis Details

### Scan Configuration

- **Scan Path:** .tests/react
- **Source Directory:** src
- **Exclusions:** node_modules/**, dist/**, build/**, coverage/**, *.spec.ts, *.test.ts

### SonarQube Server

- **Version:** LTS Community Edition (9.9.x)
- **Mode:** Ephemeral (in-workflow container)

## Raw Data Files

The following JSON files contain the complete analysis data:

- `quality-gate.json` - Quality Gate status and conditions
- `metrics.json` - All project metrics
- `issues.json` - Detailed issue list
- `hotspots.json` - Security hotspots
- `analyses.json` - Analysis history

---

*Report generated automatically by SonarQube Scan Workflow*
*Workflow: .github/workflows/sonarq.yml*
