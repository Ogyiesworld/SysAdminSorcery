<#
********************************************************************************
# SUMMARY:      Audit Shared Folder Permissions
# AUTHOR:       Joshua Ogden
# DESCRIPTION:  This script audits the permissions on selected shared folders 
#               and their subfolders, exporting the information to a CSV file. 
#               It retrieves the folder path, share name, and the associated 
#               permissions for each folder and subfolder.
# COMPATIBILITY: Windows PowerShell 5.0 or higher
# NOTES:        Ensure you run this script with administrative privileges to 
#               access all shared folders and their permissions.
********************************************************************************
#>

# Import the necessary module for file share management
Import-Module -Name 'SmbShare'

# Define the output CSV file path
$csvFilePath = "C:\temp\SharedFolderPermissions_$(Get-Date -Format 'yyyyMMdd').csv"

# Initialize an empty array to store the audit results
$auditResults = @()

# Get the list of all shared folders
$sharedFolders = Get-SmbShare | Where-Object { $_.ScopeName -like "*" }

# Display the list of shared folders
Write-Output "Available Shared Folders:"
$sharedFolders | ForEach-Object { Write-Output "$($_.Name) - $($_.Path)" }

# Prompt user to select the shares to audit
$selectedShares = Read-Host "Enter the names of the shares you want to audit (comma-separated)"

# Convert the input string to an array
$selectedSharesArray = $selectedShares -split ','

# Function to get NTFS permissions of a folder
function Get-NTFSAccess {
    param (
        [string]$Path
    )
    try {
        $acl = Get-Acl -Path $Path
        foreach ($access in $acl.Access) {
            [PSCustomObject]@{
                Path          = $Path
                AccountName   = $access.IdentityReference
                AccessControl = $access.FileSystemRights
            }
        }
    } catch {
        Write-Warning "Failed to get ACL for $Path $_"
    }
}

# Iterate through each selected shared folder and retrieve permissions
foreach ($shareName in $selectedSharesArray) {
    $share = $sharedFolders | Where-Object { $_.Name -eq $shareName.Trim() }
    if ($null -eq $share) {
        Write-Warning "Share '$shareName' not found."
        continue
    }
    
    $sharePath = $share.Path
    Write-Output "Auditing Share: $shareName - Path: $sharePath"
    
    # Get permissions for the shared folder itself
    $permissions = Get-SmbShareAccess -Name $shareName.Trim()
    foreach ($permission in $permissions) {
        $auditResults += [PSCustomObject]@{
            ShareName     = $shareName.Trim()
            Path          = $sharePath
            AccountName   = $permission.Name
            AccessControl = $permission.AccessControlType
        }
    }
    
    # Get NTFS permissions for the shared folder and subfolders
    $folders = Get-ChildItem -Path $sharePath -Recurse -Directory
    $folders = @($sharePath) + $folders.FullName
    foreach ($folder in $folders) {
        Write-Output "Reading permissions for folder: $folder"
        $ntfsPermissions = Get-NTFSAccess -Path $folder
        $auditResults += $ntfsPermissions
    }
}

# Export the audit results to a CSV file
$auditResults | Export-Csv -Path $csvFilePath -NoTypeInformation

Write-Output "Shared folder permissions have been successfully exported to $csvFilePath"
