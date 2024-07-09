<#
********************************************************************************
# SUMMARY:      Retrieve and Export Service Details
# AUTHOR:       Joshua Ogden
# DESCRIPTION:  This script retrieves details of all services on a Windows machine,
#               including their status, start type, and the account they run under.
#               It also performs basic checks for potential configuration issues and
#               exports the details to a CSV file with the current date in the filepath$csvFilePath.
# COMPATIBILITY: Windows PowerShell 5.1 or later
# NOTES:        Ensure you have the necessary permissions to access WMI and
#               service details on the machine where this script is executed.
********************************************************************************
#>

# Create an empty array to hold service details
$serviceDetailsList = @()

# Retrieve all services
$services = Get-Service

# Retrieve all service accounts in one WMI query for efficiency
try {
    $serviceAccounts = Get-WmiObject -Query "SELECT Name, StartName FROM Win32_Service"
} catch {
    Write-Error "Failed to retrieve service account details: $_"
    exit 1
}

# Create a hashtable to map service names to their start names
$serviceAccountMap = @{}
foreach ($serviceAccount in $serviceAccounts) {
    $serviceAccountMap[$serviceAccount.Name] = $serviceAccount.StartName
}

# Iterate through each service and gather details
foreach ($service in $services) {
    # Determine the account name under which the service runs
    $runningAs = if ($serviceAccountMap.ContainsKey($service.Name)) {
        $serviceAccountMap[$service.Name]
    } else {
        "Unknown"
    }

    # Example check for potential configuration issues
    $configStatus = "OK"
    if ($service.StartType -eq "Disabled") {
        $configStatus = "Warning: Review required"
    }
    if ($service.Status -ne "Running") {
        $configStatus = "Not Running: Review required"
    }

    # Add service details to the list
    $serviceDetailsList += [PSCustomObject]@{
        ServiceName  = $service.Name
        DisplayName  = $service.DisplayName
        Status       = $service.Status
        StartType    = $service.StartType
        Description  = $service.Description
        RunningAs    = $runningAs
        ConfigStatus = $configStatus
    }
}

# Generate filepath$csvFilePath with current date
$date = Get-Date -Format "yyyyMMdd"
$csvFilePath = "C:\Temp\ServiceDetails_$date.csv"

# Export to CSV
try {
    $serviceDetailsList | Export-Csv -Path $csvFilePath -NoTypeInformation
    Write-Output "Service details successfully exported to $csvFilePath"
} catch {
    Write-Error "Failed to export service details to CSV: $_"
}
