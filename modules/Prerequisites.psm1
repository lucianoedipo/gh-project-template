function Test-GitHubCLI {
    Write-Host "`n📋 Verificando pré-requisitos..." -ForegroundColor Yellow

    # Verificar se o GitHub CLI está instalado
    $ghInstalled = $null -ne (Get-Command gh -ErrorAction SilentlyContinue)
    if (-not $ghInstalled) {
        Write-Error "❌ GitHub CLI (gh) não está instalado. Por favor, instale-o: https://cli.github.com/"
        return $false
    }
    Write-Host "✅ GitHub CLI está instalado."

    # Sincronizar e verificar autenticação
    $authInfo = Sync-GitHubAuth
    
    if (-not $authInfo.IsAuthenticated) {
        Write-Host "🔑 Você não está autenticado no GitHub." -ForegroundColor Yellow
        Write-Host "`n⚠️ ATENÇÃO: Esta ferramenta requer um token de acesso com permissões específicas!" -ForegroundColor Red
        Write-Host "   As seguintes permissões são necessárias:" -ForegroundColor Yellow
        Write-Host "   - repo (acesso completo)"
        Write-Host "   - admin:org (para gerenciar projetos)"
        Write-Host "   - project (acesso aos projetos)"
        Write-Host "`n📚 Para criar um token com as permissões corretas, siga as instruções em:"
        Write-Host "   https://docs.github.com/pt/authentication/keeping-your-account-and-data-secure/creating-a-personal-access-token"
        Write-Host "`n🔄 Após criar o token, você pode fazer login com:"
        Write-Host "   gh auth login --web" -ForegroundColor Cyan
        Write-Host "   ou"
        Write-Host "   gh auth login --with-token < seu_arquivo_token.txt" -ForegroundColor Cyan
        
        # Perguntar se deseja iniciar o processo de login agora
        $response = Read-Host "`nDeseja iniciar o processo de login agora? (S/N)"
        if ($response -eq "S" -or $response -eq "s") {
            gh auth login
            
            # Verificar novamente após tentativa de login
            $authInfo = Get-GitHubAuthType
            if (-not $authInfo.IsAuthenticated) {
                Write-Error "❌ Falha ao autenticar. Por favor, tente novamente manualmente com 'gh auth login'."
                return $false
            }
        } else {
            Write-Host "`n⚠️ Autenticação requerida. Execute o script novamente após efetuar login com 'gh auth login'." -ForegroundColor Yellow
            return $false
        }
    } else {
        Write-Host "✅ Autenticado no GitHub como $($authInfo.User) (Método: $($authInfo.AuthType))."
        
        # Verificar permissões
        $permissionCheck = Test-RequiredPermissions
        
        if (-not $permissionCheck.HasAllPermissions) {
            Write-Host "`n⚠️ AVISO: Seu token não tem todas as permissões necessárias!" -ForegroundColor Red
            Write-Host "   Seu token atual está faltando os seguintes escopos:" -ForegroundColor Yellow
            foreach ($scope in $permissionCheck.MissingScopes) {
                Write-Host "   - $scope" -ForegroundColor Yellow
            }
            
            $updateToken = Read-Host "`nDeseja tentar atualizar o token com esses escopos agora? (S/N)"
            if ($updateToken -eq "S" -or $updateToken -eq "s") {
                $updated = Update-TokenScopes -MissingScopes $permissionCheck.MissingScopes
                
                if ($updated) {
                    # Re-verificar permissões após atualização
                    $permissionCheck = Test-RequiredPermissions
                    if ($permissionCheck.HasAllPermissions) {
                        Write-Host "✅ Token agora possui todas as permissões necessárias." -ForegroundColor Green
                        return $true
                    }
                }
            }
            
            Write-Host "`n   Para criar um novo token com todas as permissões necessárias, acesse:"
            Write-Host "   https://github.com/settings/tokens"
            Write-Host "`n   Escopos de permissão atuais: $($authInfo.TokenScope -join ', ')"
            
            $continue = Read-Host "`nDeseja continuar mesmo assim? (S/N)"
            if ($continue -ne "S" -and $continue -ne "s") {
                return $false
            }
        } else {
            Write-Host "✅ Token possui todas as permissões necessárias."
        }
    }
    
    return $true
}

