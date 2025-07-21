# Verificação de Templates de Issues

Para verificar se os templates de issues estão configurados corretamente:

1. Navegue até a página principal do repositório no GitHub
2. Clique no botão "Issues"
3. Clique em "New issue"
4. Você deve ver os seguintes templates disponíveis:
   - 🐛 Reportar um Bug
   - 💡 Solicitação de Recurso
   - 📚 Melhoria de Documentação
   - 🧩 Solicitar Novo Template

Se os templates não aparecerem:

1. Verifique se todos os arquivos `.yml` e `.md` estão na pasta `.github/ISSUE_TEMPLATE/`
2. Confirme que o arquivo `config.yml` está configurado corretamente
3. Certifique-se de que o formato YAML dos templates está correto e possui os campos obrigatórios:
   - `name`
   - `description`
   - `title`
   - `labels` (opcional, mas recomendado)
   - `body` com os campos apropriados

Para mais informações sobre configuração de templates de issues, consulte:
https://docs.github.com/en/communities/using-templates-to-encourage-useful-issues-and-pull-requests
