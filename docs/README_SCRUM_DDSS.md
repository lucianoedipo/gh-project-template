# Template SCRUM-DDSS-v1 para GitHub Projects

Este template implementa a estrutura de projeto ágil baseada no modelo SCRUM-DDSS-v1, utilizada pela **Divisão de Desenvolvimento e Sustentação de Sistemas (DDSS/CGTI/ANPD)**. Ele serve como referência para automação e padronização de projetos institucionais, conforme o Processo de Desenvolvimento de Software (PDS v1.0, jan/2025).

## 🎯 Objetivo

Padronizar campos, colunas e visualizações para uso institucional do GitHub Projects v2, alinhado ao Scrum, Pontos de Função (PF) e diretrizes da ANPD.

Este template pode ser reutilizado e customizado para outros times, projetos ou metodologias. Basta adaptar o arquivo de schema JSON e os scripts conforme a necessidade.

> **Exemplo de reuso:**
>
> - Para Kanban, basta alterar o campo de iteração e as colunas.
> - Para projetos sem PF, remova os campos relacionados.

Consulte os scripts e o schema para criar novas combinações!

## ⚙️ Estrutura Geral

### Iteração

- **Nome**: Sprint
- **Duração**: 14 dias corridos

> O campo de iteração é criado automaticamente pelo script, conforme definido no schema. Outros parâmetros como início e timezone devem ser ajustados manualmente no GitHub, se necessário.

## 🧱 Campos Personalizados

### 1. `Status` (single_select)

Define o estágio atual da issue:

- 📋 A Fazer
- 🟢 Pronto para iniciar
- 🚧 Em andamento
- 🔍 Em revisão
- 📤 Aguardando validação
- ✅ Concluído

### 2. `Tipo de Item` (single_select)

Classificação da natureza do item:

- HU - História de Usuário
- DE - Defeito
- ME - Melhoria
- TE - Requisito Técnico
- Épico

> 🔍 **Sprint não é um tipo de item.** Representa-se como uma issue especial, fora dessa classificação, para não poluir esse campo.

### 3. `Prioridade` (single_select)

Define urgência:

- 🔥 Urgente (P0)
- ⏱ Alta (P1)
- 📌 Normal (P2)
- 🧊 Baixa (P3)

### 4. `PF Estimado` (number)

Quantidade de Pontos de Função atribuída no planejamento.

### 5. `PF Validado` (number)

Quantidade de PF efetivamente entregue e homologada.

### 6. `Critérios de Aceitação` (text)

Critérios objetivos para que o item seja aceito como pronto.

### 7. `Definição de Pronto` (text)

Checklist técnico mínimo (ex: testes, versionamento, build).

> ⚠️ O GitHub não suporta campos tipo checklist. Recomenda-se uso de texto com markdown:
>
> ```
> - [x] Código versionado
> - [x] Testes unitários rodando
> - [x] Build documentado
> ```

### 8. `Validação do PO` (single_select)

Indica se o PO aprovou o item:

- ✅ Validado
- 🕗 Pendente
- ❌ Rejeitado

### 9. `Evidência de Teste` (text)

Link ou descrição de evidência funcional do item.

### 10. `Regra de Negócio` (text)

Texto livre para rastrear a lógica de negócio aplicada.

### 11. `Dependências` (text)

IDs ou links de issues bloqueadoras.

### 12. `Sprint (Issue ID)` (text)

Representa a Sprint à qual o item pertence (por referência manual à issue de Sprint).

> **Observação:** O campo de iteração nativo do GitHub pode ser usado em paralelo ou substituído por esse campo manual, conforme a necessidade do projeto.

## 🧾 Colunas do Projeto

1. 📋 Backlog do Produto
2. 🧾 Backlog da Sprint
3. ⚙️ Em andamento
4. 🔍 Em revisão
5. 📤 Aguardando validação
6. ✅ Feito

---

## 👁️ Visualizações Padrão

### 📅 Sprint Atual

- Filtro: `Sprint = atual`
- Group by: `Status`
- Campos: `Tipo de Item`, `PF Estimado`, `Validação do PO`, `Critérios de Aceitação`

### 📈 Métricas de Entrega

- Filtro: `PF Validado != null`
- Campos: `Sprint`, `PF Estimado`, `PF Validado`, `Status`

### 🔍 Itens Pendentes de Validação

- Filtro: `Validação do PO = 🕗 Pendente`
- Campos: `Status`, `Critérios de Aceitação`, `Evidência de Teste`

### 🗺️ Visão por Épico

- Filtro: `Tipo de Item = Épico`
- Group by: `Tipo de Item`
- Campos: `Status`, `PF Estimado`

---

## 📌 Decisões Estruturais

- 🔒 **Não usamos Story Points**: o processo da DDSS adota **Pontos de Função (PF)** como métrica exclusiva de esforço e faturamento.
- 🌀 **Sprint pode ser representada como uma issue ou pelo campo de iteração nativo**. Não faz parte do campo `Tipo de Item`.
- ✅ A vinculação de itens a sprints é feita por **campo manual (`Sprint (Issue ID)`)** ou **Iteration nativa**.

---

## ♻️ Reuso e Customização

Este template é totalmente adaptável. Para criar um novo modelo:

1. Edite o arquivo de schema JSON conforme sua metodologia.
2. Ajuste os scripts para importar os campos e colunas desejados.
3. Consulte a documentação dos módulos para exemplos de uso.

> **Dica:** Você pode criar múltiplos arquivos de schema e scripts para diferentes tipos de projeto e alternar conforme a demanda.

## 📚 Referência

- Processo de Desenvolvimento de Software – DDSS/CGTI/ANPD – Versão 1.0 – Jan/2025
- Scrum Guide – Novembro/2020
- Portaria SGD/MGI nº 750/2023

---

**Uso obrigatório para todos os projetos estruturados com planejamento por Sprint na DDSS.**
