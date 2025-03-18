# Requires -Modules ActiveDirectory
<#
.SYNOPSIS
    Audits Active Directory replication status across all domain controllers.

.DESCRIPTION
    This script performs a comprehensive audit of Active Directory replication status
    across all domain controllers in the environment. It checks replication health,
    last replication times, potential replication errors, and relevant event logs.

.PARAMETER OutputPath
    The path where the CSV report will be saved. If not specified, defaults to C:\Temp.

.PARAMETER EventLogDays
    Number of days of event logs to collect. Default is 1 day.

.EXAMPLE
    .\Audit_DC_Replication.ps1
    Runs the audit with default settings

.EXAMPLE
    .\Audit_DC_Replication.ps1 -OutputPath "D:\Reports" -EventLogDays 7
    Runs the audit and collects 7 days of event logs

.NOTES
    Version:        2.1
    Author:         Updated by Joshua Ogden
    Last Modified:  2025-01-06
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory=$false)]
    [string]$OutputPath = "C:\Temp",

    [Parameter(Mandatory=$false)]
    [int]$EventLogDays = 1
)

# Function to write log messages
function Write-Log {
    param($Message)
    $logMessage = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss'): $Message"
    Write-Host $logMessage
    $script:logMessages += $logMessage
}

# Function to get relevant event logs
function Get-ReplicationEvents {
    param (
        [string]$ServerName,
        [int]$Days
    )
    
    $startTime = (Get-Date).AddDays(-$Days)
    $events = @()
    
    try {
        # Directory Service events
        $dsEvents = Get-WinEvent -ComputerName $ServerName -FilterHashtable @{
            LogName = 'Directory Service'
            Level = 1,2,3 # Error, Warning, Information
            StartTime = $startTime
        } -ErrorAction Stop | Where-Object {
            $_.Id -in @(1311,1645,1644,1388,1988,2042) # Common replication-related event IDs
        }
        $events += $dsEvents
        
        # DFS Replication events
        $dfsrEvents = Get-WinEvent -ComputerName $ServerName -FilterHashtable @{
            LogName = 'DFS Replication'
            Level = 1,2,3
            StartTime = $startTime
        } -ErrorAction Stop
        $events += $dfsrEvents
    }
    catch {
        Write-Log "Warning: Could not retrieve all events from $ServerName : $_"
    }
    
    return $events
}

