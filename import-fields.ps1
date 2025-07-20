param(
    [string]$projectId,
    [string]$schemaPath = ".\templates\project-schema.scrum-ddss.v1.json"
)
if (-not $projectId) {
    Write-Error "O ID do projeto é obrigatório. Use: .\import-status-columns.ps1 -projectId SEU_ID_AQUI"
    return
}
Write-Host "🚀 Iniciando a configuração das colunas (Status) para o projeto: $projectId"

if (-not (Test-Path $schemaPath)) {
    Write-Error "Arquivo de schema não encontrado em: $schemaPath"
    return
}
$schema = Get-Content -Path $schemaPath | ConvertFrom-Json

# Filtra os campos, excluindo "Status" que é tratado por outro script
$fields = $schema.fields | Where-Object { $_.name -ne "Status" }

$createFieldMutation = @'
mutation CreateField($input: CreateProjectV2FieldInput!) {
  createProjectV2Field(input: $input) {
    projectV2Field {
      ... on ProjectV2SingleSelectField {
        id
        name
      }
    }
  }
}
'@

$getFieldsQuery = @'
query GetFields($projectId: ID!) {
  node(id: $projectId) {
    ... on ProjectV2 {
      fields(first: 100) {
        nodes {
          ... on ProjectV2SingleSelectField {
            id
            name
            options {
              name
            }
          }
        }
      }
    }
  }
}
'@

$addOptionMutation = @'
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

foreach ($field in $fields) {
    $input = @{
        projectId = $projectId
        name      = $field.name
    }

    switch ($field.type) {
        "single_select" {
            $input.dataType = "SINGLE_SELECT"
            $input.singleSelectOptions = $field.options
        }
        "number" {
            $input.dataType = "NUMBER"
        }
        default {
            $input.dataType = "TEXT"
        }
    }

    $createPayload = @{
        query     = $createFieldMutation
        variables = @{ input = $input }
    } | ConvertTo-Json -Depth 10 -Compress

    $response = $createPayload | gh api graphql --input - --header "Content-Type: application/json"
    $resultObj = $response | ConvertFrom-Json
    $createdField = $resultObj.data.createProjectV2Field.projectV2Field

    if ($createdField) {
        $createdFieldName = $createdField.name
        if (-not $createdFieldName) {
            $createdFieldName = $field.name
        }
        Write-Host "✅ Criado campo: $createdFieldName"
        continue
    }

    if ($response -like '*Name has already been taken*') {
        # Se o campo no schema não for do tipo 'single_select', apenas informe que já existe.
        if ($field.type -ne "single_select") {
            Write-Host "⚠️ Campo já existe: $($field.name) (Tipo: $($field.type))"
            continue
        }

        Write-Host "⚠️ Campo já existe: $($field.name). Verificando opções..."

        $queryPayload = @{
            query     = $getFieldsQuery
            variables = @{ projectId = $projectId }
        } | ConvertTo-Json -Depth 5 -Compress

        $existing = $queryPayload | gh api graphql --input - --header "Content-Type: application/json" | ConvertFrom-Json
        $found = $existing.data.node.fields.nodes | Where-Object { $_.name -eq $field.name }

        if (-not $found) {
            Write-Host "❌ Campo '$($field.name)' não encontrado apesar do erro de nome já usado."
            continue
        }

        $existingOptionNames = $found.options.name

        foreach ($opt in $field.options) {
            if ($existingOptionNames -contains $opt.name) {
                Write-Host "  ✅ Opção já existe: $($opt.name)"
                continue
            }

            $addPayload = @{
                query     = $addOptionMutation
                variables = @{
                    fieldId     = $found.id
                    name        = $opt.name
                    description = $opt.description
                    color       = $opt.color
                }
            } | ConvertTo-Json -Depth 10 -Compress

            $addResult = $addPayload | gh api graphql --input - --header "Content-Type: application/json"

            if ($addResult -like '*singleSelectFieldOption*') {
                Write-Host "  ➕ Adicionada nova opção: $($opt.name)"
            } else {
                Write-Host "  ❌ Falha ao adicionar: $($opt.name)"
                Write-Host $addResult
            }
        }
    } else {
        Write-Host "❌ Erro ao criar campo: $($field.name)"
        Write-Host "Resposta:"
        $response
    }
}

