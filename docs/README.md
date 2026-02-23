# ops-sonarq docs

Esta documentacao reflete o comportamento atual de `action.yml`.

## Resumo

`ops-sonarq` e uma GitHub Action composta que:

- executa scan no SonarQube para o `path` informado;
- gera relatorios em `path/.sonarq`;
- faz commit em branch dedicada e tenta abrir PR;
- publica artifact `sonarqube-report`.

## Inputs

| Input | Required | Default | Description |
|---|---|---|---|
| `path` | yes | `api` | Path to scan |
| `project_key` | no | `nome-do-projeto` | Project key |
| `project_name` | no | `Nome do Projeto` | Project name |

## Outputs declarados

| Output | Description |
|---|---|
| `json` | Generated JSON file path (array). |
| `report_path` | Generated JSON file path (array). |
| `status` | Scan status. |
| `count` | Number of literals found. |

Nota: os outputs acima estao declarados, mas hoje dependem de `steps.generate_output` que nao existe no fluxo.

## Relatorios gerados

Diretorio: `path/.sonarq`

- `quality-gate.json`
- `metrics.json`
- `issues.json`
- `hotspots.json`
- `analyses.json`
- `REPORT.md`

## Exemplo

```yaml
- name: Run ops-sonarq
  uses: Malnati/ops-sonarq@v1.0.0
  with:
    path: api
    project_key: meu-projeto
    project_name: Meu Projeto
```
