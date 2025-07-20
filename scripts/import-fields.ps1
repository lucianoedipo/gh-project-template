param(
    [string]$projectId,
    [string]$schemaPath = ""
)

# Importar módulos
$modulesPath = Join-Path $PSScriptRoot "modules"
. (Join-Path $modulesPath "graphql-queries.ps1")
. (Join-Path $modulesPath "utils.ps1")
. (Join-Path $modulesPath "field-types.ps1")
. (Join-Path $modulesPath "iteration-fields.ps1")

# --- Input Validation ---
if (-not $projectId) {
    Write-Error "O ID do projeto é obrigatório. Use: .\import-fields.ps1 -projectId SEU_ID_AQUI"
    return
}
Write-Host "🚀 Iniciando a configuração de campos para o projeto: $projectId" -ForegroundColor Cyan

if (-not (Test-Path $schemaPath)) {
    Write-Error "Arquivo de schema não encontrado em: $schemaPath"
    return
}
$schema = Get-Content -Path $schemaPath | ConvertFrom-Json
Write-Host "✅ Schema carregado com sucesso: $schemaPath" -ForegroundColor Green

# Filtra os campos, excluindo "Status" que é tratado por outro script
$fields = $schema.fields | Where-Object { $_.name -ne "Status" }

# --- Configure Custom Fields (excluding Status and Iteration) ---
Write-Host "`n🔧 Configurando campos personalizados (exceto Status e Iteração)..." -ForegroundColor Yellow

# Criar campos regulares
Add-CustomFields -fields $fields -projectId $projectId

# --- Create Iteration Field (Sprint) ---
Write-Host "`n📅 Configurando campo de iteração (Sprint)..." -ForegroundColor Yellow

if ($schema.iteration) {
    Add-IterationField -projectId $projectId -iterationConfig $schema.iteration
}
else {
    Write-Host "ℹ️ Nenhuma configuração de campo de iteração encontrada no schema. Pulando esta etapa." -ForegroundColor DarkYellow
}

Write-Host "`n✅ Configuração de campos concluída." -ForegroundColor Green