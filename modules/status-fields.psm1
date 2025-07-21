# Funções para gerenciar colunas de status

# Importar o módulo de consultas GraphQL
$graphqlModulePath = Join-Path $PSScriptRoot "graphql-queries.psm1"
Import-Module $graphqlModulePath -Force

# Importar o módulo de utilidades
$utilsModulePath = Join-Path $PSScriptRoot "utils.psm1"
Import-Module $utilsModulePath -Force

function Update-StatusColumns {
    param(
        [string]$projectId,
        [PSCustomObject]$statusFieldSchema
    )

    # Encontrar o ID do campo Status no projeto
    $statusFieldId = Get-StatusFieldId -projectId $projectId
    if (-not $statusFieldId) { return }

    # Preparar as novas opções a partir do schema
    $newOptions = $statusFieldSchema.options | ForEach-Object {
        @{
            name        = $_.name
            color       = $_.color
            description = $_.description
        }
    }

    # Limpar as opções existentes primeiro para evitar duplicatas
    Write-Output "🧹 Limpando opções existentes para evitar duplicatas..."
    $clearResult = Clear-StatusOptions -statusFieldId $statusFieldId
    
    # Adicionar as novas opções
    Write-Output "🔄 Atualizando as opções do campo 'Status'..."
    $addResult = Add-StatusOptions -statusFieldId $statusFieldId -options $newOptions
    
    # Não retornar valores booleanos diretamente para evitar saída no console
    return
}

function Get-StatusFieldId {
    param(
        [string]$projectId
    )

    # Definir a consulta GraphQL diretamente para evitar problemas de escopo
    $findStatusFieldQuery = @'
query($projectId: ID!) {
  node(id: $projectId) {
    ... on ProjectV2 {
      field(name: "Status") {
        ... on ProjectV2SingleSelectField {
          id
          name
          options {
            id
            name
          }
        }
      }
    }
  }
}
'@

    $queryPayload = @{
        query     = $findStatusFieldQuery
        variables = @{ projectId = $projectId }
    } | ConvertTo-Json -Depth 5 -Compress

    # IMPORTANTE: Não usar Write-Output aqui, usar Write-Host para evitar captura do texto na variável de retorno
    Write-Host "🔍 Buscando o campo 'Status' no projeto..." -ForegroundColor Yellow
    
    try {
        # Usar arquivo temporário para a consulta para evitar problemas de pipeline e redirecionamento
        $tempFile = [System.IO.Path]::GetTempFileName()
        Set-Content -Path $tempFile -Value $queryPayload -Encoding UTF8NoBOM
        
        $fieldResult = gh api graphql --input "$tempFile" 2>&1
        Remove-Item -Path $tempFile -Force -ErrorAction SilentlyContinue
        
        # Converter resultado para objeto
        $resultObj = $fieldResult | ConvertFrom-Json -ErrorAction Stop
        $statusFieldId = $resultObj.data.node.field.id
        
        if (-not $statusFieldId) {
            Write-Host "❌ Não foi possível encontrar o campo 'Status' no projeto." -ForegroundColor Red
            Write-Host "   O campo Status será criado automaticamente quando você configurar o Board do projeto." -ForegroundColor Yellow
            return $null
        }
        
        Write-Host "✅ Campo 'Status' encontrado com ID: $statusFieldId" -ForegroundColor Green
        # Retornar apenas o ID sem nenhuma mensagem adicional
        return $statusFieldId
    }
    catch {
        Write-Host "❌ Erro ao buscar campo 'Status': $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "   O campo Status será criado automaticamente quando você configurar o Board do projeto." -ForegroundColor Yellow
        return $null
    }
}

function Clear-StatusOptions {
    param(
        [string]$statusFieldId
    )

    # Garantir que estamos trabalhando com um ID válido
    if (-not $statusFieldId -or $statusFieldId -match "Buscando" -or $statusFieldId -match "encontrado") {
        Write-Host "⚠️ ID do campo Status inválido: '$statusFieldId'" -ForegroundColor Red
        return $false
    }

    # Usar a variável importada corretamente
    $clearPayload = @{
        query     = $script:updateStatusOptionsMutation
        variables = @{
            fieldId = $statusFieldId
            options = @()
        }
    } | ConvertTo-Json -Depth 10 -Compress

    $tempFile = [System.IO.Path]::GetTempFileName()
    Set-Content -Path $tempFile -Value $clearPayload -Encoding UTF8NoBOM

    # Remover linha de debug
    # Write-Output "DEBUG: Temp JSON file content for Clear-StatusOptions: $(Get-Content -Path $tempFile | Out-String)"

    try {
        $clearResult = gh api graphql --input "$tempFile" 2>&1
        Remove-Item -Path $tempFile -Force -ErrorAction SilentlyContinue
        
        # Processar a resposta
        try {
            $resultObj = $clearResult | ConvertFrom-Json -ErrorAction Stop
            if ($resultObj.data.updateProjectV2Field.projectV2Field) {
                Write-Output "✅ Opções do campo 'Status' removidas com sucesso"
                return $true
            }
            else {
                Write-Log -Message "Possível problema ao limpar opções de status: $clearResult" -Level Warning
                return $false
            }
        }
        catch {
            Write-Log -Message "Erro ao processar resposta de limpeza: $clearResult" -Level Error
            return $false
        }
    }
    catch {
        Write-Log -Message "Erro ao limpar opções: $($_.Exception.Message)" -Level Error
        return $false
    }
}

function Add-StatusOptions {
    param(
        [string]$statusFieldId,
        [Array]$options
    )

    # Correção aqui: usar $script:updateStatusOptionsMutation 
    # em vez de $updateStatusOptionsMutation
    $updatePayload = @{
        query     = $script:updateStatusOptionsMutation
        variables = @{
            fieldId = $statusFieldId
            options = $options
        }
    } | ConvertTo-Json -Depth 10 -Compress

    $tempFile = [System.IO.Path]::GetTempFileName()
    Set-Content -Path $tempFile -Value $updatePayload -Encoding UTF8NoBOM

    # Remover linha de debug
    # Write-Output "DEBUG: Temp JSON file content for Add-StatusOptions: $(Get-Content -Path $tempFile | Out-String)"

    try {
        $updateResult = gh api graphql --input "$tempFile" 2>&1
        Remove-Item -Path $tempFile -Force -ErrorAction SilentlyContinue
        
        # Processar a resposta
        try {
            $resultObj = $updateResult | ConvertFrom-Json -ErrorAction Stop
            if ($resultObj.data.updateProjectV2Field.projectV2Field) {
                Write-Output "✅ Sucesso! As colunas do quadro (Status) foram atualizadas conforme o schema."
                $updatedOptions = $resultObj.data.updateProjectV2Field.projectV2Field.options
                Write-Output "Opções atuais:"
                $updatedOptions | ForEach-Object { Write-Output "  - $($_.name) ($($_.color))" }
                return $true
            }
            else {
                Write-Log -Message "Falha ao atualizar as opções do campo 'Status': $updateResult" -Level Warning
                return $false
            }
        }
        catch {
            Write-Log -Message "Erro ao processar resposta de atualização: $updateResult" -Level Error
            return $false
        }
    }
    catch {
        # Corrigir o erro de sintaxe na linha abaixo
        Write-Log -Message "Erro ao adicionar opções: $($_.Exception.Message)" -Level Error
        return $false
    }
}

# Corrigir a linha duplicada de exportação
Export-ModuleMember -Function Update-StatusColumns, Get-StatusFieldId, Clear-StatusOptions, Add-StatusOptions