# SonarQube Quality Report

## Summary

| Item | Value |
|------|-------|
| **Project** | E2E React |
| **Project Key** | e2e-react |
| **Quality Gate** | PASSED (OK) |
| **Generated** | 2026-02-25T16:45:58Z |
| **Branch** | main |
| **Commit** | f483331 |
| **Workflow Run** | #1 (ID: 1) |

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
| Code Smells | 36 | Maintainability issues |
| Coverage | 0.0% | Test coverage percentage |
| Duplications | 0.0% | Duplicated lines percentage |

### Issues by Severity

| Severity | Count |
|----------|-------|
| Blocker | 1 |
| Critical | 1 |
| Major | 1 |
| Minor | 1 |
| **Total** | **36** |

## Analysis Details

### Scan Configuration

- **Scan Path:** .tests/react
- **Sources:** .
- **Inclusions:** **/*.ts,**/*.tsx,**/*.js,**/*.jsx
- **Exclusions:** .sonarq/**,.scannerwork/**,node_modules/**,dist/**,build/**,coverage/**,**/*.spec.ts,**/*.test.ts
- **ESLint Report:** .sonarq/eslint-report.json

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
