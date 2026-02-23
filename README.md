# Malnati/ops-sonarq

GitHub Action composta para executar analise SonarQube em um diretorio do repositorio, gerar relatorios em `path/.sonarq`, publicar artifact e abrir PR com os arquivos gerados.

## O que a action faz hoje

Fluxo implementado em `action.yml`:

1. Faz checkout do repositorio (`actions/checkout@v4`).
2. Define `scan_path` a partir de `inputs.path` (fallback `api`).
3. Detecta URL do SonarQube tentando:
   - `http://localhost:9000`
   - `http://sonarqube:9000`
   - `http://127.0.0.1:9000`
   - `http://host.docker.internal:9000`
4. Aguarda o SonarQube ficar `UP`.
5. Gera `sonar-project.properties` com `envsubst` a partir de `assets/sonar-project.properties.template`.
6. Baixa SonarScanner CLI e adiciona ao `PATH`.
7. Garante existencia de `path/src` (cria placeholder quando ausente).
8. Executa scan SonarQube com login/senha `admin/admin`.
9. Aguarda processamento da analise.
10. Extrai dados via API SonarQube para `path/.sonarq`.
11. Gera `REPORT.md` com `envsubst` usando `assets/sonarqube-report.md.template`.
12. Cria branch, commit e tenta abrir PR com os relatorios.
13. Publica artifact `sonarqube-report` com `actions/upload-artifact@v4`.

## Inputs

| Input | Required | Default | Description |
|---|---|---|---|
| `path` | yes | `api` | Path to scan |
| `project_key` | no | `nome-do-projeto` | Project key |
| `project_name` | no | `Nome do Projeto` | Project name |

## Outputs declarados

| Output | Description em `action.yml` |
|---|---|
| `json` | Generated JSON file path (array). |
| `report_path` | Generated JSON file path (array). |
| `status` | Scan status. |
| `count` | Number of literals found. |

Observacao importante: no estado atual do `action.yml`, os outputs apontam para `steps.generate_output.outputs.*`, mas nao existe step com `id: generate_output`.

## Arquivos gerados

No diretorio `path/.sonarq`:

- `quality-gate.json`
- `metrics.json`
- `issues.json`
- `hotspots.json`
- `analyses.json`
- `REPORT.md`

## Exemplo de uso

```yaml
name: sonarq

on:
  workflow_dispatch:

jobs:
  scan:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Run ops-sonarq
        uses: Malnati/ops-sonarq@v1.0.0
        with:
          path: api
          project_key: meu-projeto
          project_name: Meu Projeto
```

## Teste local via bash

```bash
bash assets/run.sh --path api --project-key meu-projeto --project-name "Meu Projeto"
```

## Dependencias e premissas reais

- O fluxo usa comandos `npm`, `curl`, `unzip`, `envsubst`, `git` e `gh`.
- O scanner e as APIs SonarQube estao configurados com `admin/admin`.
- O workflow espera templates em `assets/`:
  - `eslint.config.cjs.template`
  - `sonar-project.properties.template`
  - `sonarqube-report.md.template`

## Licenca

MIT.
