# Templates de Issues

Este diretório contém os templates de issues para o projeto GitHub Project Template.

## Formatos Suportados

O GitHub suporta dois formatos para templates de issues:

1. **Formato YAML (`.yml`)** - Formato recomendado atual com formulários estruturados

   - Exemplo: `bug_report.yml`, `feature_request.yml`
   - Permite campos obrigatórios, dropdowns, validações, etc.

2. **Formato Markdown (`.md`)** - Formato anterior mais simples
   - Exemplo: `bug_report_md.md`, `feature_request_md.md` (note o sufixo `_md` para evitar conflitos de nome)
   - Apenas texto formatado sem validações ou campos estruturados

## Estrutura Atual

Atualmente, este projeto usa ambos os formatos:

### Templates YAML (Recomendados)

- `bug_report.yml` - Template para reportar bugs
- `feature_request.yml` - Template para solicitar novas funcionalidades
- `documentation.yml` - Template para melhorias na documentação
- `template_request.yml` - Template para solicitar novos templates de projeto
- `basic_issue.yml` - Template básico para issues gerais

### Templates Markdown (Formato Alternativo)

- `bug_report_md.md` - Versão markdown para reportar bugs
- `feature_request_md.md` - Versão markdown para solicitar funcionalidades
- `documentation_md.md` - Versão markdown para documentação
- `template_request_md.md` - Versão markdown para solicitar templates

## Configuração Central

O arquivo `config.yml` neste diretório configura o comportamento geral dos templates de issues,
como desativar issues em branco e adicionar links para documentação.

## Nota sobre Nomenclatura

Os templates Markdown devem ter nomes diferentes dos templates YAML, por isso usamos o sufixo `_md`. O GitHub não permite ter dois templates com o mesmo nome base, mesmo que tenham extensões diferentes.
