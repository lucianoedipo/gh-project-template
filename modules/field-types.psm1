# Funções para gerenciar campos regulares

# Importar o módulo de consultas GraphQL e utilidades
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
        # Skip iteration field, as it's handled separately
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
                    $fieldInput.singleSelectOptions = @(
                        @{
                            name        = $firstOption.name
                            description = $firstOption.description
                            color       = $firstOption.color
                        }
                    )
                }
            }
            "number" {
                $fieldInput.dataType = "NUMBER"
            }
            "text" {
                $fieldInput.dataType = "TEXT"
            }
            default {
                Write-Warning "⚠️ Tipo de campo desconhecido ou não suportado: $($field.type). Campo: $($field.name)"
                continue
            }
        }

        # Renomeado para usar verbo aprovado
        Add-ProjectField -fieldInput $fieldInput -field $field
    }
}

# Renomeada de Create-Field para Add-ProjectField (verbo aprovado)
function Add-ProjectField {
    param(
        [hashtable]$fieldInput,
        [PSCustomObject]$field
    )

    # Remover a verificação redundante e usar diretamente a consulta do módulo importado
    $createPayload = @{
        query     = $script:createFieldMutation
        variables = @{ input = $fieldInput }
    } | ConvertTo-Json -Depth 10 -Compress

    try {
        Write-Host "   🔄 Criando campo '$($field.name)' (Tipo: $($field.type))..." -ForegroundColor Cyan
        
        $response = $createPayload | gh api graphql --input - --header "Content-Type: application/json" 2>&1
        
        # Extrair e processar o JSON da resposta
        $resultObj = ConvertFrom-GhApiResponse -response $response
        
        if ($resultObj -and $resultObj.data.createProjectV2Field.projectV2Field) {
            $createdFieldName = $resultObj.data.createProjectV2Field.projectV2Field.name
            Write-Host "✅ Criado campo: $createdFieldName (Tipo: $($field.type))" -ForegroundColor Green

            # If it's a single_select, add remaining options
            if ($field.type -eq "single_select" -and $field.options -and $field.options.Count -gt 1) {
                $createdFieldId = $resultObj.data.createProjectV2Field.projectV2Field.id
                Add-SingleSelectOptions -fieldId $createdFieldId -fieldName $field.name -options $field.options -skipFirst $true
            }
        }
        elseif ($resultObj -and $resultObj.errors) {
            $errorMsg = $resultObj.errors | ForEach-Object { $_.message } | Out-String
            
            # Verificar se o erro é sobre campo já existente
            if ($errorMsg -like '*Name has already been taken*') {
                throw [System.Exception]::new("Name has already been taken")
            }
            else {
                Write-Warning "⚠️ Erro ao criar campo '$($field.name)': $errorMsg"
            }
        }
        else {
            Write-Warning "⚠️ Não foi possível processar a resposta da API para o campo '$($field.name)'"
            Write-Verbose "Resposta bruta: $response"
        }
    }
    catch {
        # Lidar com campo já existente
        if ($_.Exception.Message -like '*Name has already been taken*') {
            # Para campos single_select, verificamos as opções
            if ($field.type -eq "single_select") {
                Write-Host "⚠️ Campo '$($field.name)' já existe. Verificando opções..." -ForegroundColor Yellow
                Update-ExistingField -projectId $fieldInput.projectId -field $field
            } 
            else {
                # Para outros tipos, apenas informamos que o campo já existe
                Write-Host "ℹ️ Campo '$($field.name)' (Tipo: $($field.type)) já existe." -ForegroundColor Cyan
            }
        }
        else {
            Write-Error "❌ Erro ao criar campo '$($field.name)': $($_.Exception.Message)"
            Write-Verbose "Resposta GH CLI (se houver): $response"
        }
    }
}

# Renomeada de Handle-ExistingField para Update-ExistingField
function Update-ExistingField {
    param(
        [string]$projectId,
        [PSCustomObject]$field
    )

    # Só prosseguir se for um campo de seleção única (que tem opções)
    if ($field.type -ne "single_select") {
        return
    }

    # Remover a verificação redundante e usar diretamente a consulta do módulo importado
    $queryPayload = @{
        query     = $script:getFieldsQuery
        variables = @{ projectId = $projectId }
    } | ConvertTo-Json -Depth 5 -Compress

    try {
        $existing = $queryPayload | gh api graphql --input - --header "Content-Type: application/json" | ConvertFrom-Json
        $found = $existing.data.node.fields.nodes | Where-Object { $_.name -eq $field.name }

        if (-not $found) {
            # Em vez de mostrar um aviso, usamos uma mensagem informativa e menos assustadora
            Write-Host "ℹ️ Não foi possível obter detalhes do campo existente '$($field.name)'. Verificação de opções ignorada." -ForegroundColor Yellow
            return
        }

        if ($field.type -eq "single_select") {
            Add-SingleSelectOptions -fieldId $found.id -fieldName $field.name -options $field.options -existingOptions $found.options
        }
    }
    catch {
        Write-Warning "⚠️ Erro ao verificar campo existente '$($field.name)': $($_.Exception.Message)"
    }
}

# Esta função mantém o nome pois já usa um verbo aprovado (Add)
function Add-SingleSelectOptions {
    param(
        [string]$fieldId,
        [string]$fieldName,
        [Array]$options,
        [Array]$existingOptions = @(),
        [bool]$skipFirst = $false
    )

    # Remover a verificação redundante e usar diretamente a consulta do módulo importado
    $existingOptionNames = $existingOptions.name
    $startIndex = if ($skipFirst) { 1 } else { 0 }

    for ($i = $startIndex; $i -lt $options.Count; $i++) {
        $opt = $options[$i]
        
        if ($existingOptionNames -contains $opt.name) {
            Write-Host "   ✅ Opção já existe: $($opt.name)" -ForegroundColor Green
            continue
        }

        $addPayload = @{
            query     = $script:addOptionMutation
            variables = @{
                fieldId     = $fieldId
                name        = $opt.name
                description = $opt.description
                color       = $opt.color
            }
        } | ConvertTo-Json -Depth 10 -Compress

        $addResult = $addPayload | gh api graphql --input - --header "Content-Type: application/json"
        $addResultObj = ConvertFrom-GhApiResponse -response $addResult
        
        if ($addResultObj -and $addResultObj.data.addProjectV2SingleSelectFieldOption.singleSelectFieldOption) {
            Write-Host "   ➕ Adicionada nova opção: $($opt.name) ao campo '$fieldName'" -ForegroundColor Green
        }
        else {
            Write-Warning "   ❌ Falha ao adicionar opção '$($opt.name)' ao campo '$fieldName'"
        }
    }
}

# Exportar as funções com os novos nomes
Export-ModuleMember -Function Add-CustomFields, Add-ProjectField, Update-ExistingField, Add-SingleSelectOptions