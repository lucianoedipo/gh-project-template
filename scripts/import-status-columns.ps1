param(
    [string]$projectId,
    [string]$schemaPath = ""
)

# Definir função de fallback para o Write-Log caso ele não esteja disponível
function Write-LogFallback {
    param(
        [string]$Message,
        [string]$Level = "Info",
        [switch]$Console
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] $Message"
    
    $logDir = Join-Path $PSScriptRoot "..\logs"
    if (-not (Test-Path $logDir)) {
        New-Item -ItemType Directory -Path $logDir -Force | Out-Null
    }
    
    $logFile = Join-Path $logDir "setup.log"
    Add-Content -Path $logFile -Value $logMessage -ErrorAction SilentlyContinue
    
    if ($Console -or $Level -eq "Info") {
        Write-Host $Message
    }
    elseif ($Level -eq "Warning") {
        Write-Warning $Message
    }
    elseif ($Level -eq "Error") {
        Write-Error $Message
    }
}

# Importar módulos corretamente
$modulesPath = Join-Path $PSScriptRoot "..\modules"
Import-Module (Join-Path $modulesPath "graphql-queries.psm1") -Force
Import-Module (Join-Path $modulesPath "status-fields.psm1") -Force
Import-Module (Join-Path $modulesPath "SchemaManager.psm1") -Force

# Verificar se utils.psm1 existe e tentar importá-lo
$utilsPath = Join-Path $modulesPath "utils.psm1"
if (Test-Path $utilsPath) {
    try {
        Import-Module $utilsPath -Force
        # Testar se a função Write-Log está disponível
        if (-not (Get-Command Write-Log -ErrorAction SilentlyContinue)) {
            Write-Warning "A função Write-Log não foi importada corretamente. Usando fallback."
            # Criar um alias para nossa função de fallback
            Set-Alias -Name Write-Log -Value Write-LogFallback -Scope Script
        }
    }
    catch {
        Write-Warning "Não foi possível importar o módulo utils: $($_.Exception.Message)"
        # Criar um alias para nossa função de fallback
        Set-Alias -Name Write-Log -Value Write-LogFallback -Scope Script
    }
}
else {
    Write-Warning "O módulo utils.psm1 não foi encontrado em $utilsPath. Usando fallback."
    # Criar um alias para nossa função de fallback
    Set-Alias -Name Write-Log -Value Write-LogFallback -Scope Script
}

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

# Adicionar mais informações de diagnóstico
Write-Host "📋 Verificando schema de status..." -ForegroundColor Yellow
if ($statusFieldSchema) {
    Write-Host "✅ Schema de status encontrado com $($statusFieldSchema.options.Count) opções configuradas." -ForegroundColor Green
    Write-Host "📊 Opções de status definidas no schema:" -ForegroundColor Cyan
    foreach ($option in $statusFieldSchema.options) {
        Write-Host "   - $($option.name) ($($option.color))" -ForegroundColor White
    }
} else {
    Write-Host "❌ Campo 'Status' não foi encontrado no arquivo de schema." -ForegroundColor Red
    return
}

# Chamar a função com modo verbose para mais diagnóstico
Write-Host "🔄 Aplicando configuração de status ao projeto..." -ForegroundColor Cyan

# Obter ID do status e verificar se é válido antes de continuar
$statusFieldId = Get-StatusFieldId -projectId $projectId
if ($statusFieldId) {
    Write-Host "👉 Usando ID do campo Status: $statusFieldId" -ForegroundColor Cyan
    $statusResult = Update-StatusColumns -projectId $projectId -statusFieldSchema $statusFieldSchema
}
else {
    Write-Host "❌ Não foi possível obter o ID do campo Status. A configuração de colunas foi ignorada." -ForegroundColor Red
}

