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
   - `read:project` (para listar projetos existentes)

   Para instruções detalhadas de autenticação, consulte `docs/autenticacao.md`.

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

2. Para problemas de autenticação, o script oferece métodos interativos para:

   - Atualizar escopos de token existente (quando possível)
   - Criar um novo token com as permissões corretas
   - Informar ID ou número do projeto manualmente se não puder listar projetos

3. **NOTA IMPORTANTE**: Evite usar `gh auth login --with-token` diretamente, pois pode travar em alguns ambientes. Use o método interativo recomendado:
   ```
   gh auth logout
   gh auth login
   # Escolha a opção para colar um token quando solicitado
   ```

## Documentação

Os seguintes documentos estão disponíveis para ajudar no uso da ferramenta:

- `docs/autenticacao.md` - Guia completo de autenticação e resolução de problemas de permissão
- `docs/campos-especiais.md` - Como configurar campos que exigem etapas manuais (ex: Iteração/Sprint)
- `docs/criar-views-manual.md` - Instruções para criar views personalizadas (não automatizável pela API)
- `docs/README_SCRUM_DDSS.md` - Documentação do template SCRUM-DDSS

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
- O comando `gh auth refresh` pode travar em alguns ambientes

## Suporte

Para problemas ou sugestões, crie uma issue neste repositório.

- Opções de status (colunas do quadro)
- Definições de visualizações (views)
- Configuração de iterações (sprints)

## Limitações Conhecidas

- A API do GitHub não permite criar ou atualizar views programaticamente
- As views precisam ser criadas manualmente conforme documentado em `docs/criar-views-manual.md`
- Campos existentes com o mesmo nome podem causar conflitos

## Suporte

Para problemas ou sugestões, crie uma issue neste repositório.
