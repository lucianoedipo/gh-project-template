param(
    [string]$projectId,
    [string]$schemaPath = ""
)

# Importar módulos corretamente
$modulesPath = Join-Path $PSScriptRoot "..\modules"
Import-Module (Join-Path $modulesPath "graphql-queries.psm1") -Force
Import-Module (Join-Path $modulesPath "utils.psm1") -Force
Import-Module (Join-Path $modulesPath "status-fields.psm1") -Force
Import-Module (Join-Path $modulesPath "SchemaManager.psm1") -Force

# Validação dos parâmetros de entrada
if (-not $projectId) {
    Write-Error "O ID do projeto é obrigatório. Use: .\import-status-columns.ps1 -projectId SEU_ID_AQUI"
    return
}

Write-Host "🚀 Iniciando a configuração das colunas (Status) para o projeto: $projectId"

# Carregar e validar o schema
$schemaInfo = Get-ProjectSchema -schemaPath $schemaPath
if (-not $schemaInfo) { return }
$schema = $schemaInfo.Schema

$statusFieldSchema = $schema.fields | Where-Object { $_.name -eq "Status" }
if (-not $statusFieldSchema) {
    Write-Error "O campo 'Status' não foi encontrado no arquivo de schema."
    return
}

# Chama a função modularizada para atualizar as colunas de status
Update-StatusColumns -projectId $projectId -statusFieldSchema $statusFieldSchema

