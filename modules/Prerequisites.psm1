function Test-GitHubCLI {
    Write-Host "`n📋 Verificando pré-requisitos..." -ForegroundColor Yellow

    # Verificar se o GitHub CLI está instalado
    $ghInstalled = $null -ne (Get-Command gh -ErrorAction SilentlyContinue)
    if (-not $ghInstalled) {
        Write-Error "❌ GitHub CLI (gh) não está instalado. Por favor, instale-o: https://cli.github.com/"
        return $false
    }
    Write-Host "✅ GitHub CLI está instalado."

    # Verificar autenticação
    $authStatus = gh auth status -h github.com 2>&1
    if ($authStatus -like "*not logged*") {
        Write-Host "🔑 Você não está autenticado no GitHub. Iniciando processo de login..."
        gh auth login
        
        # Verificar novamente após tentativa de login
        $authStatus = gh auth status -h github.com 2>&1
        if ($authStatus -like "*not logged*") {
            Write-Error "❌ Falha ao autenticar. Por favor, execute 'gh auth login' manualmente."
            return $false
        }
    }
    Write-Host "✅ Autenticado no GitHub."
    
    return $true
}

Export-ModuleMember -Function Test-GitHubCLI
