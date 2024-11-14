<#
********************************************************************************
# SUMMARY:      Directory Ownership and Permission Management
# AUTHOR:       Your Name
# DESCRIPTION:  This script validates a directory path, takes ownership of it,
#               and grants full control permissions to a specified user.
# COMPATIBILITY: Windows PowerShell 5.1 and above
# NOTES:        Ensure the script is run with administrative privileges.
# PARAMETERS:   
#   -DirectoryPath: The path to the directory.
#   -User: The user to whom permissions will be granted.
# EXAMPLE:      
#   .\ManageDirectoryPermissions.ps1
********************************************************************************
#>

# Function to validate the directory path
function Validate-DirectoryPath {
    param (
        [Parameter(Mandatory=$true)][string]$Path
    )
    if (-Not (Test-Path $Path)) {
        Write-Error "Invalid directory path: $Path"
        exit 1
    }
}

# Function to take ownership of the directory
function Take-Ownership {
    param (
        [Parameter(Mandatory=$true)][string]$Path
    )
    try {
        & takeown /f $Path /r /d y | Out-Null
        Write-Host "Ownership taken successfully for $Path" -ForegroundColor Green
    } catch {
        Write-Error "Failed to take ownership of $Path: $_"
        exit 1
    }
}

# Function to grant permissions
function Grant-Permissions {
    param (
        [Parameter(Mandatory=$true)][string]$Path,
        [Parameter(Mandatory=$true)][string]$User
    )
    try {
        & icacls $Path /grant "$User:F" /t | Out-Null
        Write-Host "Full control permissions granted to $User for $Path" -ForegroundColor Green
    } catch {
        Write-Error "Failed to grant permissions for $Path: $_"
        exit 1
    }
}

# Main script execution
try {
    $Directory_Path = Read-Host "Insert directory path here"
    $User = Read-Host "Insert user name here"

    # Validate inputs
    Validate-DirectoryPath -Path $Directory_Path

    # Execute functions
    Take-Ownership -Path $Directory_Path
    Grant-Permissions -Path $Directory_Path -User $User

} catch {
    Write-Error "An unexpected error occurred: $_"
    exit 1
}
