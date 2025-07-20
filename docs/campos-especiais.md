# Campos Especiais no GitHub Projects

Este documento explica como configurar campos especiais no GitHub Projects que não podem ser criados automaticamente via API, com foco no template SCRUM-DDSS-v1. As instruções podem ser adaptadas para outros templates e cenários.

## Campo de Iteração (Sprint)

A API GraphQL do GitHub não suporta a criação programática de campos de iteração. Portanto, este campo deve ser criado manualmente na interface web do GitHub Projects.

### Como criar um campo de Iteração

1. Acesse seu projeto no GitHub
2. No canto superior direito, clique em "+" e selecione "Novo campo"
3. Escolha "Iteração" na lista de tipos de campo
4. Configure o campo:
   - **Nome**: Sprint (ou o nome definido no seu schema)
   - **Duração**: 14 dias (ou conforme definido no seu schema)
5. Clique em "Salvar"

### Como adicionar iterações

1. Após criar o campo, clique no campo de iteração no cabeçalho do projeto
2. Clique em "Gerenciar iterações"
3. Clique em "Nova iteração"
4. Digite o título (ex: "Sprint 1", "Sprint 2", ...)
5. Defina a data de início ("Start on")
6. Selecione a duração (ex: 14 dias)
7. Clique em "Criar"
8. Repita para criar as próximas sprints conforme o planejamento

### Limitações

- A API GraphQL do GitHub **não suporta** a criação programática de campos de iteração
- O campo e as iterações devem ser criados manualmente pela interface web
- Após criado, o campo pode ser consultado via API, mas não alterado ou recriado

### Dicas

- Crie várias iterações antecipadamente para facilitar o planejamento
- Use um padrão consistente para nomear as sprints (ex: "Sprint 1", "Sprint 2", ...)
- Mantenha as iterações em sequência, sem intervalos entre elas
- Adapte o nome e duração conforme o schema do seu template

## Uso do campo de Iteração

- **Atribuir itens a uma iteração**: Selecione a iteração no campo correspondente de cada item
- **Filtrar por iteração**: Use o filtro do campo de iteração para visualizar apenas itens de uma sprint específica
- **Relatórios**: Analise a conclusão de itens por sprint para medir a velocidade da equipe

---

> Este procedimento pode ser adaptado para outros templates e tipos de campo especial. Consulte o schema do seu projeto para ajustar nome e duração conforme necessário.
