# Funções para gerenciar campos regulares

# Importar o módulo de consultas GraphQL e utilidades
# Estes módulos estão na mesma pasta 'modules'
$graphqlModulePath = Join-Path $PSScriptRoot "graphql-queries.psm1"
Import-Module $graphqlModulePath -Force

$utilsModulePath = Join-Path $PSScriptRoot "utils.psm1"
Import-Module $utilsModulePath -Force



function Add-CustomFields {
    param(
        [Array]$fields,
        [string]$projectId
    )

    foreach ($field in $fields) {
        # Ignorar campo de iteração, pois é tratado separadamente
        if ($field.type -eq "iteration") {
            continue
        }

        $fieldInput = @{
            projectId = $projectId
            name      = $field.name
        }

        switch ($field.type) {
            "single_select" {
                $fieldInput.dataType = "SINGLE_SELECT"
                
                # Adicionar pelo menos uma opção no momento da criação do campo
                if ($field.options -and $field.options.Count -gt 0) {
                    $firstOption = $field.options[0]
                    $fieldInput.singleSelectOptions = @([PSCustomObject]@{ name = $firstOption.name; description = $firstOption.description; color = $firstOption.color })
                }
            }
            "number" {
                $fieldInput.dataType = "NUMBER"
            }
            "text" {
                $fieldInput.dataType = "TEXT"
            }
            default {
                Write-Log -Message "Tipo de campo desconhecido ou não suportado: $($field.type). Campo: $($field.name)" -Level Warning -Console
                continue
            }
        }

        Add-ProjectField -fieldInput $fieldInput -field $field
    }
}

function Add-ProjectField {
    param(
        [hashtable]$fieldInput,
        [PSCustomObject]$field
    )

    try {
        Write-Host "   🔄 Criando campo '$($field.name)' (Tipo: $($field.type))..." -ForegroundColor Cyan
        
        $tempFile = [System.IO.Path]::GetTempFileName()
        
        $mutationQuery = @{
            query = $createFieldMutation
            variables = @{
                input = $fieldInput
            }
        } | ConvertTo-Json -Depth 10 -Compress
        
        Set-Content -Path $tempFile -Value $mutationQuery -Encoding UTF8NoBOM

        # Executar consulta usando o arquivo como entrada
        # Redirecionar stderr para stdout para capturar erros do gh cli como parte da resposta
        $response = gh api graphql --input "$tempFile" 2>&1 
        
        Remove-Item -Path $tempFile -Force -ErrorAction SilentlyContinue 
        
        # O gh CLI em caso de erro pode não retornar JSON válido ou retornar uma string de erro
        # Vamos tentar converter para JSON para ver se há erros da API
        try {
            $resultObj = $response | ConvertFrom-Json -ErrorAction Stop
        }
        catch {
            # Se não for JSON, é um erro direto do gh CLI
            Write-Log -Message "Erro bruto do gh CLI ao criar campo '$($field.name)': $response" -Level Error -Console
            Write-Warning "⚠️ Campo '$($field.name)' não pôde ser criado devido a um erro no CLI. Verificando se já existe..."
            Update-ExistingField -projectId $fieldInput.projectId -field $field
            return
        }

        if ($resultObj.data.createProjectV2Field.projectV2Field) {
            $createdFieldName = $resultObj.data.createProjectV2Field.projectV2Field.name
            Write-Host "✅ Criado campo: $createdFieldName (Tipo: $($field.type))" -ForegroundColor Green
            
            # Se for single_select, adicionar as opções restantes
            if ($field.type -eq "single_select" -and $field.options -and $field.options.Count -gt 1) {
                $createdFieldId = $resultObj.data.createProjectV2Field.projectV2Field.id
                Add-SingleSelectOptions -fieldId $createdFieldId -fieldName $field.name -options $field.options
            }
        }
        elseif ($resultObj.errors) {
            $errorMsg = $resultObj.errors | ForEach-Object { $_.message } | Out-String
            
            # Verificar erro de campo já existente
            if ($errorMsg -match "Name has already been taken") {
                Write-Host "ℹ️ Campo '$($field.name)' já existe. Verificando opções..." -ForegroundColor Yellow
                Update-ExistingField -projectId $fieldInput.projectId -field $field
            }
            else {
                Write-Log -Message "Erro da API GitHub ao criar campo '$($field.name)': $errorMsg" -Level Error -Console
                Write-Warning "⚠️ Campo '$($field.name)' não pôde ser criado: $errorMsg"
            }
        }
    }
    catch {
        Write-Log -Message "Exceção inesperada ao criar campo '$($field.name)': $($_.Exception.Message)" -Level Error -Console
        Write-Warning "❌ Erro ao criar campo '$($field.name)'. Detalhes salvos no log."
    }
}

function Update-ExistingField {
    param(
        [string]$projectId,
        [PSCustomObject]$field
    )

    # Só prosseguir se for um campo de seleção única (que tem opções)
    if ($field.type -ne "single_select") {
        return
    }

    $queryPayload = @{
        query     = $getFieldsQuery
        variables = @{ projectId = $projectId }
    } | ConvertTo-Json -Depth 5 -Compress

    try {
        $existing = $queryPayload | gh api graphql --input - | ConvertFrom-Json
        $found = $existing.data.node.fields.nodes | Where-Object { $_.name -eq $field.name }

        if (-not $found) {
            Write-Log -Message "Não foi possível obter detalhes do campo existente '$($field.name)'. Verificação de opções ignorada." -Level Info -Console
            return
        }

        if ($field.type -eq "single_select") {
            Add-SingleSelectOptions -fieldId $found.id -fieldName $field.name -options $field.options -existingOptions $found.options
        }
    }
    catch {
        Write-Log -Message "Erro ao verificar campo existente '$($field.name)': $($_.Exception.Message)" -Level Error -Console
        Write-Warning "⚠️ Erro ao verificar campo existente '$($field.name)'."
    }
}

function Add-SingleSelectOptions {
    param(
        [string]$fieldId,
        [string]$fieldName,
        [Array]$options,
        [Array]$existingOptions = @(),
        [bool]$skipFirst = $false
    )

    $allOptions = @()
    $existingOptions | ForEach-Object { $allOptions += $_ }

    $startIndex = if ($skipFirst) { 1 } else { 0 }

    for ($i = $startIndex; $i -lt $options.Count; $i++) {
        $opt = $options[$i]
        if ($existingOptions.name -notcontains $opt.name) {
            $allOptions += $opt
        }
    }

    $updatePayload = @{
        query     = $updateStatusOptionsMutation
        variables = @{
            fieldId = $fieldId
            options = $allOptions
        }
    } | ConvertTo-Json -Depth 10 -Compress

    $updateResult = $updatePayload | gh api graphql --input -
    $resultObj = ConvertFrom-GhApiResponse -response $updateResult

    if ($resultObj -and $resultObj.data.updateProjectV2Field.projectV2Field) {
        Write-Host "   ✅ Opções do campo '$fieldName' atualizadas com sucesso." -ForegroundColor Green
    }
    else {
        Write-Log -Message "Falha ao atualizar opções do campo '$fieldName'. Resposta: $($updateResult | Out-String)" -Level Warning -Console
        Write-Warning "   ❌ Falha ao atualizar opções do campo '$fieldName'"
    }
}

# Exportar as funções com os novos nomes
Export-ModuleMember -Function Add-CustomFields, Add-ProjectField, Update-ExistingField, Add-SingleSelectOptions