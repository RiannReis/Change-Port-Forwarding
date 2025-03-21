param(
    [Parameter(Mandatory=$false)]
    [int]$OldPort,
    
    [Parameter(Mandatory=$true)]
    [int]$NewPort,
    
    [Parameter(Mandatory=$true)]
    [string]$WSLAddress
)

function Test-AdminRights {
    $currentUser = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    return $currentUser.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Test-PortInUse {
    param([int]$Port)
    $inUse = Get-NetTCPConnection -ErrorAction SilentlyContinue | Where-Object LocalPort -eq $Port
    return ($null -ne $inUse)
}

function Test-WSLAddress {
    param([string]$Address)
    try {
        $valid = [System.Net.IPAddress]::Parse($Address)
        return $true
    }
    catch {
        return $false
    }
}

try {
    # Verificar privilégios de administrador
    if (-not (Test-AdminRights)) {
        throw "Este script precisa ser executado como administrador!"
    }

    # Validar parâmetros de entrada
    if ($NewPort -lt 1024 -or $NewPort -gt 65535) {
        throw "Porta inválida! Use um valor entre 1024 e 65535."
    }

    if (-not (Test-WSLAddress -Address $WSLAddress)) {
        throw "Endereço IP do WSL inválido!"
    }

    # Verificar se a nova porta já está em uso
    if (Test-PortInUse -Port $NewPort) {
        throw "A porta $NewPort já está em uso por outro processo!"
    }

    Write-Host "Iniciando o processo de mudança de port forwarding..." -ForegroundColor Cyan

    # Remover configuração antiga se OldPort foi especificado
    if ($OldPort) {
        Write-Host "Removendo configurações antigas de port proxy na porta $OldPort..." -ForegroundColor Yellow
        netsh interface portproxy delete v4tov4 listenport=$OldPort listenaddress=0.0.0.0
        if ($LASTEXITCODE -ne 0) {
            Write-Warning "Aviso: Não foi possível remover a configuração antiga. Continuando..."
        }
        
        # Remover regra antiga do firewall
        Remove-NetFirewallRule -DisplayName "Allow Port $OldPort" -ErrorAction SilentlyContinue
    }

    # Adicionar nova configuração
    Write-Host "Adicionando nova configuração de port forwarding para porta $NewPort..." -ForegroundColor Green
    $result = netsh interface portproxy add v4tov4 listenport=$NewPort connectaddress=$WSLAddress connectport=$NewPort listenaddress=0.0.0.0 protocol=tcp
    if ($LASTEXITCODE -ne 0) {
        throw "Falha ao adicionar nova configuração de port forwarding: $result"
    }

    # Atualizar regras do firewall
    Write-Host "Atualizando regras do firewall..." -ForegroundColor Green
    $firewallRule = New-NetFirewallRule -DisplayName "Allow Port $NewPort" -Direction Inbound -LocalPort $NewPort -Protocol TCP -Action Allow -ErrorAction Stop

    # Exibir configuração atual
    Write-Host "`nConfiguração atual do port proxy:" -ForegroundColor Cyan
    netsh interface portproxy show all

    Write-Host "`nConfiguração concluída com sucesso!" -ForegroundColor Green
}
catch {
    Write-Host "Erro: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}