param(
    [string]$projectId,
    [string]$schemaPath = ""
)

# Verificar primeiro se o módulo iteration-fields.psm1 existe antes de tentar importá-lo
$modulesPath = Join-Path $PSScriptRoot "..\modules"
$iterationModulePath = Join-Path $modulesPath "iteration-fields.psm1"

# Importar módulos corretamente
Import-Module (Join-Path $modulesPath "graphql-queries.psm1") -Force
Import-Module (Join-Path $modulesPath "utils.psm1") -Force
Import-Module (Join-Path $modulesPath "field-types.psm1") -Force
Import-Module (Join-Path $modulesPath "SchemaManager.psm1") -Force

# Definir função de fallback para o Write-Log caso ele não esteja disponível
function Script:Write-LogFallback {
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

# Verificar se a função Write-Log existe e criar alias se necessário
if (-not (Get-Command Write-Log -ErrorAction SilentlyContinue)) {
    Set-Alias -Name Write-Log -Value Write-LogFallback -Scope Script
}

# Verificar se o módulo iteration-fields.psm1 existe e, se não existir, criar uma função substituta
if (Test-Path $iterationModulePath) {
    Import-Module $iterationModulePath -Force
}
else {
    # Criar função substituta para Add-IterationField
    function Add-IterationField {
        param(
            [string]$projectId,
            [PSCustomObject]$iterationConfig
        )
        
        Write-Output "⚠️ O módulo de campos de iteração não foi encontrado."
        Write-Output "Por favor, crie o campo '$($iterationConfig.name)' manualmente na interface do GitHub."
        Write-Output "Consulte o arquivo '.\docs\campos-especiais.md' para mais detalhes sobre a configuração manual."
    }
}

# Input Validation
if (-not $projectId) {
    Write-Error "O ID do projeto é obrigatório. Use: .\import-fields.ps1 -projectId SEU_ID_AQUI"
    return
}
Write-Output "🚀 Iniciando a configuração de campos para o projeto: $projectId"

# Carregar schema
$schemaInfo = Get-ProjectSchema -schemaPath $schemaPath
if (-not $schemaInfo) { return }
$schema = $schemaInfo.Schema

# Filtra os campos, excluindo "Status" que é tratado por outro script
$fields = $schema.fields | Where-Object { $_.name -ne "Status" }

# Configure Custom Fields (excluding Status and Iteration)
Write-Output "`n🔧 Configurando campos personalizados (exceto Status e Iteração)..."

# Criar campos regulares
$fieldErrors = @()
try {
    Add-CustomFields -fields $fields -projectId $projectId
}
catch {
    try {
        Write-Log -Message "Erro ao adicionar campos personalizados: $($_.Exception.Message)" -Level Error
    }
    catch {
        Write-LogFallback -Message "Erro ao adicionar campos personalizados: $($_.Exception.Message)" -Level Error
    }
    $fieldErrors += $_.Exception.Message
}

# Create Iteration Field (Sprint)
Write-Output "`n📅 Configurando campo de iteração (Sprint)..."

if ($schema.iteration) {
    try {
        Add-IterationField -projectId $projectId -iterationConfig $schema.iteration
    }
    catch {
        try {
            Write-Log -Message "Erro ao configurar campo de iteração: $($_.Exception.Message)" -Level Error
        }
        catch {
            Write-LogFallback -Message "Erro ao configurar campo de iteração: $($_.Exception.Message)" -Level Error
        }
        $fieldErrors += $_.Exception.Message
    }
}
else {
    Write-Output "ℹ️ Nenhuma configuração de campo de iteração encontrada no schema. Pulando esta etapa."
}

# Se houve erros, registrar no log para diagnóstico posterior
if ($fieldErrors.Count -gt 0) {
    try {
        Write-Log -Message "Erros durante a configuração de campos: $($fieldErrors -join '; ')" -Level Error
    }
    catch {
        Write-LogFallback -Message "Erros durante a configuração de campos: $($fieldErrors -join '; ')" -Level Error
    }
}

$docsPath = Join-Path $PSScriptRoot "..\docs\campos-especiais.md"
Write-Output "`nℹ️ Para mais informações sobre configuração de campos especiais, consulte:"
Write-Output "   $docsPath"

Write-Output "`n✅ Configuração de campos concluída."