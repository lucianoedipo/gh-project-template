# Armazena todas as consultas GraphQL usadas pelo script

# Criação de campo genérico
$script:createFieldMutation = @'
mutation CreateField($input: CreateProjectV2FieldInput!) {
  createProjectV2Field(input: $input) {
    projectV2Field {
      ... on ProjectV2SingleSelectField {
        id
        name
        dataType
      }
      ... on ProjectV2IterationField {
        id
        name
        dataType
      }
      # Add other field types if your schema supports them (e.g., ProjectV2Field)
      __typename
    }
  }
}
'@

# Consulta de campos existentes
$script:getFieldsQuery = @'
query GetFields($projectId: ID!) {
  node(id: $projectId) {
    ... on ProjectV2 {
      fields(first: 100) {
        nodes {
          ... on ProjectV2SingleSelectField {
            id
            name
            dataType
            options {
              name
              description
              color
            }
          }
          ... on ProjectV2IterationField {
            id
            name
            dataType
            configuration {
                duration
                startDay
            }
          }
          # Add other field types if your schema supports them
          __typename
        }
      }
    }
  }
}
'@

# Adicionar opção a um campo de seleção única
$script:addOptionMutation = @'
mutation AddOption($fieldId: ID!, $name: String!, $description: String!, $color: ProjectV2SingleSelectFieldOptionColor!) {
  addProjectV2SingleSelectFieldOption(input: {
    fieldId: $fieldId,
    name: $name,
    description: $description,
    color: $color
  }) {
    singleSelectFieldOption {
      id
      name
    }
  }
}
'@

# Criar uma iteração (sprint)
$script:createIterationMutation = @'
mutation CreateIteration($iterationFieldId: ID!, $title: String!, $startDate: Date!, $duration: Int!) {
  createProjectV2Iteration(input: {
    projectV2IterationFieldId: $iterationFieldId,
    title: $title,
    duration: $duration,
    startDate: $startDate
  }) {
    iteration {
      id
      title
      startDate
      duration
    }
  }
}
'@

# Criar campo de iteração
$script:createIterationFieldMutation = @'
mutation CreateIterationField($projectId: ID!, $name: String!, $duration: Int!, $startDay: ProjectV2IterationFieldStartDay!) {
  createProjectV2IterationField(input: {
    projectId: $projectId,
    name: $name,
    configuration: {
      duration: $duration,
      startDay: $startDay # Mapeia para o enum GraphQL
    }
  }) {
    projectV2Field {
      ... on ProjectV2IterationField {
        id
        name
      }
    }
  }
}
'@

# Query para encontrar o campo Status no projeto
$script:findStatusFieldQuery = @'
query($projectId: ID!) {
  node(id: $projectId) {
    ... on ProjectV2 {
      field(name: "Status") {
        ... on ProjectV2SingleSelectField {
          id
          name
          options {
            id
            name
          }
        }
      }
    }
  }
}
'@

# Mutation para atualizar as opções do campo Status
$script:updateStatusOptionsMutation = @'
mutation($fieldId: ID!, $options: [ProjectV2SingleSelectFieldOptionInput!]) {
  updateProjectV2Field(
    input: {
      fieldId: $fieldId
      singleSelectOptions: $options
    }
  ) {
    projectV2Field {
      ... on ProjectV2SingleSelectField {
        id
        name
        options {
          id
          name
          color
        }
      }
    }
  }
}
'@
