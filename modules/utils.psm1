# Funções utilitárias para o script

# Função para logging centralizado
function Write-Log {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Message,
        
        [Parameter(Mandatory=$false)]
        [ValidateSet("Info", "Warning", "Error", "Debug")]
        [string]$Level = "Info",
        
        [Parameter(Mandatory=$false)]
        [switch]$Console
    )
    
    # Criação do diretório de log de forma mais segura
    try {
        $logDir = Join-Path $PSScriptRoot "..\logs"
        if (-not (Test-Path $logDir)) {
            New-Item -ItemType Directory -Path $logDir -Force | Out-Null
        }
        
        $logFile = Join-Path $logDir "setup.log"
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        $logMessage = "[$timestamp] [$Level] $Message"
        
        # Sempre gravar no arquivo de log
        Add-Content -Path $logFile -Value $logMessage -ErrorAction Stop
        
        # Exibir no console apenas se solicitado ou se for nível Info
        if ($Console -or $Level -eq "Info") {
            switch ($Level) {
                "Info"    { Write-Host $Message }
                "Warning" { if ($Console) { Write-Warning $Message } }
                "Error"   { if ($Console) { Write-Error $Message } }
                "Debug"   { if ($VerbosePreference -eq 'Continue') { Write-Verbose $Message } }
            }
        }
    }
    catch {
        # Fallback para console se não conseguir gravar no log
        Write-Warning "Não foi possível escrever no arquivo de log: $($_.Exception.Message)"
        Write-Warning "Mensagem original: [$Level] $Message"
    }
}

# Função auxiliar para processar respostas da API (renomeada para usar verbo aprovado)
function ConvertFrom-GhApiResponse {
    param(
        [string]$response
    )
    
    # Se a resposta estiver vazia, retornar null imediatamente
    if ([string]::IsNullOrWhiteSpace($response)) {
        return $null
    }
    
    # Remover prefixo "gh:" se existir
    if ($response -match '^gh:\s*(.+)$') {
        $response = $Matches[1]
        # Se for uma mensagem de erro específica do gh, registrar no log e retornar null
        if ($response -match 'A query attribute must be specified') {
            try {
                Write-Log -Message "Erro da API GitHub: $response" -Level Error
            }
            catch {
                Write-Warning "Erro da API GitHub: $response"
            }
            return $null
        }
    }

    # Tentar converter diretamente
    try {
        return $response | ConvertFrom-Json -ErrorAction Stop
    }
    catch {
        # Se falhar, tentar extrair um JSON válido da resposta
        if ($response -match '(\{.*\}\s*$)') {
            $jsonPart = $Matches[1]
            try {
                return $jsonPart | ConvertFrom-Json -ErrorAction Stop
            }
            catch {
                try {
                    Write-Log -Message "Não foi possível extrair JSON válido da resposta: $jsonPart" -Level Warning
                }
                catch {
                    Write-Warning "Não foi possível extrair JSON válido da resposta: $jsonPart"
                }
                return $null
            }
        }
        
        try {
            Write-Log -Message "Resposta não é JSON válido: $response" -Level Warning
        }
        catch {
            Write-Warning "Resposta não é JSON válido: $response"
        }
        return $null
    }
}

# Garantir que as funções sejam exportadas explicitamente
Export-ModuleMember -Function Write-Log, ConvertFrom-GhApiResponse
