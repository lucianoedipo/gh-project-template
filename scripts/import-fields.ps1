param(
    [string]$projectId,
    [string]$schemaPath = ""
)

# Importar módulos corretamente
$modulesPath = Join-Path $PSScriptRoot "..\modules"
Import-Module (Join-Path $modulesPath "graphql-queries.psm1") -Force
Import-Module (Join-Path $modulesPath "utils.psm1") -Force
Import-Module (Join-Path $modulesPath "field-types.psm1") -Force
Import-Module (Join-Path $modulesPath "iteration-fields.psm1") -Force
Import-Module (Join-Path $modulesPath "SchemaManager.psm1") -Force

# Input Validation
if (-not $projectId) {
    Write-Error "O ID do projeto é obrigatório. Use: .\import-fields.ps1 -projectId SEU_ID_AQUI"
    return
}
Write-Host "🚀 Iniciando a configuração de campos para o projeto: $projectId" -ForegroundColor Cyan

# Carregar schema
$schemaInfo = Get-ProjectSchema -schemaPath $schemaPath
if (-not $schemaInfo) { return }
$schema = $schemaInfo.Schema

# Filtra os campos, excluindo "Status" que é tratado por outro script
$fields = $schema.fields | Where-Object { $_.name -ne "Status" }

# Configure Custom Fields (excluding Status and Iteration)
Write-Host "`n🔧 Configurando campos personalizados (exceto Status e Iteração)..." -ForegroundColor Yellow

# Criar campos regulares
Add-CustomFields -fields $fields -projectId $projectId

# Create Iteration Field (Sprint)
Write-Host "`n📅 Configurando campo de iteração (Sprint)..." -ForegroundColor Yellow

if ($schema.iteration) {
    Add-IterationField -projectId $projectId -iterationConfig $schema.iteration
}
else {
    Write-Host "ℹ️ Nenhuma configuração de campo de iteração encontrada no schema. Pulando esta etapa." -ForegroundColor DarkYellow
}

$docsPath = Join-Path $PSScriptRoot "..\docs\campos-especiais.md"
Write-Host "`nℹ️ Para mais informações sobre configuração de campos especiais, consulte:"
Write-Host "   $docsPath" -ForegroundColor Cyan

Write-Host "`n✅ Configuração de campos concluída." -ForegroundColor Green