function Get-GitHubAuthType {
    # Verificar se está autenticado primeiro
    $authStatus = gh auth status -h github.com 2>&1
    
    if ($authStatus -like "*not logged*") {
        return @{
            IsAuthenticated = $false
            AuthType = "None"
            TokenScope = @()
            User = ""
        }
    }

    # Inicializar valores padrão
    $authType = "Unknown"
    $tokenScopes = @()
    $username = ""
    
    # Extrair informações da saída do comando linha por linha para maior precisão
    $authStatusLines = $authStatus -split "`n"
    
    # Mostrar resultado completo para debug
    Write-Verbose "Auth Status Output: $authStatus"
    
    foreach ($line in $authStatusLines) {
        # Extrair nome de usuário
        if ($line -match "Logged in to github\.com account (\S+)") {
            $username = $Matches[1]
        }
        
        # Extrair escopos do token - padrão mais abrangente para capturar diferentes formatos
        if ($line -match "Token scopes: (.+)") {
            $scopesText = $Matches[1]
            Write-Verbose "Scopes Text: $scopesText"
            
            # Verificar se os escopos estão delimitados por aspas simples
            if ($scopesText -match "'([^']+)'") {
                $tokenScopes = $scopesText -split "',\s*'" | ForEach-Object { 
                    $_.Trim().Trim("'", "'", '"') 
                }
            }
            # Verificar se são múltiplos escopos separados por vírgula
            elseif ($scopesText -match ",") {
                $tokenScopes = $scopesText -split ",\s*" | ForEach-Object { 
                    $_.Trim().Trim("'", "'", '"') 
                }
            }
            # Caso seja um único escopo ou outro formato
            else {
                $tokenScopes = @($scopesText.Trim().Trim("'", "'", '"'))
            }
            
            # Verificar se temos escopos com apóstrofos adicionais
            $tokenScopes = $tokenScopes | ForEach-Object {
                $_.Trim("'", "'", '"')
            } | Where-Object { $_ -ne "" }
        }
        
        # Determinar tipo de autenticação
        if ($line -match "Token: \S+") {
            $authType = "Token"
        }
        elseif ($line -match "OAuth") {
            $authType = "OAuth/Web"
        }
        elseif ($line -match "SSH") {
            $authType = "SSH"
        }
    }
    
    # Se ainda não detectou escopos, tente uma abordagem diferente
    if ($tokenScopes.Count -eq 0) {
        $scopesLine = $authStatusLines | Where-Object { $_ -match "Token scopes:" }
        if ($scopesLine) {
            $scopesText = $scopesLine -replace "Token scopes:", ""
            $tokenScopes = $scopesText -split "[\s,']+" | Where-Object { 
                $_ -ne "" -and $_ -ne "''" -and $_ -ne "," 
            }
        }
    }
    
    # Limpar quaisquer escopos vazios
    $tokenScopes = $tokenScopes | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
    
    # Adicionar informações sobre o token para facilitar depuração
    Write-Verbose "Token type: $authType"
    Write-Verbose "Username: $username"
    Write-Verbose "Detected scopes: $($tokenScopes -join ', ')"
    
    return @{
        IsAuthenticated = $true
        AuthType = $authType
        TokenScope = $tokenScopes
        User = $username
    }
}

function Sync-GitHubAuth {
    Write-Host "🔄 Sincronizando informações de autenticação do GitHub..." -ForegroundColor Yellow
    
    # Executar o comando de status para atualizar a sessão
    $null = gh auth status -h github.com 2>&1
    
    # Retornar as informações atualizadas
    return Get-GitHubAuthType
}

function Test-RequiredPermissions {
    param (
        [string[]]$RequiredScopes = @("repo", "admin:org", "project")
    )

    $authInfo = Get-GitHubAuthType
    
    if (-not $authInfo.IsAuthenticated) {
        return @{
            HasAllPermissions = $false
            MissingScopes = $RequiredScopes
            AuthInfo = $authInfo
        }
    }
    
    # Verificar se todos os escopos necessários estão presentes
    $missingScopes = @()
    
    foreach ($scope in $RequiredScopes) {
        $hasScope = $false
        
        # Verificar correspondência exata ou escopo mais amplo
        foreach ($tokenScope in $authInfo.TokenScope) {
            if (($scope -eq "repo" -and $tokenScope -eq "repo") -or
                ($scope -eq "admin:org" -and ($tokenScope -eq "admin:org" -or $tokenScope -eq "admin" -or $tokenScope -eq "read:org" -or $tokenScope -eq "write:org")) -or
                ($scope -eq "project" -and ($tokenScope -eq "project" -or $tokenScope -eq "repo"))) {
                $hasScope = $true
                break
            }
        }
        
        if (-not $hasScope) {
            $missingScopes += $scope
        }
    }
    
    return @{
        HasAllPermissions = ($missingScopes.Count -eq 0)
        MissingScopes = $missingScopes
        AuthInfo = $authInfo
    }
}