# Function to get NTDS settings
function Get-NTDSSettings {
    param([string]$ServerName)
    
    try {
        $ntdsSettings = Get-ADObject -Filter {objectClass -eq "nTDSDSA"} `
            -SearchBase "CN=Sites,CN=Configuration,$((Get-ADDomain).DistinguishedName)" `
            -Properties * `
            -Server $ServerName -ErrorAction Stop |
            Where-Object { $_.DistinguishedName -like "*$ServerName*" }
        return $ntdsSettings
    }
    catch {
        Write-Log "Warning: Could not retrieve NTDS settings from $ServerName : $_"
        return $null
    }
}

# Initialize variables
$script:logMessages = @()
$currentTime = Get-Date -Format "yyyyMMdd_HHmmss"
$csvFilePath = Join-Path $OutputPath "DC_Replication_Audit_$currentTime.csv"
$eventsCsvPath = Join-Path $OutputPath "DC_Replication_Events_$currentTime.csv"
$logFilePath = Join-Path $OutputPath "DC_Replication_Audit_$currentTime.log"

# Ensure output directory exists
try {
    if (-not (Test-Path $OutputPath)) {
        New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
        Write-Log "Created output directory: $OutputPath"
    }
}
catch {
    Write-Error "Failed to create output directory: $_"
    exit 1
}

# Initialize arrays to store results
$auditResults = @()
$eventResults = @()

Write-Log "Starting DC replication audit..."

try {
    # Get all domain controllers
    $domainControllers = Get-ADDomainController -Filter * | Select-Object -ExpandProperty Name
    Write-Log "Found $($domainControllers.Count) domain controllers"

    # Progress counter
    $counter = 0

    foreach ($dc in $domainControllers) {
        $counter++
        $percentComplete = ($counter / $domainControllers.Count) * 100
        Write-Progress -Activity "Auditing Domain Controllers" -Status "Processing $dc" -PercentComplete $percentComplete

        try {
            Write-Log "Checking replication status for $dc"
            
            # Get detailed replication information
            $replicationPartners = Get-ADReplicationPartnerMetadata -Target $dc -ErrorAction Stop
            $replicationFailures = Get-ADReplicationFailure -Target $dc -ErrorAction Stop
            $replicationQueue = Get-ADReplicationQueueOperation -Server $dc -ErrorAction Stop
            $ntdsSettings = Get-NTDSSettings -ServerName $dc
            
            # Get event logs
            Write-Log "Collecting event logs from $dc"
            $events = Get-ReplicationEvents -ServerName $dc -Days $EventLogDays
            
            # Add events to results
            foreach ($event in $events) {
                $eventResults += [PSCustomObject]@{
                    "Timestamp" = $event.TimeCreated
                    "DC" = $dc
                    "EventID" = $event.Id
                    "Level" = $event.LevelDisplayName
                    "Log" = $event.LogName
                    "Message" = $event.Message
                }
            }
            
            foreach ($partner in $replicationPartners) {
                $auditResults += [PSCustomObject]@{
                    "Timestamp" = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                    "Source DC" = $dc
                    "Partner DC" = $partner.Partner
                    "Last Replication Success" = $partner.LastReplicationSuccess
                    "Last Replication Result" = $partner.LastReplicationResult
                    "Consecutive Failures" = $partner.ConsecutiveReplicationFailures
                    "Last Replication Attempt" = $partner.LastReplicationAttempt
                    "Pending Replication Operations" = ($replicationQueue | Where-Object {$_.ServerName -eq $partner.Partner}).Count
                    "Failure Count" = ($replicationFailures | Where-Object {$_.ServerName -eq $partner.Partner}).FailureCount
                    "First Failure Time" = ($replicationFailures | Where-Object {$_.ServerName -eq $partner.Partner}).FirstFailureTime
                    "NTDS Port" = $ntdsSettings."msDS-PortLDAP"
                    "Options" = $partner.Options -join '; '
                    "Transport Type" = $partner.TransportType
                    "Schedule" = $partner.Schedule
                    "Status" = if ($partner.LastReplicationResult -eq 0) {"Healthy"} else {"Error"}
                }
            }
        }
        catch {
            Write-Log "Error processing $dc : $_"
            $auditResults += [PSCustomObject]@{
                "Timestamp" = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                "Source DC" = $dc
                "Partner DC" = "N/A"
                "Last Replication Success" = "N/A"
                "Last Replication Result" = "Error"
                "Consecutive Failures" = "N/A"
                "Last Replication Attempt" = "N/A"
                "Pending Replication Operations" = "N/A"
                "Failure Count" = "N/A"
                "First Failure Time" = "N/A"
                "NTDS Port" = "N/A"
                "Options" = "N/A"
                "Transport Type" = "N/A"
                "Schedule" = "N/A"
                "Status" = "Error - $_"
            }
        }
    }

    Write-Progress -Activity "Auditing Domain Controllers" -Completed

    # Export results
    $auditResults | Export-Csv -Path $csvFilePath -NoTypeInformation
    $eventResults | Export-Csv -Path $eventsCsvPath -NoTypeInformation
    $logMessages | Out-File -FilePath $logFilePath

    Write-Log "Audit completed successfully"
    Write-Log "Results exported to: $csvFilePath"
    Write-Log "Event logs exported to: $eventsCsvPath"
    Write-Log "Log file saved to: $logFilePath"

    # Display summary
    $healthyDCs = ($auditResults | Where-Object {$_.Status -eq "Healthy"}).Count
    $unhealthyDCs = ($auditResults | Where-Object {$_.Status -ne "Healthy"}).Count
    $totalEvents = $eventResults.Count
    
    Write-Host "`nSummary:" -ForegroundColor Cyan
    Write-Host "Total Connections: $($auditResults.Count)" -ForegroundColor White
    Write-Host "Healthy Connections: $healthyDCs" -ForegroundColor Green
    Write-Host "Unhealthy Connections: $unhealthyDCs" -ForegroundColor $(if ($unhealthyDCs -gt 0) {"Red"} else {"Green"})
    Write-Host "Total Related Events: $totalEvents" -ForegroundColor White
}
catch {
    Write-Error "Critical error in script execution: $_"
    Write-Log "Critical error in script execution: $_"
    exit 1
}