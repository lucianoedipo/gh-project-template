function Get-ProjectSchema {
    param (
        [string]$schemaPath = ""
    )

    # Se não foi fornecido um caminho, detectar automaticamente os schemas disponíveis
    if ([string]::IsNullOrEmpty($schemaPath)) {
        $templatesDir = Join-Path $PSScriptRoot "..\templates"
        $schemaFiles = Get-ChildItem -Path "$templatesDir\*.json" -ErrorAction SilentlyContinue
        
        if ($schemaFiles.Count -eq 0) {
            Write-Error "❌ Nenhum arquivo de schema encontrado na pasta templates."
            return $null
        }
        elseif ($schemaFiles.Count -eq 1) {
            # Se há apenas um schema, usar automaticamente
            $schemaPath = $schemaFiles[0].FullName
            Write-Host "ℹ️ Usando o único schema disponível: $($schemaFiles[0].Name)" -ForegroundColor Yellow
        }
        else {
            # Se há múltiplos schemas, permitir a seleção
            Write-Host "`n📋 Múltiplos schemas disponíveis. Selecione um:" -ForegroundColor Yellow
            for ($i = 0; $i -lt $schemaFiles.Count; $i++) {
                $schemaName = [System.IO.Path]::GetFileNameWithoutExtension($schemaFiles[$i].Name)
                Write-Host "[$i] $schemaName"
            }
            
            $schemaIndex = Read-Host "Digite o número da opção desejada"
            
            if ([string]::IsNullOrWhiteSpace($schemaIndex) -or $schemaIndex -lt 0 -or $schemaIndex -ge $schemaFiles.Count) {
                Write-Error "❌ Seleção inválida. Usando o primeiro schema disponível."
                $schemaPath = $schemaFiles[0].FullName
            } else {
                $schemaPath = $schemaFiles[$schemaIndex].FullName
            }
        }
    }

    if (-not (Test-Path $schemaPath)) {
        Write-Error "❌ Arquivo de schema não encontrado em: $schemaPath"
        return $null
    }
    
    try {
        $schema = Get-Content -Path $schemaPath -Raw | ConvertFrom-Json
        Write-Host "✅ Schema carregado com sucesso: $schemaPath" -ForegroundColor Green
        
        return @{
            Path = $schemaPath
            Schema = $schema
        }
    }
    catch {
        Write-Error "❌ Erro ao carregar o schema: $($_.Exception.Message)"
        return $null
    }
}

# Função para validar se um schema tem uma estrutura mínima necessária
function Test-SchemaStructure {
    param(
        [Parameter(Mandatory=$true)]
        [PSCustomObject]$schema
    )
    
    $isValid = $true
    $errors = @()
    
    # Verificar campos obrigatórios
    if (-not (Get-Member -InputObject $schema -Name "fields" -MemberType Properties)) {
        $isValid = $false
        $errors += "Schema não contém a propriedade 'fields'"
    }
    
    # Verificar estrutura de campos
    if ($isValid -and $schema.fields -is [array]) {
        foreach ($field in $schema.fields) {
            if (-not (Get-Member -InputObject $field -Name "name" -MemberType Properties)) {
                $isValid = $false
                $errors += "Um campo não tem a propriedade 'name'"
                break
            }
            if (-not (Get-Member -InputObject $field -Name "type" -MemberType Properties)) {
                $isValid = $false
                $errors += "Campo '$($field.name)' não tem a propriedade 'type'"
                break
            }
        }
    }
    
    return @{
        IsValid = $isValid
        Errors = $errors
    }
}

Export-ModuleMember -Function Get-ProjectSchema, Test-SchemaStructure
