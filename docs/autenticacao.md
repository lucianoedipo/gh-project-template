# Guia de Autenticação para GitHub Projects Setup

Este guia explica como configurar a autenticação correta para usar as ferramentas de automação de projetos GitHub.

## Requisitos de Permissão

Para usar completamente as funcionalidades de automação de projetos, você precisa de um token com os seguintes escopos:

- `repo` (acesso completo aos repositórios)
- `admin:org` (para gerenciar projetos organizacionais)
- `project` (acesso aos projetos)
- `read:project` (para listar projetos existentes)

## Método Recomendado de Autenticação

### 1. Criar um Token de Acesso Pessoal

1. Acesse [GitHub > Settings > Developer settings > Personal access tokens > Tokens (classic)](https://github.com/settings/tokens)
2. Clique em "Generate new token" e selecione "Generate new token (classic)"
3. Dê um nome ao seu token (ex: "GitHub Projects Setup")
4. Selecione os escopos necessários:
   - `repo` (selecione todo o grupo)
   - `admin:org` (selecione todo o grupo)
   - `project` (selecione todo o grupo)
5. Clique em "Generate token"
6. **IMPORTANTE**: Copie o token gerado imediatamente e guarde-o em local seguro!

### 2. Fazer Login com o Método Interativo

Após criar o token, faça login usando o método interativo (evite o modo `--with-token` que pode travar):

```powershell
# Execute no terminal:
gh auth login

# Selecione as seguintes opções:
# - Onde você usa GitHub? GitHub.com
# - Qual protocolo preferido? HTTPS
# - Autenticar Git com credenciais GitHub? Yes
# - Como autenticar GitHub CLI? Paste an authentication token
# - Cole seu token quando solicitado
```

## Verificando suas Permissões

Para verificar se seu token tem as permissões corretas:

```powershell
gh auth status
```

Isso mostrará os escopos atuais do seu token. Certifique-se de que inclui `repo`, `admin:org` e `project`.

## Resolução de Problemas

### Token sem Permissões Suficientes

Se o script indicar que seu token não tem permissões necessárias:

1. **Não use** `gh auth refresh` - pode travar em alguns ambientes
2. É melhor fazer logout e login novamente com um novo token:

```powershell
# Sair da sessão atual
gh auth logout

# Fazer login novamente (método interativo)
gh auth login
# Escolha a opção de colar um token e use um novo token com todas as permissões
```

### Token sem Acesso para Listar Projetos

Se você receber erro como "missing required scopes [read:project]":

1. Crie um novo token com todos os escopos necessários
2. Faça logout e login novamente com o novo token
3. Alternativamente, você pode informar o ID ou número do projeto manualmente no script

### Comandos Úteis

```powershell
# Ver status atual
gh auth status

# Fazer logout
gh auth logout

# Fazer login (recomendado)
gh auth login
```
