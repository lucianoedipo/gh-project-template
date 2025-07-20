# Funções para gerenciar campos de iteração (Sprint)

# Importar o módulo de consultas GraphQL
$graphqlModulePath = Join-Path $PSScriptRoot "graphql-queries.psm1"
Import-Module $graphqlModulePath -Force

# Importar o módulo de utilidades
$utilsModulePath = Join-Path $PSScriptRoot "utils.psm1"
Import-Module $utilsModulePath -Force

function Add-IterationField {
    param(
        [string]$projectId,
        [PSCustomObject]$iterationConfig
    )

    # Remover as verificações redundantes e usar diretamente as consultas do módulo importado
    
    # 1. Check if the iteration field exists
    $checkPayload = @{
        query     = $script:getFieldsQuery
        variables = @{ projectId = $projectId }
    } | ConvertTo-Json -Depth 5
    
    try {
        $checkResult = $checkPayload | gh api graphql --input - | ConvertFrom-Json
        $iterationField = $checkResult.data.node.fields.nodes | Where-Object { 
            $_.name -eq $iterationConfig.name -and $_.dataType -eq "ITERATION" 
        }
        
        if ($iterationField) {
            Write-Host "✅ Campo de iteração '$($iterationConfig.name)' já existe no projeto (ID: $($iterationField.id))." -ForegroundColor Green
            $iterationFieldId = $iterationField.id
        }
        else {
            # 2. Create the iteration field
            Write-Host "➕ Criando campo de iteração '$($iterationConfig.name)'..."
            
            $createFieldPayload = @{
                query     = $script:createIterationFieldMutation
                variables = @{
                    projectId = $projectId
                    name      = $iterationConfig.name
                    duration  = $iterationConfig.duration
                }
            } | ConvertTo-Json -Depth 5 -Compress

            try {
                $createFieldResult = $createFieldPayload | gh api graphql --input - | ConvertFrom-Json
                if ($createFieldResult.data.createProjectV2IterationField.projectV2Field) {
                    $iterationFieldId = $createFieldResult.data.createProjectV2IterationField.projectV2Field.id
                    Write-Host "✅ Campo de iteração '$($iterationConfig.name)' criado com sucesso (ID: $iterationFieldId)." -ForegroundColor Green
                }
                else {
                    Write-IterationFieldManualInstructions -iterationConfig $iterationConfig
                    return
                }
            }
            catch {
                Write-Warning "⚠️ Erro ao criar campo de iteração: $($_.Exception.Message)"
                Write-IterationFieldManualInstructions -iterationConfig $iterationConfig
                return
            }
        }

        Write-Host "`nℹ️ As iterações (Sprints) são gerenciadas diretamente no campo 'Sprint' do projeto GitHub." -ForegroundColor DarkYellow
        Write-Host "   Para informações detalhadas sobre como configurar as iterações (sprints), consulte o arquivo: '.\docs\campos-especiais.md'" -ForegroundColor Cyan

    }
    catch {
        Write-Warning "⚠️ Não foi possível verificar ou configurar o campo de iteração. Erro: $($_.Exception.Message)"
        Write-IterationFieldManualInstructions -iterationConfig $iterationConfig
    }
}

function Write-IterationFieldManualInstructions {
    param(
        [PSCustomObject]$iterationConfig
    )
    
    Write-Host "Por favor, crie o campo '$($iterationConfig.name)' manualmente na interface do GitHub com duração de $($iterationConfig.duration) dias."
    Write-Host "Consulte o arquivo '.\docs\campos-especiais.md' para mais detalhes sobre a configuração manual do campo de iteração e sprints." -ForegroundColor Cyan
}

Export-ModuleMember -Function Add-IterationField, Write-IterationFieldManualInstructions