function Start-TokenBrowserFlow {
    param(
        [string[]]$MissingScopes
    )
    
    Write-Host "`n🌐 Iniciando processo de criação de token no navegador..." -ForegroundColor Cyan
    
    # Abrir URL diretamente com os escopos selecionados
    $scopeString = $MissingScopes -join "%20"
    $tokenUrl = "https://github.com/settings/tokens/new?scopes=$scopeString"
    
    Write-Host "`n📋 Siga estes passos:" -ForegroundColor Yellow
    Write-Host "  1. O navegador será aberto na página de criação de token" -ForegroundColor White
    Write-Host "  2. Faça login no GitHub se necessário" -ForegroundColor White
    Write-Host "  3. Confirme os escopos selecionados (ou adicione mais se necessário)" -ForegroundColor White
    Write-Host "  4. Digite uma descrição para o token (ex: 'GitHub Project Setup')" -ForegroundColor White
    Write-Host "  5. Clique em 'Generate token'" -ForegroundColor White
    Write-Host "  6. IMPORTANTE: Copie o token gerado!" -ForegroundColor Red
    
    Write-Host "`n🔄 Após criar o token, você precisará fazer login:" -ForegroundColor Yellow
    Write-Host "  1. Execute em um terminal: gh auth logout" -ForegroundColor Cyan
    Write-Host "  2. Execute: gh auth login" -ForegroundColor Cyan
    Write-Host "  3. Escolha a opção para colar um token e cole seu novo token" -ForegroundColor Cyan
    Write-Host "`n⚠️ NOTA: Evite usar 'gh auth login --with-token' pois pode travar" -ForegroundColor Red
    
    $openBrowser = Read-Host "`nAbrir navegador agora? (S/N)"
    
    if ($openBrowser -eq "S" -or $openBrowser -eq "s") {
        try {
            Start-Process $tokenUrl
            Write-Host "✅ Navegador aberto com a página de criação de token" -ForegroundColor Green
        }
        catch {
            Write-Host "❌ Não foi possível abrir o navegador. Por favor, acesse manualmente:" -ForegroundColor Red
            Write-Host $tokenUrl -ForegroundColor Cyan
        }
        
        $continue = Read-Host "`nPressione Enter após criar o token e fazer login com um novo token"
        
        # Verificar se os escopos foram atualizados
        $authInfo = Get-GitHubAuthType
        $permCheck = Test-RequiredPermissions
        
        if ($permCheck.HasAllPermissions) {
            Write-Host "✅ Token atualizado com sucesso!" -ForegroundColor Green
            return $true
        }
        else {
            Write-Host "❌ O token ainda não tem todos os escopos necessários." -ForegroundColor Red
            Write-Host "   Por favor, verifique se você selecionou todos os escopos necessários:" -ForegroundColor Yellow
            foreach ($scope in $permCheck.MissingScopes) {
                Write-Host "   - $scope" -ForegroundColor Yellow
            }
            
            # Calcular o caminho absoluto do arquivo de documentação e mostrar um caminho mais amigável
            $rootDir = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
            $docsPath = Join-Path $rootDir "docs\autenticacao.md"
            
            if (Test-Path $docsPath) {
                Write-Host "`n📘 Para instruções detalhadas de autenticação, consulte:" -ForegroundColor Cyan
                Write-Host "   .\docs\autenticacao.md" -ForegroundColor White
            }
            
            return $false
        }
    }
    else {
        Write-Host "ℹ️ Para criar o token manualmente mais tarde, acesse:" -ForegroundColor Yellow
        Write-Host $tokenUrl -ForegroundColor Cyan
        
        # Mostrar caminho simplificado
        Write-Host "`n📘 Para instruções detalhadas de autenticação, consulte:" -ForegroundColor Cyan
        Write-Host "   .\docs\autenticacao.md" -ForegroundColor White
        
        return $false
    }
}

