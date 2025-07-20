param(
    [string]$owner = "",
    [string]$title = "",
    [string]$projectId = "",
    [string]$projectNumber = "",
    [string]$schemaPath = "",
    [switch]$useExisting = $false
)

$ErrorActionPreference = "Stop" # Garante que erros de comando param o script

# Importar módulos
$modulesDir = Join-Path $PSScriptRoot "modules"
Import-Module (Join-Path $modulesDir "Prerequisites.psm1") -Force
Import-Module (Join-Path $modulesDir "SchemaManager.psm1") -Force
Import-Module (Join-Path $modulesDir "ProjectManager.psm1") -Force

Write-Host "🔧 GitHub Project Setup - Automatização de configuração de projetos" -ForegroundColor Cyan
Write-Host "=======================================================================" -ForegroundColor Cyan

# 1. Verificar instalação e autenticação do GitHub CLI
if (-not (Test-GitHubCLI)) {
    return
}

# 2. Carregar schema
$schemaInfo = Get-ProjectSchema -schemaPath $schemaPath
if (-not $schemaInfo) {
    return
}
$schemaPath = $schemaInfo.Path

# 3. Determinar se vamos usar um projeto existente ou criar um novo
$isExistingProject = $useExisting -or $projectId -or $projectNumber

if ($isExistingProject) {
    Write-Host "`n📋 Configurando projeto existente..." -ForegroundColor Yellow
    
    # Obter proprietário se não foi especificado
    if (-not $owner) {
        $owner = Get-ProjectOwner
    }
    
    # Obter informações do projeto existente
    $projectInfo = Get-ExistingProject -owner $owner -projectId $projectId -projectNumber $projectNumber
    
    if ($projectInfo.IsExisting) {
        $owner = $projectInfo.Owner
        $title = $projectInfo.Title
        $projectId = $projectInfo.ProjectId
        $projectNumber = $projectInfo.ProjectNumber
        $projectUrl = $projectInfo.ProjectUrl
        
        Write-Host "`n🔄 Utilizando projeto existente:" -ForegroundColor Yellow
        Write-Host "   Título: $title"
        Write-Host "   ID: $projectId"
        Write-Host "   Número: $projectNumber"
        Write-Host "   Proprietário: $owner"
        Write-Host "   URL: $projectUrl"
    } else {
        $isExistingProject = $false
    }
}

# 4. Se não estamos usando um projeto existente, criar um novo
if (-not $isExistingProject) {
    # Obter proprietário se não foi especificado
    if (-not $owner) {
        $owner = Get-ProjectOwner
    }
    
    # Criar novo projeto
    $newProject = New-GitHubProject -owner $owner -title $title
    if (-not $newProject) {
        return
    }
    
    $owner = $newProject.Owner
    $title = $newProject.Title
    $projectId = $newProject.ProjectId
    $projectNumber = $newProject.ProjectNumber
    $projectUrl = $newProject.ProjectUrl
}

# 5. Configurar campos personalizados
Write-Host "`n🔧 Configurando campos personalizados (incluindo Iteração e excluindo Status)..." -ForegroundColor Yellow

try {
    $fieldConfigOutput = & "$PSScriptRoot\scripts\import-fields.ps1" -projectId $projectId -schemaPath $schemaPath 2>&1
    Write-Host ($fieldConfigOutput | Out-String)
}
catch {
    Write-Error "❌ Ocorreu um erro ao configurar os campos personalizados: $($_.Exception.Message)"
    Write-Host "Saída bruta do import-fields.ps1 (se houver):"
    Write-Host ($fieldConfigOutput | Out-String)
    return
}

# 6. Configurar colunas (status)
Write-Host "`n📊 Configurando colunas (Status)..." -ForegroundColor Yellow
$statusConfigResult = & "$PSScriptRoot\scripts\import-status-columns.ps1" -projectId $projectId -schemaPath $schemaPath
Write-Host $statusConfigResult

# 7. Verificar views
Write-Host "`n👁️ Verificando views..." -ForegroundColor Yellow
$viewCheckResult = & "$PSScriptRoot\scripts\check-views.ps1" -projectId $projectId -schemaPath $schemaPath
Write-Host $viewCheckResult

# 8. Salvar informações do projeto
Save-ProjectInfo -title $title -owner $owner -projectId $projectId -projectNumber $projectNumber -projectUrl $projectUrl

# 9. Resumo final
Write-Host "`n🎉 CONFIGURAÇÃO CONCLUÍDA!" -ForegroundColor Green
Write-Host "=======================================================================" -ForegroundColor Cyan
Write-Host "📝 Resumo do projeto:"
Write-Host "   Nome: $title"
Write-Host "   Proprietário: $owner"
Write-Host "   ID: $projectId"
Write-Host "   URL: $projectUrl"
Write-Host "`n🔍 Próximos passos:"
Write-Host "   1. Acesse o projeto na URL acima"
Write-Host "   2. Configure manualmente as views conforme instruções em .\docs\criar-views-manual.md"
Write-Host "   3. Adicione itens ao seu projeto"
Write-Host "`n✨ Processo concluído com sucesso!"
