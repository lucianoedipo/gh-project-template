function Get-ProjectOwner {
    param (
        [string]$owner = ""
    )

    if (-not $owner) {
        # Listar organizações do usuário
        Write-Host "`n📋 Buscando suas organizações..." -ForegroundColor Yellow
        $orgs = gh api user/orgs --jq ".[].login" | ForEach-Object { $_ }
        
        # Adicionar o usuário atual à lista de opções
        $currentUser = gh api user --jq ".login"
        $ownerOptions = @($currentUser) + $orgs
        
        Write-Host "Selecione o proprietário do projeto:"
        for ($i = 0; $i -lt $ownerOptions.Count; $i++) {
            Write-Host "[$i] $($ownerOptions[$i])"
        }
        
        $ownerIndex = Read-Host "Digite o número da opção desejada"
        $owner = $ownerOptions[$ownerIndex]
    }
    
    Write-Host "✅ Proprietário selecionado: $owner"
    return $owner
}

function Get-ExistingProject {
    param (
        [string]$owner,
        [string]$projectId,
        [string]$projectNumber
    )
    
    $projectInfo = @{
        IsExisting = $false
        Owner = $owner
        ProjectId = $projectId
        ProjectNumber = $projectNumber
        Title = ""
        ProjectUrl = ""
    }
    
    # Se não temos ID ou número do projeto, precisamos selecionar um
    if (-not $projectId -and -not $projectNumber) {
        # Listar projetos do proprietário
        Write-Host "`n📋 Projetos existentes para $($owner):" -ForegroundColor Yellow
        try {
            # Usando o comando cli com output em formato texto para garantir compatibilidade
            $projectListOutput = gh project list --owner $owner --limit 15
            
            # Processar a saída manualmente se for em formato texto
            $existingProjects = @()
            $projectListOutput | ForEach-Object {
                if ($_ -match '^\s*(\d+)\s+(.*?)\s+(open|closed)\s+(\S+)') {
                    $existingProjects += [PSCustomObject]@{
                        number = $Matches[1]
                        title  = $Matches[2].Trim()
                        state  = $Matches[3]
                        id     = $Matches[4]
                    }
                }
            }
            
            if ($existingProjects.Count -eq 0) {
                # Tentar alternativa com formato JSON
                $jsonOutput = gh project list --owner $owner --limit 15 --format json
                if ($jsonOutput) {
                    $existingProjects = $jsonOutput | ConvertFrom-Json
                }
            }
            
            if ($existingProjects.Count -eq 0) {
                Write-Host "❌ Não foram encontrados projetos para $owner. Verifique as permissões ou crie um novo."
                return $projectInfo
            }
            
            Write-Host "Selecione o projeto a ser configurado:"
            for ($i = 0; $i -lt $existingProjects.Count; $i++) {
                Write-Host "[$i] $($existingProjects[$i].title) (Número: $($existingProjects[$i].number))"
            }
            
            $projectIndex = Read-Host "Digite o número da opção desejada (ou deixe vazio para criar novo projeto)"
            
            if ([string]::IsNullOrWhiteSpace($projectIndex)) {
                return $projectInfo
            }
            
            $selectedProject = $existingProjects[$projectIndex]
            $projectInfo.ProjectNumber = $selectedProject.number
            $projectInfo.Title = $selectedProject.title
            
            # Buscar ID do projeto usando o número se não tivermos o ID
            if (-not $selectedProject.id -or $selectedProject.id -notmatch '^PVT_') {
                $projInfo = gh project view $projectInfo.ProjectNumber --owner $owner --format json | ConvertFrom-Json
                $projectInfo.ProjectId = $projInfo.id
            }
            else {
                $projectInfo.ProjectId = $selectedProject.id
            }
            
            $projectInfo.ProjectUrl = "https://github.com/orgs/$owner/projects/$($projectInfo.ProjectNumber)"
            $projectInfo.IsExisting = $true
            
            Write-Host "✅ Projeto selecionado: $($projectInfo.Title) (ID: $($projectInfo.ProjectId))"
        }
        catch {
            Write-Warning "⚠️ Erro ao listar projetos: $($_.Exception.Message)"
            Write-Host "Criando um novo projeto ao invés de usar um existente."
        }
    }
    else {
        # Temos ID ou número, mas precisamos do outro e validar
        if ($projectId -and -not $projectNumber) {
            # Buscar informações pelo ID
            $projInfo = gh api graphql --field projectId=$projectId -f query='
                query($projectId: ID!) {
                    node(id: $projectId) {
                        ... on ProjectV2 {
                            id
                            number
                            title
                            owner {
                                login
                            }
                        }
                    }
                }
            ' | ConvertFrom-Json
            
            if ($projInfo.data.node) {
                $projectInfo.ProjectNumber = $projInfo.data.node.number
                $projectInfo.Title = $projInfo.data.node.title
                $projectInfo.Owner = $projInfo.data.node.owner.login
                $projectInfo.ProjectUrl = "https://github.com/orgs/$($projectInfo.Owner)/projects/$($projectInfo.ProjectNumber)"
                $projectInfo.IsExisting = $true
                
                Write-Host "✅ Projeto encontrado: $($projectInfo.Title) (Número: $($projectInfo.ProjectNumber), Proprietário: $($projectInfo.Owner))"
            }
            else {
                Write-Error "❌ Projeto com ID $projectId não encontrado ou sem permissão."
            }
        }
        elseif ($projectNumber -and -not $projectId) {
            # Buscar informações pelo número
            $projInfo = gh project view $projectNumber --owner $owner --format json | ConvertFrom-Json
            
            if ($projInfo) {
                $projectInfo.ProjectId = $projInfo.id
                $projectInfo.Title = $projInfo.title
                $projectInfo.ProjectUrl = "https://github.com/orgs/$owner/projects/$projectNumber"
                $projectInfo.IsExisting = $true
                
                Write-Host "✅ Projeto encontrado: $($projectInfo.Title) (ID: $($projectInfo.ProjectId))"
            }
            else {
                Write-Error "❌ Projeto número $projectNumber do proprietário $owner não encontrado ou sem permissão."
            }
        }
    }
    
    return $projectInfo
}

