# Funções globais compartilhadas entre todos os scripts

# Função global de logging que pode ser usada por qualquer script
function global:Write-ScriptLog {
    param(
        [string]$Message,
        [string]$Level = "Info",
        [switch]$Console
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] $Message"

    # Determinar o caminho do log
    $scriptRoot = if ($PSScriptRoot) { $PSScriptRoot } else { Get-Location }
    $baseDir = if ($scriptRoot -match "\\scripts$|\\modules$") { 
        Split-Path $scriptRoot -Parent 
    } else { 
        $scriptRoot 
    }

    $logDir = Join-Path $baseDir "logs"
    if (-not (Test-Path $logDir)) {
        New-Item -ItemType Directory -Path $logDir -Force | Out-Null
    }

    $logFile = Join-Path $logDir "setup.log"

    # Tentar escrever no log
    try {
        Add-Content -Path $logFile -Value $logMessage -ErrorAction Stop
    }
    catch {
        # Se falhar, não interromper a execução
        if ($Console) {
            Write-Warning "Não foi possível escrever no log: $($_.Exception.Message)"
        }
    }

    
}

# Criar um alias para compatibilidade com códigos existentes
Set-Alias -Name Write-Log -Value Write-ScriptLog -Scope Global
Set-Alias -Name Write-LogFallback -Value Write-ScriptLog -Scope Global

# Exportar as funções e aliases para o escopo global
Export-ModuleMember -Function Write-ScriptLog -Alias Write-Log, Write-LogFallback