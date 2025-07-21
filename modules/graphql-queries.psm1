# Armazena todas as consultas GraphQL usadas pelo script

# Definindo variáveis no escopo de script com prefixo para evitar conflitos
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
      __typename
    }
  }
}
'@

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
          __typename
        }
      }
    }
  }
}
'@

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

# Corrigir a mutação para campos de iteração - o formato atual está incorreto
$script:createIterationFieldMutation = @'
mutation CreateIterationField($projectId: ID!, $name: String!) {
  createProjectV2Field(input: {
    projectId: $projectId,
    dataType: ITERATION,
    name: $name
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

# Garantir que todas as consultas sejam exportadas
Export-ModuleMember -Variable createFieldMutation, getFieldsQuery, addOptionMutation, createIterationMutation, createIterationFieldMutation, findStatusFieldQuery, updateStatusOptionsMutation