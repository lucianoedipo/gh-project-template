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
            $projectListOutput = gh project list --owner $owner --limit 15 2>&1
            
            # Verificar se houve erro de permissão
            if ($projectListOutput -match "missing required scopes \[read:project\]") {
                Write-Host "⚠️ Seu token não tem permissão para listar projetos." -ForegroundColor Red
                Write-Host "   É necessário o escopo 'read:project' para esta operação." -ForegroundColor Yellow
                
                # Mostrar caminho simplificado para a documentação
                Write-Host "`n📘 Para instruções detalhadas de autenticação, consulte:" -ForegroundColor Cyan
                Write-Host "   .\docs\autenticacao.md" -ForegroundColor White
                
                Write-Host "`n   Você pode atualizar seu token criando um novo com as permissões necessárias:" -ForegroundColor Cyan
                Write-Host "   1. Crie um novo token em: https://github.com/settings/tokens" -ForegroundColor White
                Write-Host "   2. Faça logout: gh auth logout" -ForegroundColor White 
                Write-Host "   3. Faça login com novo token: gh auth login" -ForegroundColor White
                
                $refreshToken = Read-Host "`nDeseja abrir o navegador para criar um novo token? (S/N)"
                if ($refreshToken -eq "S" -or $refreshToken -eq "s") {
                    Start-Process "https://github.com/settings/tokens/new?scopes=repo%20admin:org%20project%20read:project"
                    $waitForManual = Read-Host "Pressione Enter quando tiver criado o token e feito login"
                    
                    # Verificar se o token foi atualizado
                    gh auth status -h github.com
                    $projectListOutput = gh project list --owner $owner --limit 15 2>&1
                }
                
                # Se ainda não conseguimos listar, oferecer opções alternativas
                if ($projectListOutput -match "missing required scopes") {
                    Write-Host "`n🔍 Escolha uma das opções para continuar:" -ForegroundColor Yellow
                    Write-Host "  [1] Informar manualmente o ID do projeto"
                    Write-Host "  [2] Informar manualmente o número do projeto"
                    Write-Host "  [3] Criar um novo projeto"
                    Write-Host "  [4] Cancelar operação"
                    Write-Host "  [5] Tentar novamente listar projetos" -ForegroundColor Cyan
                    
                    $option = Read-Host "`nDigite sua escolha (1-5)"
                    
                    switch ($option) {
                        "1" {
                            $manualProjectId = Read-Host "Digite o ID do projeto (formato PVT_xxx)"
                            if ($manualProjectId) {
                                $projectInfo.ProjectId = $manualProjectId
                                # Tentar obter informações adicionais usando o ID
                                $projInfo = gh api graphql --field projectId=$manualProjectId -f query='
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
                                ' 2>&1
                                
                                if ($projInfo -notmatch "error") {
                                    $projObj = $projInfo | ConvertFrom-Json
                                    if ($projObj.data.node) {
                                        $projectInfo.ProjectNumber = $projObj.data.node.number
                                        $projectInfo.Title = $projObj.data.node.title
                                        $projectInfo.Owner = $projObj.data.node.owner.login
                                        $projectInfo.ProjectUrl = "https://github.com/orgs/$($projectInfo.Owner)/projects/$($projectInfo.ProjectNumber)"
                                        $projectInfo.IsExisting = $true
                                        
                                        Write-Host "✅ Projeto encontrado: $($projectInfo.Title) (Número: $($projectInfo.ProjectNumber), Proprietário: $($projectInfo.Owner))" -ForegroundColor Green
                                    }
                                    else {
                                        Write-Host "ℹ️ Usando ID informado, mas não foi possível obter detalhes completos." -ForegroundColor Yellow
                                        $projectInfo.Title = "Projeto Existente"
                                        $projectInfo.IsExisting = $true
                                    }
                                }
                                else {
                                    Write-Host "ℹ️ Usando ID informado, mas não foi possível obter detalhes completos." -ForegroundColor Yellow
                                    $projectInfo.Title = "Projeto Existente"
                                    $projectInfo.IsExisting = $true
                                }
                            }
                        }
                        "2" {
                            $manualProjectNumber = Read-Host "Digite o número do projeto"
                            if ($manualProjectNumber) {
                                $projectInfo.ProjectNumber = $manualProjectNumber
                                $projectInfo.Title = "Projeto #$manualProjectNumber"
                                $projectInfo.ProjectUrl = "https://github.com/orgs/$owner/projects/$manualProjectNumber"
                                $projectInfo.IsExisting = $true
                                Write-Host "ℹ️ Usando número de projeto informado: #$manualProjectNumber" -ForegroundColor Yellow
                            }
                        }
                        "3" {
                            Write-Host "ℹ️ Você optou por criar um novo projeto." -ForegroundColor Yellow
                            return $projectInfo # IsExisting = false para criar novo
                        }
                        "4" {
                            Write-Host "❌ Operação cancelada pelo usuário." -ForegroundColor Red
                            exit
                        }
                        "5" {
                            Write-Host "🔄 Tentando listar projetos novamente..." -ForegroundColor Cyan
                            return Get-ExistingProject -owner $owner -projectId $projectId -projectNumber $projectNumber
                        }
                        default {
                            Write-Host "❌ Opção inválida. Cancelando operação." -ForegroundColor Red
                            exit
                        }
                    }
                    
                    return $projectInfo
                }
            }
            
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
        [string]$projectUrl,
        [string]$fieldConfigOutput,
        [string]$statusConfigResult,
        [string]$viewCheckResult
    )

    # Salvar informações do projeto para referência futura
    $projectConfig = @{
        name                = $title
        owner               = $owner
        id                  = $projectId
        number              = $projectNumber
        url                 = $projectUrl
        createdAt           = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
        'fieldConfiguration' = $fieldConfigOutput
        'statusConfiguration' = $statusConfigResult
        'viewCheck'         = $viewCheckResult
    } | ConvertTo-Json

    # Gerar timestamp para o nome do arquivo
    $timestamp = (Get-Date).ToString("yyyy-MM-dd-HHmmss")
    
    # Salvar em diretório de logs (que estará no .gitignore)
    $logsDir = ".\logs\projects"
    try {
        if (-not (Test-Path $logsDir)) {
            New-Item -ItemType Directory -Path $logsDir -Force | Out-Null
        }
        $logFile = Join-Path $logsDir "project-config-$timestamp.json"
        $projectConfig | Set-Content -Path $logFile -ErrorAction Stop
        Write-Host "`n💾 Informações do projeto salvas em: $logFile"
    }
    catch {
        $errorMessageDetail = $_.Exception.Message
        Write-Error "❌ Erro ao salvar informações do projeto em ${logFile}: $errorMessageDetail"
    }
    
    return $logFile
}

# Exporta as funções para que possam ser usadas em outros scripts ou no console
Export-ModuleMember -Function Get-ProjectOwner, Get-ExistingProject, New-GitHubProject, Save-ProjectInfo