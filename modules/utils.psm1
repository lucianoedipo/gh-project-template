# Funções utilitárias para o script

# Função auxiliar para processar respostas da API (renomeada para usar verbo aprovado)
function ConvertFrom-GhApiResponse {
    param(
        [string]$response
    )
    # Remover prefixo "gh:" se existir
    if ($response -match '^gh:\s*(.+)$') {
        $response = $Matches[1]
    }

    # Tentar extrair o JSON da resposta (após uma possível mensagem de erro)
    if ($response -match '(\{.*\}\s*$)') {
        # Ajustado para capturar o JSON no final da string
        $jsonPart = $Matches[1]
        try {
            return $jsonPart | ConvertFrom-Json -ErrorAction Stop
        }
        catch {
            # Mensagem de aviso mais limpa
            Write-Verbose "Não foi possível extrair JSON válido da resposta: $jsonPart"
            return $null
        }
    }

    # Se não encontrou um JSON no final, tenta converter a resposta inteira
    try {
        return $response | ConvertFrom-Json -ErrorAction Stop
    }
    catch {
        Write-Verbose "Resposta não é JSON válido: $response"
        return $null
    }
}

# Exportar apenas a função com verbo aprovado
Export-ModuleMember -Function ConvertFrom-GhApiResponse
