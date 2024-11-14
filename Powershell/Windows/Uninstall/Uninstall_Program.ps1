

#read the program name
$partofprogramname = Read-Host "Enter the name of the program to uninstall"

#get the wmi object
$uninstallprogram = Get-WmiObject -Class Win32_Product | Where-Object { $_.Name -like "*$partofprogramname*" } | Select-Object Name, IdentifyingNumber

#uninstall the program
foreach ($program in $uninstallprogram) {
    Write-Output "Uninstalling $($program.Name)..."
    $uninstall = (New-Object -ComObject Shell.Application).ShellExecute("msiexec.exe", "/x $($program.IdentifyingNumber) /qn", "", "runas", 0)
    if ($uninstall -eq 0) {
        Write-Output "Uninstall successful."
    }
    else {
        Write-Error "Failed to uninstall $($program.Name). Error code: $uninstall"
    }
}

#if no program found to uninstall then check using registry to see if the program is installed (only for listing)
if (-not $uninstallprogram) {
    Write-Output "No program found with the name '$partofprogramname'. Checking registry..."
    $uninstallprogram = Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* | Where-Object { $_.DisplayName -like "*$partofprogramname*" } | Select-Object DisplayName, UninstallString
    if ($uninstallprogram) {
        Write-Output "Program found in registry:"
        $uninstallprogram
    }
    else {
        Write-Output "No program found in registry with the name '$partofprogramname'."
    }
}


