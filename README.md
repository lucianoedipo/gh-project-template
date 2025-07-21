# GitHub Project Template

Uma ferramenta para configuração automatizada de projetos GitHub Projects com campos personalizados e status baseados em templates.

## Pré-requisitos

1. **GitHub CLI**: Você precisa ter o GitHub CLI instalado.

   ```
   winget install GitHub.cli
   ```

   ou visite [cli.github.com](https://cli.github.com/) para instruções de instalação.

2. **Token de Acesso com Permissões Adequadas**

   ⚠️ **IMPORTANTE**: Este script requer um token de acesso pessoal com permissões específicas:

   - `repo` (acesso completo aos repositórios)
   - `admin:org` (para gerenciar projetos organizacionais)
   - `project` (acesso aos projetos)

   **Como criar um token de acesso pessoal**:

   1. Acesse [GitHub > Settings > Developer settings > Personal access tokens > Tokens (classic)](https://github.com/settings/tokens)
   2. Clique em "Generate new token" e selecione "Generate new token (classic)"
   3. Dê um nome ao seu token (ex: "GitHub Projects Setup")
   4. Selecione os escopos necessários: `repo`, `admin:org`, `project`
   5. Clique em "Generate token"
   6. **Importante**: Copie o token gerado imediatamente e guarde-o em local seguro!

   **Autenticação com o token**:

   ```powershell
   # Opção 1: Autenticação interativa (recomendada para início)
   gh auth login

   # Opção 2: Autenticação direta com token
   gh auth login --with-token < seu_arquivo_token.txt
   ```

## Uso Básico

```powershell
# Exibir ajuda detalhada
.\setup-project.ps1 -Help

# Listar templates disponíveis
.\setup-project.ps1 -ListSchemas

# Criar um novo projeto com template específico
.\setup-project.ps1 -title "Meu Projeto Scrum" -schemaPath ".\templates\scrum-template.json"

# Usar projeto existente
.\setup-project.ps1 -useExisting -projectNumber 123 -owner "sua-organizacao" -schemaPath ".\templates\scrum-template.json"
```

## Resolução de Problemas

Se encontrar erros de permissão durante a execução:

1. Verifique se você está autenticado corretamente:

   ```
   gh auth status
   ```

2. Caso já esteja autenticado, mas encontre erros de permissão, pode ser necessário gerar um novo token com as permissões corretas:

   ```
   gh auth logout
   gh auth login
   ```

3. Selecione a opção de GitHub.com e autenticação via token, inserindo um novo token com todas as permissões necessárias.

## Mais Informações

Consulte a documentação em `.\docs\` para instruções detalhadas sobre cada aspecto da ferramenta.

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
