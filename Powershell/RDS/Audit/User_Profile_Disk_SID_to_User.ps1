<#
********************************************************************************
# SUMMARY:      Extract User Profile Details from UPD Share
# AUTHOR:       Joshua Ogden
# DESCRIPTION:  This script scans a User Profile Disk (UPD) share to extract usernames and SIDs,
#               and then exports the details to a CSV file.
# COMPATIBILITY: Windows PowerShell 5.1 or later
# NOTES:        Ensure the FileSystemObject COM class is available and necessary permissions 
#               for accessing the network UPD share are in place.
********************************************************************************
#>

# Variable Declarations
$UPDShare = "\\YourServer\YourUPDShare" # Update with the actual UPD share path
$ExportFile = "C:\temp\adusersinfo_$(Get-Date -UFormat "%B-%d-%Y").csv" # Export file name with current date
$UserProfiles = @() # Array to store user profile details
$FileSystemObject = New-Object -ComObject Scripting.FileSystemObject # Creates FileSystemObject

# Exception Handling
try {
    $Folder = $FileSystemObject.GetFolder($UPDShare)
} catch {
    Write-Error "Failed to access the folder: $UPDShare. Error: $_"
    exit 1
}

# Output CSV Headers
try {
    "Username,SiD" > $ExportFile
} catch {
    Write-Error "Failed to write to the export file: $ExportFile. Error: $_"
    exit 1
}

# Process Each File
foreach ($File in $Folder.Files) {
    # Ignore .old files
    if ($File.Name -like "*.old") {
        Write-Output "Ignoring .old file: $File.Name"
        continue
    }

    try {
        $Sid = $File.Name
        $Sid = $Sid.Substring(5, $Sid.Length - 10)

        if ($Sid -ne "template") {
            try {
                $SecurityIdentifier = New-Object Security.Principal.SecurityIdentifier $Sid
                $User = $SecurityIdentifier.Translate([Security.Principal.NTAccount])
                $UserProfile = New-Object PSObject -Property @{
                    UserName  = $User.Value
                    UPDFile   = $File.Name
                }
                $UserProfiles += $UserProfile
            } catch {
                Write-Output "Failed to translate SID $Sid. This SID could not be translated and will be skipped. Error: $_"
                continue
            }
        }
    } catch {
        Write-Error "Failed to process file $File. Error: $_"
        continue
    }
}   

# Export to CSV
try {
    $UserProfiles | Select-Object UserName, UPDFile | Export-Csv -Path $ExportFile -NoTypeInformation
    Write-Output "User profile details successfully exported to $ExportFile."
} catch {
    Write-Error "Failed to export user profiles to CSV. Error: $_"
}