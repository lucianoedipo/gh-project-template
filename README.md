# GitHub Project Template Automation

Este repositório contém scripts para automatizar a criação e configuração de projetos GitHub baseados em templates pré-definidos.

## Visão Geral

Os scripts neste repositório permitem:

1. Criar novos projetos GitHub
2. Configurar campos personalizados
3. Configurar colunas de status (quadro Kanban)
4. Verificar e guiar a configuração manual de visualizações (views)

## Pré-requisitos

- PowerShell 5.1 ou superior
- [GitHub CLI](https://cli.github.com/) instalado e autenticado
- Permissões de administrador no GitHub (pessoal ou organização)

## Guia Rápido

### Configuração Completa (Recomendado)

Para criar e configurar um novo projeto do zero:

```powershell
.\setup-project.ps1
```

Este script guiará você através do processo completo, desde a seleção do proprietário (você ou sua organização) até a criação e configuração do projeto.

### Scripts Individuais

Se preferir executar etapas específicas:

1. **Criar campos personalizados**:

   ```powershell
   .\import-fields.ps1 -projectId SEU_ID_PROJETO
   ```

2. **Configurar colunas de status**:

   ```powershell
   .\import-status-columns.ps1 -projectId SEU_ID_PROJETO
   ```

3. **Verificar status das views**:
   ```powershell
   .\check-views.ps1 -projectId SEU_ID_PROJETO
   ```

## Uso com Projetos Existentes

Para configurar um projeto já existente:

```powershell
# Usando seleção interativa
.\setup-project.ps1 -useExisting

# Usando ID do projeto
.\setup-project.ps1 -projectId "PVT_kw..."

# Usando número do projeto e proprietário
.\setup-project.ps1 -owner "minha-org" -projectNumber 42
```

Isso permite aplicar o template a projetos existentes sem precisar criar um novo projeto.

## Estrutura de Arquivos

- `setup-project.ps1` - Script principal para criar e configurar projetos
- `import-fields.ps1` - Configura campos personalizados
- `import-status-columns.ps1` - Configura colunas de status (Kanban)
- `check-views.ps1` - Verifica status das visualizações
- `templates/` - Arquivos JSON de templates de projeto
  - `project-schema.scrum-ddss.v1.json` - Template SCRUM para equipes DDSS
- `docs/` - Documentação detalhada
  - `criar-views-manual.md` - Guia para criação manual de views
- `projects/` - Armazena detalhes de projetos criados (gerado automaticamente)

## Templates Disponíveis

### SCRUM-DDSS v1

Template otimizado para equipes SCRUM que inclui:

- Configuração de Sprints (iterações de 2 semanas)
- Campos para pontos de função (PF)
- Fluxo de validação do Product Owner
- Views específicas para acompanhamento de Sprint e métricas

## Personalização de Templates

Você pode personalizar ou criar novos templates editando os arquivos JSON na pasta `templates/`. Cada template contém:

- Configuração de campos personalizados
- Opções de status (colunas do quadro)
- Definições de visualizações (views)
- Configuração de iterações (sprints)

## Limitações Conhecidas

- A API do GitHub não permite criar ou atualizar views programaticamente
- As views precisam ser criadas manualmente conforme documentado em `docs/criar-views-manual.md`
- Campos existentes com o mesmo nome podem causar conflitos

## Suporte

Para problemas ou sugestões, crie uma issue neste repositório.
