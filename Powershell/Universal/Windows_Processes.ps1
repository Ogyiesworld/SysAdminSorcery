<#
****************************************************************************************************
# SUMMARY:      Generates an HTML Report of Running Processes Sorted by CPU Usage
# AUTHOR:       Joshua Ogden
# DESCRIPTION:  Captures current running processes, sorts them by CPU usage, and generates an HTML report.
#               Intended for system monitoring, performance analysis, or initial threat hunting.
# COMPATIBILITY: Windows PowerShell 5.1 and later.
# NOTES:        Version 1.3. Last Updated: [04/03/2024]. Checks for C:\Temp directory existence or 
#               creates it if missing. The report includes process name, ID, CPU time, and memory usage.
****************************************************************************************************
#>

# Prepare environment
$CurrentTime = Get-Date -Format "MM-dd-yyyy_HH-mm-ss"
$OutputDirectory = "C:\Temp"
$OutputFile = Join-Path -Path $OutputDirectory -ChildPath ("RunningProcesses_" + $CurrentTime + ".html")

# Ensure output directory exists
if (-not (Test-Path -Path $OutputDirectory)) {
    New-Item -Path $OutputDirectory -ItemType Directory | Out-Null
}

# Get total physical memory for memory usage percentage calculation
$totalMemory = Get-CimInstance Win32_ComputerSystem | Select-Object -ExpandProperty TotalPhysicalMemory

# Initialize HTML content
$HtmlContent = @"
<!DOCTYPE html>AA
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Running Processes Report - $CurrentTime</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        table { border-collapse: collapse; width: 100%; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background-color: #4CAF50; color: white; }
        tr:nth-child(even) { background-color: #f2f2f2; }
    </style>
</head>
<body>
    <h1>Running Processes Report - $CurrentTime</h1>
    <table>
        <thead>
            <tr>
                <th>Process Name</th>
                <th>Process ID</th>
                <th>CPU Time (HH:MM:SS)</th>
                <th>Memory Usage (MB) / % of Total</th>
            </tr>
        </thead>
        <tbody>
"@

Try {
    $Processes = Get-Process | Sort-Object -Property CPU -Descending
    foreach ($Process in $Processes) {
        if ($Process.CPU -gt 0) {
            $cpuTime = [timespan]::FromSeconds($Process.CPU).ToString("hh\:mm\:ss")
            $memoryUsageMB = $Process.WorkingSet / 1MB
            $memoryUsagePercent = ($memoryUsageMB * 1MB) / $totalMemory * 100
            $HtmlContent += @"
                <tr>
                    <td>$($Process.ProcessName)</td>
                    <td>$($Process.Id)</td>
                    <td>$cpuTime</td>
                    <td>$("{0:N2}" -f $memoryUsageMB) MB / $("{0:N2}" -f $memoryUsagePercent)%</td>
                </tr>
"@
        }
    }
} Catch {
    Write-Error "Failed to retrieve or sort processes. Error: $_"
    Exit
}

$HtmlContent += @"
        </tbody>
    </table>
</body>
</html>
"@

# Save the report
Try {
    $HtmlContent | Out-File -FilePath $OutputFile -Encoding UTF8
} Catch {
    Write-Error "Failed to save the HTML report. Error: $_"
}
# Prompt the user for their choice
$userChoice = Read-Host "Do you want to open the file? (Y/N)"

# Check if the user's choice was "Y" (case-insensitive)
if ($userChoice -ieq "Y") {
    # Attempt to open the file
    try {
        Invoke-Item $OutputFile
        Write-Host "File opened successfully." -ForegroundColor Green
    } catch {
        Write-Host "Failed to open the file: $_" -ForegroundColor Red
    }
} elseif ($userChoice -ieq "N") {
    Write-Host "The file will not be opened." -ForegroundColor Yellow
} else {
    Write-Host "Invalid input. Please enter 'Y' for Yes or 'N' for No." -ForegroundColor Red
}