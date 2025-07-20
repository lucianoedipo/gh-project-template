# Funções para gerenciar colunas de status

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
    Write-Host "🧹 Limpando opções existentes para evitar duplicatas..." -ForegroundColor Yellow
    Clear-StatusOptions -statusFieldId $statusFieldId
    
    # Adicionar as novas opções
    Write-Host "🔄 Atualizando as opções do campo 'Status'..." -ForegroundColor Cyan
    Add-StatusOptions -statusFieldId $statusFieldId -options $newOptions
}

function Get-StatusFieldId {
    param(
        [string]$projectId
    )

    $queryPayload = @{
        query     = $script:findStatusFieldQuery
        variables = @{ projectId = $projectId }
    } | ConvertTo-Json -Depth 5

    Write-Host "🔍 Buscando o campo 'Status' no projeto..." -ForegroundColor Cyan
    
    try {
        $fieldResult = $queryPayload | gh api graphql --input - | ConvertFrom-Json
        $statusFieldId = $fieldResult.data.node.field.id
        
        if (-not $statusFieldId) {
            Write-Error "Não foi possível encontrar o campo 'Status' no projeto. Verifique o ID do projeto e suas permissões."
            return $null
        }
        
        Write-Host "✅ Campo 'Status' encontrado com ID: $statusFieldId" -ForegroundColor Green
        return $statusFieldId
    }
    catch {
        Write-Error "❌ Erro ao buscar campo 'Status': $($_.Exception.Message)"
        return $null
    }
}

function Clear-StatusOptions {
    param(
        [string]$statusFieldId
    )

    $clearPayload = @{
        query     = $script:updateStatusOptionsMutation
        variables = @{
            fieldId = $statusFieldId
            options = @()
        }
    } | ConvertTo-Json -Depth 10 -Compress

    try {
        $clearResult = $clearPayload | gh api graphql --input -
        $resultObj = Process-GhApiResponse -response $clearResult
        
        if ($resultObj -and $resultObj.data.updateProjectV2Field.projectV2Field) {
            Write-Host "✅ Opções do campo 'Status' removidas com sucesso" -ForegroundColor Green
            return $true
        }
        else {
            Write-Warning "⚠️ Possível problema ao limpar opções de status"
            return $false
        }
    }
    catch {
        Write-Error "❌ Erro ao limpar opções: $($_.Exception.Message)"
        return $false
    }
}

function Add-StatusOptions {
    param(
        [string]$statusFieldId,
        [Array]$options
    )

    $updatePayload = @{
        query     = $script:updateStatusOptionsMutation
        variables = @{
            fieldId = $statusFieldId
            options = $options
        }
    } | ConvertTo-Json -Depth 10 -Compress

    try {
        $updateResult = $updatePayload | gh api graphql --input -
        $resultObj = Process-GhApiResponse -response $updateResult
        
        if ($resultObj -and $resultObj.data.updateProjectV2Field.projectV2Field) {
            Write-Host "✅ Sucesso! As colunas do quadro (Status) foram atualizadas conforme o schema." -ForegroundColor Green
            $updatedOptions = $resultObj.data.updateProjectV2Field.projectV2Field.options
            Write-Host "Opções atuais:"
            $updatedOptions | ForEach-Object { Write-Host "  - $($_.name) ($($_.color))" }
            return $true
        }
        else {
            Write-Error "❌ Falha ao atualizar as opções do campo 'Status'."
            if ($resultObj -and $resultObj.errors) {
                $resultObj.errors | ForEach-Object { Write-Host "   - $($_.message)" -ForegroundColor Red }
            }
            return $false
        }
    }
    catch {
        Write-Error "❌ Erro ao adicionar opções: $($_.Exception.Message)"
        return $false
    }
}
