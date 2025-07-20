# Funções utilitárias para o script

# Função auxiliar para processar respostas da API
function Process-GhApiResponse {
    param(
        [string]$response
    )
    # Remover prefixo "gh:" se existir
    if ($response -match '^gh:\s*(.+)$') {
        $response = $Matches[1]
    }

    # Tentar extrair o JSON da resposta (após uma possível mensagem de erro)
    # Procura por um JSON que começa com "{" e termina com "}"
    if ($response -match '(\{.*\}\s*$)') {
        # Ajustado para capturar o JSON no final da string
        $jsonPart = $Matches[1]
        try {
            return $jsonPart | ConvertFrom-Json -ErrorAction Stop
        }
        catch {
            # Se falhar aqui, o JSON encontrado não é válido
            Write-Warning "Não foi possível extrair JSON válido da parte final da resposta: '$jsonPart'. Erro: $($_.Exception.Message)"
            return $null
        }
    }

    # Se não encontrou um JSON no final, tenta converter a resposta inteira
    try {
        return $response | ConvertFrom-Json -ErrorAction Stop
    }
    catch {
        # Isso pode ser uma resposta que não é JSON, como "Name has already been taken" sem JSON válido
        # Ou um erro geral do gh cli que não é um JSON no corpo
        Write-Warning "Não foi possível converter a resposta completa em JSON: '$response'. Erro: $($_.Exception.Message)"
        return $null
    }
}

# Função para carregar e validar o schema do projeto
function Get-ProjectSchema {
    param(
        [string]$schemaPath
    )

    if (-not (Test-Path $schemaPath)) {
        Write-Error "Arquivo de schema não encontrado em: $schemaPath"
        return $null
    }
    
    $schema = Get-Content -Path $schemaPath | ConvertFrom-Json
    Write-Host "✅ Schema carregado com sucesso: $schemaPath" -ForegroundColor Green
    return $schema
}

