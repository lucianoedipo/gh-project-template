# Guia de Solução de Problemas

Este documento descreve problemas comuns que podem ocorrer ao usar a ferramenta GitHub Project Template e como resolvê-los.

## Problemas de Autenticação

### Erro: "Token não tem permissões suficientes"

**Sintomas:**

- Mensagem informando que seu token não tem todos os escopos necessários
- Não consegue listar ou criar projetos

**Solução:**

1. Siga as instruções interativas do script quando ele oferecer atualizar seu token
2. Opte por criar um novo token no navegador (opção recomendada)
3. Certifique-se de que seu novo token inclui todos os escopos necessários:
   - `repo`
   - `admin:org`
   - `project`
   - `read:project`

Para instruções detalhadas, consulte `docs/autenticacao.md`.

### Erro: "Missing required scopes [read:project]"

**Sintomas:**

- Não consegue listar projetos existentes
- Recebe a mensagem "Missing required scopes [read:project]"

**Solução:**

1. Escolha uma das opções oferecidas pelo script:
   - Abrir o navegador para criar um novo token com o escopo `read:project`
   - Informar manualmente o ID ou número do projeto
   - Criar um novo projeto

### Comando `gh auth refresh` travando

**Sintomas:**

- O processo fica parado após executar `gh auth refresh`
- Nenhuma saída ou resposta do comando

**Solução:**

1. Pressione CTRL+C para cancelar o processo
2. Use o método recomendado de login:
   ```
   gh auth logout
   gh auth login
   ```
3. Escolha a opção para colar um token quando solicitado

## Problemas com Campos e Visualizações

### Erro: "Name has already been taken"

**Sintomas:**

- Mensagens de erro ao tentar criar campos personalizados
- O campo já existe no projeto

**Solução:**

- Este é um comportamento normal. O script tenta reutilizar campos existentes.
- Verifique se o campo existente tem as propriedades corretas (especialmente em campos do tipo single_select).

### Visualizações (Views) não são criadas automaticamente

**Sintomas:**

- O script conclui com sucesso, mas as visualizações não aparecem no projeto

**Causa:**

- A API do GitHub não permite criar views programaticamente

**Solução:**

- Siga as instruções em `docs/criar-views-manual.md` para criar as views manualmente
- Execute `.\scripts\check-views.ps1` para verificar quais views precisam ser criadas

### Campo de Iteração (Sprint) não está configurado corretamente

**Sintomas:**

- O campo de iteração não tem a duração correta
- As iterações não aparecem no campo

**Solução:**

- O campo de iteração requer configuração manual adicional
- Siga as instruções em `docs/campos-especiais.md` para configurar o campo corretamente

## Problemas de Execução do Script

### Erro: "Cannot import module"

**Sintomas:**

- Mensagens de erro ao tentar importar módulos
- Funções não são reconhecidas

**Solução:**

1. Certifique-se de estar executando o script do diretório raiz do projeto
2. Verifique se todos os módulos estão presentes na pasta `modules/`
3. Execute com PowerShell em modo administrativo se necessário

### Erro com caminhos de arquivo incorretos

**Sintomas:**

- Mensagens de erro mencionando arquivos não encontrados
- Referências a caminhos com `..` ou caminhos incorretos

**Solução:**

1. Execute o script do diretório raiz do projeto
2. Verifique se a estrutura de diretórios está completa e correta

## Ajuda Adicional

Se você encontrar problemas não listados aqui:

1. Verifique os logs em `.\logs\setup.log` para obter detalhes
2. Consulte a documentação específica em `.\docs\`
3. Execute o script com o parâmetro `-Help` para ver todas as opções disponíveis
