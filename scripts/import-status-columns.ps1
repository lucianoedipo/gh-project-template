param(
    [string]$projectId,
    [string]$schemaPath = ""
)

## Importar módulos
$modulesPath = Join-Path $PSScriptRoot "modules"
. (Join-Path $modulesPath "graphql-queries.ps1")
. (Join-Path $modulesPath "utils.ps1")
. (Join-Path $modulesPath "status-fields.ps1")

## Validação dos parâmetros de entrada
if (-not $projectId) {
    Write-Error "O ID do projeto é obrigatório. Use: .\import-status-columns.ps1 -projectId SEU_ID_AQUI"
    return
}

Write-Host "🚀 Iniciando a configuração das colunas (Status) para o projeto: $projectId"

## Carregar e validar o schema
$schema = Get-ProjectSchema -schemaPath $schemaPath
if (-not $schema) { return }

$statusFieldSchema = $schema.fields | Where-Object { $_.name -eq "Status" }
if (-not $statusFieldSchema) {
    Write-Error "O campo 'Status' não foi encontrado no arquivo de schema."
    return
}

## Chama a função modularizada para atualizar as colunas de status
Update-StatusColumns -projectId $projectId -statusFieldSchema $statusFieldSchema

