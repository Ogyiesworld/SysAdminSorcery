# GPO Connectivity Troubleshooting Script
# Author: James Ogden
# Date: 2024-12-28
# Purpose: Troubleshoot GPO connectivity and processing issues

# Ensure we're running with administrative privileges
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Error "This script requires administrative privileges. Please run as administrator."
    exit 1
}

# Function to test network connectivity to domain controllers
function Test-DomainControllerConnectivity {
    Write-Host "`n[*] Testing Domain Controller Connectivity..." -ForegroundColor Cyan
    
    try {
        $dcs = Get-ADDomainController -Filter * | Select-Object -ExpandProperty HostName
        foreach ($dc in $dcs) {
            $result = Test-Connection -ComputerName $dc -Count 1 -ErrorAction SilentlyContinue
            if ($result) {
                Write-Host "  [+] Connection to $dc successful - Response time: $($result.ResponseTime)ms" -ForegroundColor Green
            } else {
                Write-Host "  [-] Connection to $dc failed!" -ForegroundColor Red
            }
        }
    } catch {
        Write-Host "  [-] Error getting domain controllers: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Function to check DNS resolution
function Test-DNSResolution {
    Write-Host "`n[*] Testing DNS Resolution..." -ForegroundColor Cyan
    
    try {
        $domain = $env:USERDNSDOMAIN
        $result = Resolve-DnsName -Name $domain -ErrorAction Stop
        Write-Host "  [+] DNS resolution for $domain successful" -ForegroundColor Green
        Write-Host "  [+] DNS Servers configured:"
        Get-DnsClientServerAddress -AddressFamily IPv4 | 
            Where-Object {$_.InterfaceAlias -notlike "*Loopback*"} |
            Select-Object InterfaceAlias, ServerAddresses
    } catch {
        Write-Host "  [-] DNS resolution failed: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Function to check GPO processing time
function Test-GPOProcessingTime {
    Write-Host "`n[*] Testing GPO Processing Time..." -ForegroundColor Cyan
    
    try {
        $startTime = Get-Date
        gpupdate /force /wait:0
        $endTime = Get-Date
        $duration = $endTime - $startTime
        
        Write-Host "  [+] GPO update completed in $($duration.TotalSeconds) seconds" -ForegroundColor Green
        
        # Get recent GPO processing events
        Write-Host "`n[*] Recent GPO Processing Events:" -ForegroundColor Cyan
        Get-WinEvent -LogName "Microsoft-Windows-GroupPolicy/Operational" -MaxEvents 5 |
            Select-Object TimeCreated, Id, Message |
            Format-Table -AutoSize
    } catch {
        Write-Host "  [-] Error during GPO processing: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Function to check network latency to domain
function Test-NetworkLatency {
    Write-Host "`n[*] Testing Network Latency..." -ForegroundColor Cyan
    
    try {
        $domain = $env:USERDNSDOMAIN
        $results = Test-Connection -ComputerName $domain -Count 4 -ErrorAction Stop
        $avg = ($results | Measure-Object -Property ResponseTime -Average).Average
        
        Write-Host "  [+] Average latency to domain: $($avg)ms" -ForegroundColor $(
            if ($avg -lt 50) { "Green" }
            elseif ($avg -lt 100) { "Yellow" }
            else { "Red" }
        )
    } catch {
        Write-Host "  [-] Network latency test failed: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Function to get applied GPO policies
function Get-AppliedGPOPolicies {
    Write-Host "`n[*] Retrieving Applied GPO Policies..." -ForegroundColor Cyan
    
    try {
        # Try to import the GroupPolicy module
        if (Get-Module -ListAvailable -Name GroupPolicy) {
            Import-Module GroupPolicy -ErrorAction Stop
            
            # Get Computer GPO Report
            Write-Host "`n  [*] Computer GPO Policies:" -ForegroundColor Yellow
            $computerGPOs = Get-GPResultantSetOfPolicy -ReportType Computer -ErrorAction Stop
            $computerGPOs.AppliedGPOs | ForEach-Object {
                Write-Host "  [+] $($_.DisplayName)" -ForegroundColor Green
                Write-Host "      - Link: $($_.Link)"
                Write-Host "      - Status: $($_.GPOStatus)"
            }

            # Get User GPO Report
            Write-Host "`n  [*] User GPO Policies:" -ForegroundColor Yellow
            $userGPOs = Get-GPResultantSetOfPolicy -ReportType User -ErrorAction Stop
            $userGPOs.AppliedGPOs | ForEach-Object {
                Write-Host "  [+] $($_.DisplayName)" -ForegroundColor Green
                Write-Host "      - Link: $($_.Link)"
                Write-Host "      - Status: $($_.GPOStatus)"
            }
        } else {
            Write-Host "  [-] GroupPolicy PowerShell module not available. Using gpresult instead." -ForegroundColor Yellow
        }

        # Get detailed GPO settings using gpresult
        Write-Host "`n  [*] Detailed GPO Settings:" -ForegroundColor Yellow
        Write-Host "  [*] Running gpresult to get applied policies..." -ForegroundColor Cyan
        
        # Get GPO report in HTML format for more detailed information
        $tempFile = [System.IO.Path]::GetTempFileName() + ".html"
        gpresult /H $tempFile /F
        Write-Host "  [+] Full GPO report saved to: $tempFile" -ForegroundColor Green
        
        # Display summary using gpresult /r
        $gpresultOutput = gpresult /r
        $gpresultOutput | ForEach-Object {
            if ($_ -match "Applied Group Policy Objects" -or $_ -match "The following GPOs were not applied") {
                Write-Host "`n  $_" -ForegroundColor Yellow
            } elseif ($_ -match "Group Policy Object") {
                Write-Host "  [+] $_" -ForegroundColor Green
            } elseif ($_ -match "Last time Group Policy was applied") {
                Write-Host "`n  [*] $_" -ForegroundColor Cyan
            } else {
                Write-Host "      $_"
            }
        }
        
        # Additional GPO processing information from event logs
        Write-Host "`n  [*] Recent GPO Processing Events:" -ForegroundColor Yellow
        Get-WinEvent -LogName "Microsoft-Windows-GroupPolicy/Operational" -MaxEvents 3 | 
            Where-Object { $_.Id -in @(4016, 5312, 5313, 7016, 7017) } |
            ForEach-Object {
                Write-Host "  [+] $($_.TimeCreated) - Event ID $($_.Id)" -ForegroundColor Green
                Write-Host "      $($_.Message)"
            }
        
    } catch {
        Write-Host "  [-] Error retrieving GPO policies: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Main execution
Clear-Host
Write-Host "GPO Connectivity Troubleshooting Script" -ForegroundColor Yellow
Write-Host "======================================`n"

Write-Host "Computer Name: $env:COMPUTERNAME"
Write-Host "Domain: $env:USERDNSDOMAIN"
Write-Host "Current Time: $(Get-Date)`n"

# Run all tests
Test-DomainControllerConnectivity
Test-DNSResolution
Test-NetworkLatency
Test-GPOProcessingTime
Get-AppliedGPOPolicies

Write-Host "`nTroubleshooting Complete!" -ForegroundColor Green