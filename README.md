
<!-- README.md -->
<h1 align="center">Malnati/ops-sonarq</h1>

<p align="center">
  <b>Scan with idempotence. GitHub Action para análise de código com SonarQ.</b>
</p>

<p align="center">
  <a href="https://github.com/Malnati/ops-sonarq/releases">
    <img alt="Release" src="https://img.shields.io/github/v/release/Malnati/ops-sonarq?include_prereleases" />
  </a>
  <a href="https://github.com/Malnati/ops-sonarq/blob/main/LICENSE">
    <img alt="License" src="https://img.shields.io/badge/license-MIT-green" />
  </a>
  <img alt="Marketplace" src="https://img.shields.io/badge/marketplace-coming%20soon-lightgrey" />
</p>

<p align="center">
  <a href="https://github.com/Malnati/ops-sonarq"><b>Repository</b></a>
  •
  <a href="https://github.com/Malnati/ops-sonarq/issues"><b>Issues</b></a>
</p>

<hr/>


## O que é?

**ops-sonarq** é uma GitHub Action que executa análise de código com SonarQ, de forma idempotente, exportando resultados como outputs reutilizáveis no workflow.

Ideal para automações CI/CD que precisam garantir análise consistente e outputs prontos para uso em etapas seguintes.

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

- ✅ Escaneia o diretório informado (`path`)

## Exemplo de uso

```yaml
- name: "🔎 Scan com ops-sonarq"
  uses: Malnati/ops-sonarq@v1.0.0
  with:
    path: "api" # diretório a ser escaneado
    project_key: "meu-projeto"
    project_name: "Meu Projeto"
```

### Entradas

| Input        | Obrigatório | Default            | Descrição                |
|--------------|-------------|--------------------|--------------------------|
| path         | sim         | "api"              | Caminho a ser escaneado  |
| project_key  | não         | "nome-do-projeto"  | Chave do projeto SonarQ  |
| project_name | não         | "Nome do Projeto"  | Nome do projeto SonarQ   |

### Saídas

| Output      | Descrição                                 |
|-------------|-------------------------------------------|
| json        | Caminho do arquivo JSON gerado (array)    |
| report_path | Caminho do relatório gerado (array)       |
| status      | Status do scan                            |
| count       | Quantidade de literais encontradas        |

### Licença

MIT. Veja LICENSE.
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
