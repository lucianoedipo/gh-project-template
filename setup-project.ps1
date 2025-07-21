<#
.SYNOPSIS
    Automatiza a configuração de projetos GitHub Projects.
    Cria ou configura um projeto existente, adicionando campos personalizados e colunas de status com base em um schema JSON.

.DESCRIPTION
    Este script simplifica o processo de setup de projetos GitHub Projects V2.
    Ele verifica a instalação do GitHub CLI, carrega um schema de configuração,
    cria um novo projeto ou utiliza um existente, e então configura os campos
    personalizados (incluindo campos de iteração e colunas de status)
    e exibe um resumo final com os próximos passos.

.PARAMETER owner
    O nome de usuário do proprietário do projeto (organização ou usuário).
    Se não for fornecido, o script tentará descobrir o proprietário através do GitHub CLI.

.PARAMETER title
    O título do novo projeto a ser criado. Necessário se -useExisting não for especificado.

.PARAMETER projectId
    O ID do projeto GitHub existente a ser configurado. Usar em conjunto com -useExisting.

.PARAMETER projectNumber
    O número do projeto GitHub existente a ser configurado (para projetos de usuário ou organização).
    Usar em conjunto com -useExisting se o projectId não for conhecido.

.PARAMETER schemaPath
    O caminho para o arquivo JSON do schema de configuração do projeto.
    Ex: '.\schemas\my-project-schema.schema.json'

.PARAMETER useExisting
    Um switch que indica que um projeto existente deve ser usado em vez de criar um novo.
    Requer projectId ou projectNumber.

.PARAMETER ListSchemas
    Um switch que, quando presente, lista os schemas de projeto disponíveis na pasta 'schemas'
    e encerra o script.

.EXAMPLE
    .\setup-project.ps1 -title "Meu Novo Projeto Scrum" -owner "minha-organizacao" -schemaPath ".\schemas\project-schema.schema.json"
    Cria um novo projeto com o título especificado e configura-o usando o schema fornecido.

.EXAMPLE
    .\setup-project.ps1 -useExisting -projectId "PVT_ABCD123" -schemaPath ".\schemas\project-schema.schema.json"
    Configura um projeto existente pelo seu ID, aplicando o schema.

.EXAMPLE
    .\setup-project.ps1 -useExisting -projectNumber 123 -owner "minha-organizacao" -schemaPath ".\schemas\project-schema.schema.json"
    Configura um projeto existente pelo seu número e proprietário, aplicando o schema.

.EXAMPLE
    Get-Help .\setup-project.ps1 -Full
    Exibe a ajuda completa do script, incluindo descrição e exemplos.

.EXAMPLE
    .\setup-project.ps1 -ListSchemas
    Lista todos os arquivos de schema JSON disponíveis na pasta 'schemas'.

.NOTES
    Certifique-se de que o GitHub CLI esteja instalado e autenticado.
    As funções de logging e utilitários são importadas dos módulos 'global-functions.psm1' e 'utils.psm1'.
#>
param(
    [string]$owner = "",
    [string]$title = "",
    [string]$projectId = "",
    [string]$projectNumber = "",
    [string]$schemaPath = "",
    [switch]$useExisting = $false,
    [switch]$ListSchemas,
    [switch]$Help
)

# --- Fallback para parâmetros desconhecidos / Help explícito ---
if ($Help -or ($args -contains "--help" -or $args -contains "-?") -and -not $ListSchemas) {
    Write-Host "Comando de ajuda reconhecido. Por favor, use 'Get-Help .\setup-project.ps1 -Full' para obter a documentação completa." -ForegroundColor Green
    Get-Help $PSScriptRoot\setup-project.ps1 -Full
    return
}
# -----------------------------------------------------------------

# Importar módulos com verificação
$modulesDir = Join-Path $PSScriptRoot "modules"
Remove-Module -Name Prerequisites -ErrorAction SilentlyContinue
Remove-Module -Name SchemaManager -ErrorAction SilentlyContinue
Remove-Module -Name ProjectManager -ErrorAction SilentlyContinue
Remove-Module -Name global-functions -ErrorAction SilentlyContinue
Remove-Module -Name utils -ErrorAction SilentlyContinue
Import-Module (Join-Path $modulesDir "Prerequisites.psm1") -Force
Import-Module (Join-Path $modulesDir "SchemaManager.psm1") -Force
Import-Module (Join-Path $modulesDir "ProjectManager.psm1") -Force
Import-Module (Join-Path $modulesDir "global-functions.psm1") -Force
Import-Module (Join-Path $modulesDir "utils.psm1") -Force

Write-Host "🔧 GitHub Project Setup - Automatização de configuração de projetos" -ForegroundColor Cyan
Write-Host "=======================================================================" -ForegroundColor Cyan

# Lógica para listar schemas e sair
if ($ListSchemas) {
    Write-Host "`n📝 Schemas de Projeto Disponíveis em '$($PSScriptRoot)\schemas\':" -ForegroundColor Cyan
    $schemasDir = Join-Path $PSScriptRoot "schemas"
    if (Test-Path $schemasDir) {
        Get-ChildItem -Path $schemasDir -Filter "*.json" | ForEach-Object {
            Write-Host "  - $($_.Name)"
        }
    } else {
        Write-Host "  Nenhum diretório 'schemas' encontrado em '$PSScriptRoot'." -ForegroundColor Yellow
    }
    Write-Host "`nUse um desses nomes com o parâmetro -schemaPath." -ForegroundColor Green
    return
}


