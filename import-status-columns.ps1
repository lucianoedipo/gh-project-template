param(
    [string]$projectId,
    [string]$schemaPath = ".\templates\project-schema.scrum-ddss.v1.json"
)

if (-not $projectId) {
    Write-Error "O ID do projeto é obrigatório. Use: .\import-status-columns.ps1 -projectId SEU_ID_AQUI"
    return
}

Write-Host "🚀 Iniciando a configuração das colunas (Status) para o projeto: $projectId"

# 1. Ler e processar o arquivo de schema JSON
if (-not (Test-Path $schemaPath)) {
    Write-Error "Arquivo de schema não encontrado em: $schemaPath"
    return
}
$schema = Get-Content -Path $schemaPath | ConvertFrom-Json
$statusFieldSchema = $schema.fields | Where-Object { $_.name -eq "Status" }

if (-not $statusFieldSchema) {
    Write-Error "O campo 'Status' não foi encontrado no arquivo de schema."
    return
}

# 2. Query para encontrar o ID do campo "Status" no projeto
$findStatusFieldQuery = @'
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

$queryPayload = @{
    query     = $findStatusFieldQuery
    variables = @{ projectId = $projectId }
} | ConvertTo-Json -Depth 5

Write-Host "🔍 Buscando o campo 'Status' no projeto..."
$fieldResult = $queryPayload | gh api graphql --input - | ConvertFrom-Json

$statusFieldId = $fieldResult.data.node.field.id
$existingOptions = $fieldResult.data.node.field.options

if (-not $statusFieldId) {
    Write-Error "Não foi possível encontrar o campo 'Status' no projeto. Verifique o ID do projeto e suas permissões."
    return
}

Write-Host "✅ Campo 'Status' encontrado com ID: $statusFieldId"

# 3. Preparar as novas opções a partir do schema
$newOptions = $statusFieldSchema.options | ForEach-Object {
    @{
        name  = $_.name
        color = $_.color
        description = $_.description
    }
}

# 4. Mutation para ATUALIZAR as opções do campo.
# Esta mutation substitui TODAS as opções existentes pelas novas.
$updateOptionsMutation = @'
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

$updatePayload = @{
    query     = $updateOptionsMutation
    variables = @{
        fieldId = $statusFieldId
        options = $newOptions
    }
} | ConvertTo-Json -Depth 10 -Compress

Write-Host "🔄 Atualizando as opções do campo 'Status'..."

# 5. Executar a atualização
$updateResult = $updatePayload | gh api graphql --input -

if ($updateResult -like '*"projectV2Field":*') {
    Write-Host "✅ Sucesso! As colunas do quadro (Status) foram atualizadas conforme o schema."
    $updatedOptions = ($updateResult | ConvertFrom-Json).data.updateProjectV2Field.projectV2Field.options
    Write-Host "Opções atuais:"
    $updatedOptions | ForEach-Object { Write-Host "  - $($_.name) ($($_.color))" }
} else {
    Write-Error "❌ Falha ao atualizar as opções do campo 'Status'."
    Write-Host $updateResult
}
