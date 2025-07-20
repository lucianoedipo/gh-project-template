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
    } | ConvertTo-Json -Depth 5

    Write-Host "🔍 Buscando o campo 'Status' no projeto..." -ForegroundColor Cyan
    
    try {
        $fieldResult = $queryPayload | gh api graphql --input - | ConvertFrom-Json
        $statusFieldId = $fieldResult.data.node.field.id
        
        if (-not $statusFieldId) {
            Write-Host "❌ Não foi possível encontrar o campo 'Status' no projeto." -ForegroundColor Red
            Write-Host "   O campo Status será criado automaticamente quando você configurar o Board do projeto." -ForegroundColor Yellow
            return $null
        }
        
        Write-Host "✅ Campo 'Status' encontrado com ID: $statusFieldId" -ForegroundColor Green
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

    # Definir a consulta GraphQL diretamente para evitar problemas de escopo
    $updateStatusOptionsMutation = @'
mutation($fieldId: ID!, $options: [ProjectV2SingleSelectFieldOptionInput!]) {
  updateProjectV2Field(
    input: {
      fieldId: $fieldId
      singleSelectOptions: $options
    }
  ) {
    projectV2Field {
      ... on ProjectV2SingleSelectField {
        id
        name
        options {
          id
          name
          color
        }
      }
    }
  }
}
'@

    $clearPayload = @{
        query     = $updateStatusOptionsMutation
        variables = @{
            fieldId = $statusFieldId
            options = @()
        }
    } | ConvertTo-Json -Depth 10 -Compress

    try {
        $clearResult = $clearPayload | gh api graphql --input -
        $resultObj = ConvertFrom-GhApiResponse -response $clearResult
        
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
        Write-Warning "❌ Erro ao limpar opções: $($_.Exception.Message)"
        return $false
    }
}

function Add-StatusOptions {
    param(
        [string]$statusFieldId,
        [Array]$options
    )

    # Definir a consulta GraphQL diretamente para evitar problemas de escopo
    $updateStatusOptionsMutation = @'
mutation($fieldId: ID!, $options: [ProjectV2SingleSelectFieldOptionInput!]) {
  updateProjectV2Field(
    input: {
      fieldId: $fieldId
      singleSelectOptions: $options
    }
  ) {
    projectV2Field {
      ... on ProjectV2SingleSelectField {
        id
        name
        options {
          id
          name
          color
        }
      }
    }
  }
}
'@

    $updatePayload = @{
        query     = $updateStatusOptionsMutation
        variables = @{
            fieldId = $statusFieldId
            options = $options
        }
    } | ConvertTo-Json -Depth 10 -Compress

    try {
        $updateResult = $updatePayload | gh api graphql --input -
        $resultObj = ConvertFrom-GhApiResponse -response $updateResult
        
        if ($resultObj -and $resultObj.data.updateProjectV2Field.projectV2Field) {
            Write-Host "✅ Sucesso! As colunas do quadro (Status) foram atualizadas conforme o schema." -ForegroundColor Green
            $updatedOptions = $resultObj.data.updateProjectV2Field.projectV2Field.options
            Write-Host "Opções atuais:"
            $updatedOptions | ForEach-Object { Write-Host "  - $($_.name) ($($_.color))" }
            return $true
        }
        else {
            Write-Warning "❌ Falha ao atualizar as opções do campo 'Status'."
            if ($resultObj -and $resultObj.errors) {
                $resultObj.errors | ForEach-Object { Write-Host "   - $($_.message)" -ForegroundColor Red }
            }
            return $false
        }
    }
    catch {
        Write-Warning "❌ Erro ao adicionar opções: $($_.Exception.Message)"
        return $false
    }
}

Export-ModuleMember -Function Update-StatusColumns, Get-StatusFieldId, Clear-StatusOptions, Add-StatusOptions