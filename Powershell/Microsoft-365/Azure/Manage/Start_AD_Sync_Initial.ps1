# Prompt the user for the server to invoke the command on
$server = Read-Host "Enter the server name"

# Start Initial ADsync
Invoke-Command -ComputerName $server -ScriptBlock {
    Import-Module ADSync
    Start-ADSyncSyncCycle -PolicyType Initial
}