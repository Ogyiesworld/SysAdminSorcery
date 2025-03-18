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

# Define the output CSV file path and log file path
$timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
$outputDir = "C:\temp\ShareAudits"
$csvFilePath = Join-Path $outputDir "SharedFolderPermissions_$timestamp.csv"
$logFilePath = Join-Path $outputDir "AuditLog_$timestamp.log"

# Create output directory if it doesn't exist
if (-not (Test-Path $outputDir)) {
    New-Item -ItemType Directory -Path $outputDir | Out-Null
}

# Function to write to log file
function Write-Log {
    param(
        [string]$Message,
        [ValidateSet('Info', 'Warning', 'Error')]
        [string]$Level = 'Info'
    )
    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $logMessage = "[$timestamp] [$Level] $Message"
    Add-Content -Path $logFilePath -Value $logMessage
    switch ($Level) {
        'Info' { Write-Host $logMessage }
        'Warning' { Write-Host $logMessage -ForegroundColor Yellow }
        'Error' { Write-Host $logMessage -ForegroundColor Red }
    }
}

# Initialize an array to store the audit results
$auditResults = [System.Collections.ArrayList]::new()

# Function to compare access rules
function Compare-AccessRules {
    param (
        $Rule1,
        $Rule2
    )
    return ($Rule1.IdentityReference -eq $Rule2.IdentityReference) -and 
           ($Rule1.FileSystemRights -eq $Rule2.FileSystemRights) -and 
           ($Rule1.AccessControlType -eq $Rule2.AccessControlType) -and 
           ($Rule1.IsInherited -eq $Rule2.IsInherited)
}

# Function to get NTFS permissions of a folder with error handling
function Get-NTFSAccess {
    param (
        [string]$Path,
        [string]$ShareName,
        [string]$ParentPath
    )
    try {
        $acl = Get-Acl -Path $Path -ErrorAction Stop
        $parentAcl = if ($ParentPath) { Get-Acl -Path $ParentPath -ErrorAction SilentlyContinue }

        foreach ($access in $acl.Access) {
            # Check if this permission is different from parent
            $isDifferent = $true
            if ($parentAcl -and $access.IsInherited) {
                foreach ($parentAccess in $parentAcl.Access) {
                    if (Compare-AccessRules $access $parentAccess) {
                        $isDifferent = $false
                        break
                    }
                }
            }

            # If permission is not inherited or is different from parent, add it to the audit results
            if (-not $access.IsInherited -or $isDifferent) {
                $null = $auditResults.Add([PSCustomObject]@{
                    ShareName     = $ShareName
                    Path         = $Path
                    AccountName  = $access.IdentityReference
                    AccessType   = "NTFS"
                    AccessControl = $access.FileSystemRights
                    IsInherited  = $access.IsInherited
                    InheritanceFlags = $access.InheritanceFlags
                    PropagationFlags = $access.PropagationFlags
                    AccessControlType = $access.AccessControlType
                    TimeStamp   = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
                    ParentPath  = $ParentPath
                })
            }
        }

        # Check if inheritance is broken 
        if (-not $acl.AreAccessRulesProtected) {
            Write-Log "Inheritance enabled on: $Path" -Level 'Info'
        } else {
            Write-Log "Inheritance broken on: $Path" -Level 'Warning'
        }
    } catch {
        Write-Log "Failed to get ACL for $Path : $_" -Level 'Error'
    }
}

# Get all shares excluding system shares
$excludedShares = @('ADMIN$', 'C$', 'D$', 'IPC$')
$sharedFolders = Get-SmbShare | Where-Object { 
    $_.ScopeName -like "*" -and 
    $excludedShares -notcontains $_.Name -and 
    ![string]::IsNullOrEmpty($_.Path)
}

Write-Log "Found $($sharedFolders.Count) non-system shares to audit" -Level 'Info'

# Create a hashtable to track processed paths
$processedPaths = @{}

# Process each share
foreach ($share in $sharedFolders) {
    Write-Log "Processing share: $($share.Name) - $($share.Path)" -Level 'Info'
    
    # Get share permissions
    try {
        $permissions = Get-SmbShareAccess -Name $share.Name -ErrorAction Stop
        foreach ($permission in $permissions) {
            $null = $auditResults.Add([PSCustomObject]@{
                ShareName     = $share.Name
                Path         = $share.Path
                AccountName  = $permission.AccountName
                AccessType   = "Share"
                AccessControl = $permission.AccessRight
                IsInherited  = $false
                InheritanceFlags = "None"
                PropagationFlags = "None"
                AccessControlType = $permission.AccessControlType
                TimeStamp   = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
                ParentPath  = $null
            })
        }
    } catch {
        Write-Log "Failed to get share permissions for $($share.Name): $_" -Level 'Error'
        continue
    }
    
    # Process root folder
    if (-not $processedPaths.ContainsKey($share.Path)) {
        $processedPaths[$share.Path] = $true
        Get-NTFSAccess -Path $share.Path -ShareName $share.Name -ParentPath $null
    }
    
    # Process all subfolders
    try {
        $folders = Get-ChildItem -Path $share.Path -Recurse -Directory -ErrorAction Stop
        $totalFolders = $folders.Count
        $currentFolder = 0
        
        foreach ($folder in $folders) {
            $currentFolder++
            $percentComplete = [math]::Round(($currentFolder / $totalFolders) * 100, 2)
            Write-Progress -Activity "Processing $($share.Name)" -Status "$percentComplete% Complete" -PercentComplete $percentComplete
            
            # Always process each subfolder to check for unique permissions
            $parentPath = Split-Path -Parent $folder.FullName
            Get-NTFSAccess -Path $folder.FullName -ShareName $share.Name -ParentPath $parentPath
            $processedPaths[$folder.FullName] = $true
        }
        Write-Progress -Activity "Processing $($share.Name)" -Completed
    } catch {
        Write-Log "Error processing subfolders in $($share.Path): $_" -Level 'Error'
    }
}

# Export the audit results to a CSV file
try {
    $auditResults | Export-Csv -Path $csvFilePath -NoTypeInformation -Force
    Write-Log "Successfully exported audit results to $csvFilePath" -Level 'Info'
} catch {
    Write-Log "Failed to export results to CSV: $_" -Level 'Error'
}

# Output summary
$uniquePaths = $processedPaths.Keys.Count
$totalPermissions = $auditResults.Count
Write-Log "Audit Summary:" -Level 'Info'
Write-Log "- Total shares processed: $($sharedFolders.Count)" -Level 'Info'
Write-Log "- Unique paths processed: $uniquePaths" -Level 'Info'
Write-Log "- Total permissions recorded: $totalPermissions" -Level 'Info'
Write-Log "- Results saved to: $csvFilePath" -Level 'Info'
Write-Log "- Log file location: $logFilePath" -Level 'Info'