# 1. Verificar instalação e autenticação do GitHub CLI
if (-not (Test-GitHubCLI)) {
    Write-Log -Message "Pré-requisitos do GitHub CLI não atendidos. Encerrando." -Level Error -Console
    return
}

# 2. Carregar schema
$schemaInfo = Get-ProjectSchema -schemaPath $schemaPath
if (-not $schemaInfo) {
    if (-not $schemaPath) {
        Write-Log -Message "O parâmetro -schemaPath é obrigatório para configurar um projeto." -Level Error -Console
        Write-Host "`n❌ Erro: O parâmetro -schemaPath é obrigatório para configurar um projeto." -ForegroundColor Red
        Write-Host "       Use 'Get-Help .\setup-project.ps1' para mais informações ou execute '.\setup-project.ps1 -ListSchemas' para ver as opções." -ForegroundColor Yellow
    }
    return
}
$schemaPath = $schemaInfo.Path

# 3. Determinar se vamos usar um projeto existente ou criar um novo
$isExistingProject = $useExisting -or $projectId -or $projectNumber

if ($isExistingProject) {
    Write-Host "`n📋 Configurando projeto existente..." -ForegroundColor Yellow
    
    if (-not $owner) {
        $owner = Get-ProjectOwner -owner $owner
        if (-not $owner) {
            Write-Log -Message "Não foi possível determinar o proprietário do projeto." -Level Error -Console
            return
        }
    }
    
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
        if ($useExisting) {
            Write-Log -Message "Nenhum projeto existente foi selecionado ou encontrado com os parâmetros fornecidos. Encerrando." -Level Error -Console
            Write-Host "`n❌ Erro: Nenhum projeto existente foi selecionado ou encontrado. Encerrando." -ForegroundColor Red
            return # Exit if -useExisting was specified and no project was found/selected
        } else {
            Write-Log -Message "Projeto existente (ID: $projectId, Número: $projectNumber, Proprietário: $owner) não encontrado. Tentando criar um novo." -Level Warning -Console
            $isExistingProject = $false
        }
    }
}

# 4. Se não estamos usando um projeto existente, criar um novo
if (-not $isExistingProject) {
    # Removida a validação forte de -title aqui. O PowerShell solicitará se faltar.

    if (-not $owner) {
        $owner = Get-ProjectOwner -owner $owner
        if (-not $owner) {
            Write-Log -Message "Não foi possível determinar o proprietário do projeto." -Level Error -Console
            return
        }
    }
    
    $newProject = New-GitHubProject -owner $owner -title $title
    if (-not $newProject) {
        Write-Log -Message "Falha ao criar um novo projeto GitHub." -Level Error -Console
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
    $importFieldsScriptPath = Join-Path $PSScriptRoot "scripts\import-fields.ps1"
    $rawFieldOutput = & $importFieldsScriptPath -projectId $projectId -schemaPath $schemaPath 6>&1 *>&1
    $fieldConfigOutput = $rawFieldOutput | Out-String
    Write-Host $fieldConfigOutput # Explicitly write to console
}
catch {
    $errorMessage = $_.Exception.Message
    Write-Log -Message "Ocorreu um erro ao configurar os campos personalizados: $errorMessage" -Level Error -Console
    Write-Host "Consulte o arquivo de log para detalhes completos: $PSScriptRoot\logs\setup.log" -ForegroundColor Yellow
    $fieldConfigOutput = "Erro: $errorMessage"
}

# 6. Configurar colunas (status)
Write-Host "`n📊 Configurando colunas (Status)..." -ForegroundColor Yellow
try {
    $importStatusScriptPath = Join-Path $PSScriptRoot "scripts\import-status-columns.ps1"
    $rawStatusOutput = & $importStatusScriptPath -projectId $projectId -schemaPath $schemaPath 6>&1 *>&1
    $statusConfigResult = $rawStatusOutput | Out-String
    Write-Host $statusConfigResult # Explicitly write to console
}
catch {
    Write-Log -Message "Erro ao configurar colunas de status: $($_.Exception.Message)" -Level Error -Console
    $statusConfigResult = "Erro: $($_.Exception.Message)"
}

# 7. Verificar views
Write-Host "`n👁️ Verificando views..." -ForegroundColor Yellow
try {
    $checkViewsScriptPath = Join-Path $PSScriptRoot "scripts\check-views.ps1"
    $rawViewOutput = & $checkViewsScriptPath -projectId $projectId -schemaPath $schemaPath 6>&1 *>&1
    $viewCheckResult = $rawViewOutput | Out-String
    Write-Host $viewCheckResult # Explicitly write to console
}
catch {
    Write-Log -Message "Erro ao verificar views: $($_.Exception.Message)" -Level Error -Console
    $viewCheckResult = "Erro: $($_.Exception.Message)"
}

# 8. Salvar informações do projeto
Save-ProjectInfo -title $title -owner $owner -projectId $projectId -projectNumber $projectNumber -projectUrl $projectUrl -fieldConfigOutput $fieldConfigOutput -statusConfigResult $statusConfigResult -viewCheckResult $viewCheckResult

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