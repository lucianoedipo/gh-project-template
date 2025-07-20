# Funções para gerenciar campos regulares

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
                Write-Warning "⚠️ Tipo de campo desconhecido ou não suportado para criação via API: $($field.type). Campo: $($field.name)"
                continue
            }
        }

        Create-Field -fieldInput $fieldInput -field $field
    }
}

function Create-Field {
    param(
        [hashtable]$fieldInput,
        [PSCustomObject]$field
    )

    $createPayload = @{
        query     = $script:createFieldMutation
        variables = @{ input = $fieldInput }
    } | ConvertTo-Json -Depth 10 -Compress

    try {
        Write-Host "   🔄 Criando campo '$($field.name)' (Tipo: $($field.type))..." -ForegroundColor Cyan
        
        $response = $createPayload | gh api graphql --input - --header "Content-Type: application/json" 2>&1
        
        # Extrair e processar o JSON da resposta
        $resultObj = Process-GhApiResponse -response $response
        
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
                Write-Warning "⚠️ Erro retornado pela API: $errorMsg"
                Write-Host "   Continuando com próximos campos..."
            }
        }
        else {
            Write-Warning "⚠️ Não foi possível processar a resposta da API"
            Write-Host "   Resposta bruta: $response"
        }
    }
    catch {
        # Lidar com campo já existente
        if ($_.Exception.Message -like '*Name has already been taken*') {
            Write-Host "⚠️ Campo '$($field.name)' já existe. Verificando opções (se for single_select)..." -ForegroundColor Yellow
            Handle-ExistingField -projectId $fieldInput.projectId -field $field
        }
        else {
            Write-Error "❌ Erro inesperado ao criar campo '$($field.name)': $($_.Exception.Message)"
            Write-Host "Resposta GH CLI (se houver):`n$response"
        }
    }
}

function Handle-ExistingField {
    param(
        [string]$projectId,
        [PSCustomObject]$field
    )

    $queryPayload = @{
        query     = $script:getFieldsQuery
        variables = @{ projectId = $projectId }
    } | ConvertTo-Json -Depth 5 -Compress

    try {
        $existing = $queryPayload | gh api graphql --input - --header "Content-Type: application/json" | ConvertFrom-Json
        $found = $existing.data.node.fields.nodes | Where-Object { $_.name -eq $field.name }

        if (-not $found) {
            Write-Warning "❌ Campo '$($field.name)' não encontrado apesar do erro de nome já usado. Pode ser um tipo diferente."
            return
        }

        if ($field.type -eq "single_select") {
            Add-SingleSelectOptions -fieldId $found.id -fieldName $field.name -options $field.options -existingOptions $found.options
        }
        else {
            Write-Host "   Campo '$($field.name)' (Tipo: $($field.type)) já existe e não é um campo de seleção única, ignorando opções."
        }
    }
    catch {
        Write-Warning "⚠️ Erro ao verificar ou adicionar opções para campo existente '$($field.name)': $($_.Exception.Message)"
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

    $existingOptionNames = $existingOptions.name
    $startIndex = if ($skipFirst) { 1 } else { 0 }

    for ($i = $startIndex; $i -lt $options.Count; $i++) {
        $opt = $options[$i]
        
        if ($existingOptionNames -contains $opt.name) {
            Write-Host "   ✅ Opção já existe: $($opt.name)"
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
        $addResultObj = Process-GhApiResponse -response $addResult
        
        if ($addResultObj -and $addResultObj.data.addProjectV2SingleSelectFieldOption.singleSelectFieldOption) {
            Write-Host "   ➕ Adicionada nova opção: $($opt.name) ao campo '$fieldName'"
        }
        else {
            Write-Warning "   ❌ Falha ao adicionar opção '$($opt.name)' ao campo '$fieldName'"
        }
    }
}

