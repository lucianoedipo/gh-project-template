param(
    [string]$projectId,
    [string]$schemaPath = ""
)

if (-not $projectId) {
    Write-Error "O ID do projeto é obrigatório. Use: .\check-views.ps1 -projectId SEU_ID_AQUI"
    return
}

Write-Host "🚀 Iniciando a verificação de views para o projeto: $projectId"

# 1. Ler o schema
if (-not (Test-Path $schemaPath)) {
    Write-Error "Arquivo de schema não encontrado em: $schemaPath"
    return
}
$schema = Get-Content -Path $schemaPath | ConvertFrom-Json
$viewsSchema = $schema.views

# 2. Query para buscar todos os campos e views existentes para mapeamento
$getProjectDataQuery = @'
query GetProjectData($projectId: ID!) {
  node(id: $projectId) {
    ... on ProjectV2 {
      fields(first: 100) {
        nodes {
          ... on ProjectV2FieldCommon {
            id
            name
          }
        }
      }
      views(first: 100) {
        nodes {
          id
          name
        }
      }
    }
  }
}
'@

$queryPayload = @{ query = $getProjectDataQuery; variables = @{ projectId = $projectId } } | ConvertTo-Json
Write-Host "🔍 Mapeando campos e views existentes no projeto..."
$projectData = $queryPayload | gh api graphql --input - | ConvertFrom-Json

if ($null -eq $projectData.data.node) {
    Write-Error "❌ Falha ao buscar dados do projeto. Verifique o ID do projeto e suas permissões."
    Write-Host "Resposta da API:"
    Write-Host ($projectData | ConvertTo-Json -Depth 5)
    return
}

# 3. Criar mapas de Nome para ID
$fieldNameToIdMap = @{}
foreach ($field in $projectData.data.node.fields.nodes) {
    $fieldNameToIdMap[$field.name] = $field.id
}

$viewNameToIdMap = @{}
foreach ($view in $projectData.data.node.views.nodes) {
    $viewNameToIdMap[$view.name] = $view.id
}

Write-Host "✅ Mapeamento concluído."

# 4. Gerar relatório de correspondência entre as views do schema e do projeto
Write-Host "📊 Gerando relatório de views..."
$viewReport = @()

foreach ($viewSchema in $viewsSchema) {
    $viewName = $viewSchema.name
    $exists = $viewNameToIdMap.ContainsKey($viewName)
    $status = if ($exists) { "✅ Encontrada" } else { "❌ Não encontrada" }
    
    $viewReport += [PSCustomObject]@{
        Nome   = $viewName
        Status = $status
        Id     = if ($exists) { $viewNameToIdMap[$viewName] } else { "N/A" }
    }
}

# Exibir relatório de views como texto simples para evitar problemas de formatação
Write-Host "`nRelatório de Views:"
Write-Host "===================="
foreach ($item in $viewReport) {
    Write-Host "$($item.Status) | $($item.Nome) | ID: $($item.Id)"
}
Write-Host "===================="

Write-Host "`n🔔 Verificação concluída!"
Write-Host "  • Para instruções detalhadas sobre como criar as views manualmente, consulte:"
Write-Host "    .\docs\criar-views-manual.md"

