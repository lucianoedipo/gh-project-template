# Modelo de Projeto SCRUM-DDSS-v1 para GitHub Projects

Este repositório define a estrutura padronizada do **Projeto Ágil baseado em Scrum híbrido** da **Divisão de Desenvolvimento e Sustentação de Sistemas (DDSS/CGTI/ANPD)**, conforme definido no documento oficial do Processo de Desenvolvimento de Software (PDS v1.0, jan/2025).

## 🎯 Objetivo

Formalizar a estrutura de campos, colunas e visualizações para o uso institucional de GitHub Projects v2, garantindo alinhamento com:

- Princípios do Scrum
- Práticas contratuais com métrica de Pontos de Função (PF)
- Normativas do setor público e diretrizes da ANPD

---

## ⚙️ Estrutura Geral

### Iteração

- **Nome**: Sprint
- **Duração**: 14 dias corridos
- **Início**: Segunda-feira
- **Timezone**: America/Sao_Paulo

---

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

---

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
- 🌀 **Sprint é representada como uma issue**, com checklist de itens. Não faz parte do campo `Tipo de Item`.
- ✅ A vinculação de itens a sprints é feita por **campo manual (`Sprint (Issue ID)`)** ou **Iteration nativa**.

---

## 📚 Referência

- Processo de Desenvolvimento de Software – DDSS/CGTI/ANPD – Versão 1.0 – Jan/2025
- Scrum Guide – Novembro/2020
- Portaria SGD/MGI nº 750/2023

---

**Uso obrigatório para todos os projetos estruturados com planejamento por Sprint na DDSS.**