function New-GitHubProject {
    param (
        [string]$owner,
        [string]$title
    )

    # Solicitar título do projeto, se não fornecido
    if (-not $title) {
        Write-Host "`n📋 Projetos existentes para ${owner}:" -ForegroundColor Yellow
        gh project list --owner $owner --limit 10
        
        $title = Read-Host "`nDigite um título para o novo projeto"
        if (-not $title) {
            Write-Error "❌ O título do projeto é obrigatório."
            return $null
        }
    }
    Write-Host "✅ Título do projeto: $title"

    # Criar o projeto
    Write-Host "`n🚀 Criando projeto '$title' para '$owner'..." -ForegroundColor Yellow
    $createResult = gh project create --owner $owner --title $title --format json
    if (-not $createResult) {
        Write-Error "❌ Falha ao criar o projeto."
        return $null
    }

    $projectInfo = $createResult | ConvertFrom-Json
    
    $result = @{
        Owner = $owner
        Title = $title
        ProjectId = $projectInfo.id
        ProjectNumber = $projectInfo.number
        ProjectUrl = $projectInfo.url
    }

    Write-Host "✅ Projeto criado com sucesso!" -ForegroundColor Green
    Write-Host "   ID: $($result.ProjectId)"
    Write-Host "   Número: $($result.ProjectNumber)"
    Write-Host "   URL: $($result.ProjectUrl)"
    
    return $result
}

function Save-ProjectInfo {
    param (
        [string]$title,
        [string]$owner,
        [string]$projectId,
        [string]$projectNumber,
        [string]$projectUrl
    )

    # Salvar informações do projeto para referência futura
    $projectConfig = @{
        name      = $title
        owner     = $owner
        id        = $projectId
        number    = $projectNumber
        url       = $projectUrl
        createdAt = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    } | ConvertTo-Json

    # Salvar em diretório de logs (que estará no .gitignore)
    $logsDir = ".\logs\projects"
    if (-not (Test-Path $logsDir)) {
        New-Item -ItemType Directory -Path $logsDir -Force | Out-Null
    }
    $logFile = Join-Path $logsDir "$owner-$($projectNumber).json"
    $projectConfig | Set-Content -Path $logFile

    Write-Host "`n💾 Informações do projeto salvas em: $logFile"
    
    return $logFile
}

Export-ModuleMember -Function Get-ProjectOwner, Get-ExistingProject, New-GitHubProject, Save-ProjectInfo
