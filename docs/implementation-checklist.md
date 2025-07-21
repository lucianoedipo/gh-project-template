# Checklist de Implementação

Este documento contém uma lista de verificação para garantir que todos os componentes do projeto estejam corretamente implementados.

## Templates de Issues

Para verificar se os templates de issues estão funcionando corretamente:

1. **Verifique a estrutura de diretórios**:

   - Confirme que existe o diretório `.github/ISSUE_TEMPLATE/`
   - Verifique se os arquivos de template estão presentes neste diretório

2. **Verifique se os arquivos foram commitados e enviados para o GitHub**:

   ```bash
   git status
   # Deve mostrar que não há alterações pendentes nos arquivos de template

   git log -- .github/ISSUE_TEMPLATE/
   # Deve mostrar commits relacionados aos arquivos de template
   ```

3. **Verifique o formato dos arquivos de template**:

   - Templates YAML (`.yml`) devem conter os campos obrigatórios: `name`, `description`, `title`, `body`
   - Templates Markdown (`.md`) devem conter o front matter YAML com campos obrigatórios

4. **Teste localmente**:

   ```bash
   # Validar os arquivos YAML
   npx yaml-validator .github/ISSUE_TEMPLATE/*.yml
   ```

5. **Commit e Push**:

   ```bash
   git add .github/
   git commit -m "Add issue templates"
   git push origin main
   ```

6. **Verifique no GitHub**:
   - Navegue até seu repositório no GitHub
   - Clique na aba "Issues"
   - Clique no botão "New issue"
   - Verifique se os templates aparecem

## Soluções para Problemas Comuns

### Templates não aparecem

1. **Problema de cache do navegador**:

   - Limpe o cache do navegador ou tente em uma janela anônima/privada

2. **Arquivos não enviados para o GitHub**:

   - Verifique se os arquivos foram commitados e enviados para o branch correto

3. **Problemas de formato**:

   - Certifique-se de que não há erros de sintaxe nos arquivos YAML
   - Verifique se todos os campos obrigatórios estão presentes

4. **Configuração incorreta**:

   - Verifique se o arquivo `config.yml` está configurado corretamente
   - Garanta que os arquivos de template estão no diretório `.github/ISSUE_TEMPLATE/`

5. **Permissões do repositório**:
   - Verifique se você tem permissão para gerenciar as configurações do repositório