function Update-TokenScopes {
    param(
        [string[]]$MissingScopes
    )
    
    Write-Host "`n🔑 Atualizando token com os escopos necessários..." -ForegroundColor Yellow
    
    # Como o método --with-token pode travar, recomendamos diretamente o método manual
    Write-Host "❓ Como você prefere atualizar os escopos do token?" -ForegroundColor Cyan
    Write-Host "  [1] Abrir o navegador para criar um novo token (RECOMENDADO)" -ForegroundColor Green
    Write-Host "  [2] Tentar atualização automática via CLI (NÃO RECOMENDADO - pode travar)" -ForegroundColor Red
    
    $updateChoice = Read-Host "`nEscolha uma opção (1 ou 2)"
    
    if ($updateChoice -eq "2") {
        # Aviso adicional
        Write-Host "`n⚠️ AVISO: Este método pode travar em alguns ambientes." -ForegroundColor Red
        $confirmChoice = Read-Host "Tem certeza que deseja continuar? (S/N)"
        
        if ($confirmChoice -ne "S" -and $confirmChoice -ne "s") {
            return Start-TokenBrowserFlow -MissingScopes $MissingScopes
        }
        
        # Opção original de atualização automática
        try {
            Write-Host "Executando: gh auth refresh $(foreach($scope in $MissingScopes) { "-s $scope " }) --hostname github.com" -ForegroundColor Gray
            Write-Host "⚠️ Este processo pode travar. Se nada acontecer após 15 segundos:" -ForegroundColor Red
            Write-Host "   1. Pressione CTRL+C para cancelar" -ForegroundColor Yellow
            Write-Host "   2. Execute o script novamente e escolha a opção 1" -ForegroundColor Yellow
            
            # Opção mais segura: executar o comando diretamente e não via Invoke-Expression
            $argList = @("auth", "refresh", "--hostname", "github.com")
            foreach ($scope in $MissingScopes) {
                $argList += "-s"
                $argList += $scope
            }

            # Iniciar processo com Start-Process para melhor controle
            $pinfo = New-Object System.Diagnostics.ProcessStartInfo
            $pinfo.FileName = "gh"
            $pinfo.Arguments = $argList -join " "
            $pinfo.RedirectStandardOutput = $true
            $pinfo.RedirectStandardError = $true
            $pinfo.UseShellExecute = $false
            $pinfo.CreateNoWindow = $true
            
            $process = New-Object System.Diagnostics.Process
            $process.StartInfo = $pinfo
            $process.Start() | Out-Null
            
            # Definir um tempo limite de 30 segundos
            $timeoutSeconds = 30
            $hasExited = $process.WaitForExit($timeoutSeconds * 1000)
            
            if (-not $hasExited) {
                Write-Host "⚠️ O processo está demorando mais do que o esperado. Deseja cancelar? (S/N)" -ForegroundColor Red
                $cancel = Read-Host
                if ($cancel -eq "S" -or $cancel -eq "s") {
                    try {
                        $process.Kill()
                    }
                    catch {
                        # Processo pode ter terminado entre a verificação e a tentativa de matá-lo
                    }
                    Write-Host "❌ Processo cancelado pelo usuário." -ForegroundColor Red
                    # Pular para o método alternativo
                    $useAlternative = $true
                }
                else {
                    # Continuar esperando
                    $process.WaitForExit()
                }
            }
            
            $stdout = $process.StandardOutput.ReadToEnd()
            $stderr = $process.StandardError.ReadToEnd()
            $exitCode = $process.ExitCode
            
            if ($exitCode -eq 0 -and ($stdout -match "Expanded" -or $stdout -match "success")) {
                Write-Host "✅ Escopos de token atualizados com sucesso!" -ForegroundColor Green
                return $true
            }
            else {
                Write-Host "⚠️ Não foi possível atualizar automaticamente os escopos do token." -ForegroundColor Red
                if ($stderr) {
                    Write-Host "Erro: $stderr" -ForegroundColor Yellow
                }
                if ($stdout) {
                    Write-Host "Saída: $stdout" -ForegroundColor Gray
                }
                
                $useAlternative = $true
            }
        }
        catch {
            Write-Host "❌ Erro ao atualizar token: $($_.Exception.Message)" -ForegroundColor Red
            Write-Host "Tentando método alternativo..." -ForegroundColor Yellow
            return Start-TokenBrowserFlow -MissingScopes $MissingScopes
        }
    }
    else {
        # Método recomendado - fluxo do navegador
        return Start-TokenBrowserFlow -MissingScopes $MissingScopes
    }
}

# Exportar as funções
Export-ModuleMember -Function Test-GitHubCLI, Get-GitHubAuthType, Test-RequiredPermissions, Sync-GitHubAuth
