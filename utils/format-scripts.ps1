#Requires -Modules PSScriptAnalyzer

param(
    [string]$Path = "*.ps1",
    [switch]$Recursive = $true
)

# Verificar se o PSScriptAnalyzer está instalado
if (-not (Get-Module -ListAvailable -Name PSScriptAnalyzer)) {
    Write-Host "📦 PSScriptAnalyzer não encontrado. Instalando..." -ForegroundColor Yellow
    Install-Module -Name PSScriptAnalyzer -Scope CurrentUser -Force
    Write-Host "✅ PSScriptAnalyzer instalado com sucesso" -ForegroundColor Green
}

Write-Host "🔍 Buscando scripts PowerShell para formatar..." -ForegroundColor Cyan

# Encontrar todos os arquivos PS1
if ($Recursive) {
    $scripts = Get-ChildItem -Path $Path -Recurse
}
else {
    $scripts = Get-ChildItem -Path $Path
}

$count = 0
foreach ($script in $scripts) {
    Write-Host "🔄 Formatando: $($script.FullName)" -ForegroundColor Yellow
    
    # Ler o conteúdo original
    $originalContent = Get-Content -Path $script.FullName -Raw
    
    # Formatar o script
    $formattedContent = Invoke-Formatter -ScriptDefinition $originalContent
    
    # Salvar o conteúdo formatado
    if ($formattedContent -ne $originalContent) {
        $formattedContent | Set-Content -Path $script.FullName -Encoding UTF8
        $count++
        Write-Host "  ✅ Formatado com sucesso" -ForegroundColor Green
    }
    else {
        Write-Host "  ℹ️ Nenhuma alteração necessária" -ForegroundColor Blue
    }
}

Write-Host "`n🎉 Processo concluído! $count scripts foram formatados." -ForegroundColor Cyan

