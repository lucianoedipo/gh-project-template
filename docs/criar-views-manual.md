# Guia para Criar Visualizações Manualmente no GitHub Projects

## Introdução

A API GraphQL do GitHub não suporta a criação ou atualização programática de visualizações (views) em Projects. Este guia traz instruções detalhadas para criar manualmente as views conforme o template SCRUM-DDSS-v1, mas pode ser adaptado para outros templates e combinações.

## Pré-requisitos

- Acesso administrativo ao GitHub Project
- ID do projeto no formato `PVT_xxxxxx`
- Template de projeto já aplicado com campos personalizados configurados

## Verificação de Visualizações Existentes

Execute o script abaixo para identificar quais views já existem e quais precisam ser criadas:

```powershell
.\check-views.ps1 -projectId SEU_ID_PROJETO
```

## Instruções Gerais para Criar uma Visualização

1. Acesse seu projeto no GitHub: `https://github.com/orgs/SEU_USUARIO_OU_ORG/projects/SEU_PROJETO`
2. Clique em "➕ Nova visualização" no canto superior direito
3. Selecione "Tabela" como tipo de visualização
4. Dê o nome exato conforme especificado no schema
5. Configure agrupamento, ordenação, campos visíveis e filtros conforme as instruções abaixo

## Visualizações Específicas

### 1. 📅 Sprint Atual

**Nome exato:** `📅 Sprint Atual`

**Configuração:**

- **Agrupamento:** Agrupar por "Status"
- **Ordenação:** "Sprint (Issue ID)" em ordem crescente
- **Campos visíveis:**
  - Tipo de Item
  - PF Estimado
  - Validação do PO
  - Critérios de Aceitação
- **Filtro:** Itens da sprint atual (configure manualmente selecionando o valor atual)

**Passos detalhados:**

1. Clique em "➕ Nova visualização" > "Tabela"
2. Nomeie como "📅 Sprint Atual"
3. Clique no menu "..." da view e selecione "Configurar visualização"
4. Em "Agrupar por", selecione "Status"
5. Em "Ordenar por", adicione "Sprint (Issue ID)" e selecione "Crescente"
6. Em "Configurações de campos", marque apenas:
   - Tipo de Item
   - PF Estimado
   - Validação do PO
   - Critérios de Aceitação
7. Para filtrar por sprint atual, clique no botão de filtro (funil) e configure um filtro para "Sprint (Issue ID)" igual ao valor da sprint atual

### 2. 📈 Métricas de Entrega

**Nome exato:** `📈 Métricas de Entrega`

**Configuração:**

- **Ordenação:** "PF Validado" em ordem decrescente
- **Campos visíveis:**
  - Sprint (Issue ID)
  - PF Estimado
  - PF Validado
  - Status
- **Filtro:** Apenas itens com PF Validado preenchido

**Passos detalhados:**

1. Clique em "➕ Nova visualização" > "Tabela"
2. Nomeie como "📈 Métricas de Entrega"
3. Clique no menu "..." da view e selecione "Configurar visualização"
4. Em "Ordenar por", adicione "PF Validado" e selecione "Decrescente"
5. Em "Configurações de campos", marque apenas:
   - Sprint (Issue ID)
   - PF Estimado
   - PF Validado
   - Status
6. Para filtrar, clique no botão de filtro (funil) e configure um filtro para "PF Validado" diferente de vazio

### 3. 🔍 Itens Pendentes de Validação

**Nome exato:** `🔍 Itens Pendentes de Validação`

**Configuração:**

- **Ordenação:** "Status" em ordem crescente
- **Campos visíveis:**
  - Status
  - Critérios de Aceitação
  - Evidência de Teste
- **Filtro:** "Validação do PO" igual a "🕗 Pendente"

**Passos detalhados:**

1. Clique em "➕ Nova visualização" > "Tabela"
2. Nomeie como "🔍 Itens Pendentes de Validação"
3. Clique no menu "..." da view e selecione "Configurar visualização"
4. Em "Ordenar por", adicione "Status" e selecione "Crescente"
5. Em "Configurações de campos", marque apenas:
   - Status
   - Critérios de Aceitação
   - Evidência de Teste
6. Para filtrar, clique no botão de filtro (funil) e configure um filtro para "Validação do PO" igual a "🕗 Pendente"

### 4. 🗺️ Visão por Épico

**Nome exato:** `🗺️ Visão por Épico`

**Configuração:**

- **Agrupamento:** Agrupar por "Tipo de Item"
- **Ordenação:** "PF Estimado" em ordem decrescente
- **Campos visíveis:**
  - Status
  - PF Estimado
- **Filtro:** "Tipo de Item" igual a "Épico"

**Passos detalhados:**

1. Clique em "➕ Nova visualização" > "Tabela"
2. Nomeie como "🗺️ Visão por Épico"
3. Clique no menu "..." da view e selecione "Configurar visualização"
4. Em "Agrupar por", selecione "Tipo de Item"
5. Em "Ordenar por", adicione "PF Estimado" e selecione "Decrescente"
6. Em "Configurações de campos", marque apenas:
   - Status
   - PF Estimado
7. Para filtrar, clique no botão de filtro (funil) e configure um filtro para "Tipo de Item" igual a "Épico"

## Verificando a Configuração

Após criar todas as visualizações, execute novamente o script de verificação para confirmar que todas foram criadas corretamente:

```powershell
.\check-views.ps1 -projectId SEU_ID_PROJETO
```

O relatório deve mostrar todas as views como "Encontradas".

---

> Este guia pode ser adaptado para outros templates e combinações de campos. Basta seguir a mesma lógica e ajustar os nomes e filtros conforme o schema do seu projeto.
