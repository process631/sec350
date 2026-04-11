#Requires -RunAsAdministrator
<#
.SYNOPSIS
  Download and install the Wazuh Windows agent (Lab 10 / mgmt).

.DESCRIPTION
  Pull this repo on the mgmt VM, then run:
    powershell -ExecutionPolicy Bypass -File .\install-wazuh-agent.ps1

  Or override manager IP / group:
    .\install-wazuh-agent.ps1 -WazuhManager 172.16.200.10 -AgentGroup default
#>
param(
    [string]$WazuhManager = '172.16.200.10',
    [string]$RegistrationServer = '172.16.200.10',
    [string]$AgentGroup = 'default',
    [string]$MsiUrl = 'https://packages.wazuh.com/4.x/windows/wazuh-agent-4.3.11-1.msi',
    [string]$OutPath = 'C:\wazuh-agent.msi'
)

$ErrorActionPreference = 'Stop'

Write-Host "Downloading Wazuh agent MSI..."
Invoke-WebRequest -Uri $MsiUrl -OutFile $OutPath -UseBasicParsing

$args = @(
    '/i', $OutPath,
    '/qn',
    "WAZUH_MANAGER=$WazuhManager",
    "WAZUH_REGISTRATION_SERVER=$RegistrationServer",
    "WAZUH_AGENT_GROUP=$AgentGroup"
)

Write-Host "Installing (quiet)..."
$p = Start-Process -FilePath 'msiexec.exe' -ArgumentList $args -Wait -PassThru
if ($p.ExitCode -notin 0, 3010) {
    throw "msiexec failed with exit code $($p.ExitCode). 3010 = success, reboot may be required."
}

Write-Host "Starting Wazuh service..."
net start wazuh
if ($LASTEXITCODE -ne 0) {
    throw "net start wazuh failed (exit $LASTEXITCODE). If the service name differs, check services.msc for Wazuh."
}

Write-Host "Done."
