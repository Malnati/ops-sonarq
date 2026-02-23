<!-- docs/README.md -->
<h1 align="center">ops-sonarq</h1>

<p align="center">
  <b>GitHub Action para análise de código com SonarQ, outputs idempotentes e reutilizáveis.</b>
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

