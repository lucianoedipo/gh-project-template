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

    # 1. Verificar se o campo de iteração já existe
    $checkPayload = @{
        query     = $script:getFieldsQuery
        variables = @{ projectId = $projectId }
    } | ConvertTo-Json -Depth 5 -Compress
    
    try {
        $tempFileCheck = [System.IO.Path]::GetTempFileName()
        Set-Content -Path $tempFileCheck -Value $checkPayload -Encoding UTF8NoBOM
        
        # Remover linha de debug
        # Write-Host "DEBUG: Temp JSON file content for checkPayload: $(Get-Content -Path $tempFileCheck | Out-String)" -ForegroundColor Magenta
        
        try {
            $checkResult = gh api graphql --input "$tempFileCheck" 2>&1
            Remove-Item -Path $tempFileCheck -Force -ErrorAction SilentlyContinue
            
            try {
                $checkResultObj = $checkResult | ConvertFrom-Json -ErrorAction Stop
                $iterationField = $checkResultObj.data.node.fields.nodes | Where-Object { 
                    $_.name -eq $iterationConfig.name -and $_.dataType -eq "ITERATION" 
                }
                
                if ($iterationField) {
                    Write-Output "✅ Campo de iteração '$($iterationConfig.name)' já existe no projeto (ID: $($iterationField.id))."
                    $iterationFieldId = $iterationField.id
                }
                else {
                    # 2. Criar o campo de iteração
                    Write-Output "➕ Criando campo de iteração '$($iterationConfig.name)'..."
                    
                    # Remover parâmetro de duração que não é aceito na criação inicial
                    $createFieldPayload = @{
                        query     = $script:createIterationFieldMutation
                        variables = @{
                            projectId = $projectId
                            name      = $iterationConfig.name
                        }
                    } | ConvertTo-Json -Depth 10 -Compress
    
                    $tempFileCreate = [System.IO.Path]::GetTempFileName()
                    Set-Content -Path $tempFileCreate -Value $createFieldPayload -Encoding UTF8NoBOM
                    
                    # Remover linha de debug
                    # Write-Host "DEBUG: Temp JSON file content for createFieldPayload: $(Get-Content -Path $tempFileCreate | Out-String)" -ForegroundColor Magenta
                    
                    try {
                        $createFieldResult = gh api graphql --input "$tempFileCreate" 2>&1
                        Remove-Item -Path $tempFileCreate -Force -ErrorAction SilentlyContinue
                        
                        try {
                            $createResultObj = $createFieldResult | ConvertFrom-Json -ErrorAction Stop
                            # Ajustar o caminho dos dados na resposta para corresponder à nova mutação
                            if ($createResultObj.data.createProjectV2Field.projectV2Field) {
                                $iterationFieldId = $createResultObj.data.createProjectV2Field.projectV2Field.id
                                Write-Output "✅ Campo de iteração '$($iterationConfig.name)' criado com sucesso (ID: $iterationFieldId)."
                                
                                # Configurar a duração em uma etapa separada se necessário
                                Write-Output "ℹ️ A duração da iteração ($($iterationConfig.duration) dias) deve ser configurada manualmente na interface do GitHub."
                            }
                            else {
                                Write-IterationFieldManualInstructions -iterationConfig $iterationConfig
                                return
                            }
                        }
                        catch {
                            Write-Warning "⚠️ Erro ao processar resposta da criação: $createFieldResult"
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
            }
            catch {
                Write-Warning "⚠️ Erro ao processar resposta da verificação: $checkResult"
                Write-IterationFieldManualInstructions -iterationConfig $iterationConfig
                return
            }
        }
        catch {
            Write-Warning "⚠️ Erro ao verificar campo de iteração: $($_.Exception.Message)"
            Write-IterationFieldManualInstructions -iterationConfig $iterationConfig
            return
        }

        Write-Output "`nℹ️ As iterações (Sprints) são gerenciadas diretamente no campo 'Sprint' do projeto GitHub."
        Write-Output "   Para informações detalhadas sobre como configurar as iterações (sprints), consulte o arquivo: '.\docs\campos-especiais.md'"

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
    
    Write-Output "Por favor, crie o campo '$($iterationConfig.name)' manualmente na interface do GitHub com duração de $($iterationConfig.duration) dias."
    Write-Output "Consulte o arquivo '.\docs\campos-especiais.md' para mais detalhes sobre a configuração manual do campo de iteração e sprints."
}

Export-ModuleMember -Function Add-IterationField, Write-IterationFieldManualInstructions