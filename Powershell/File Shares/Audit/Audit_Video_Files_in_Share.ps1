<#
********************************************************************************
# SUMMARY:      List Video Files in Drive
# AUTHOR:       Joshua Ogden
# DESCRIPTION:  This script recursively searches through a specified drive for 
#               video files and exports their names and directory locations 
#               to a CSV file.
# COMPATIBILITY: Windows PowerShell 5.1 and above
# NOTES:        Ensure the script is run with sufficient permissions to access 
#               all directories on the target drive.
********************************************************************************
#>

# Variable Declaration
$DriveLetter = Read-Host "Enter the drive letter you want to search (e.g. D:\)"
$OutputFileName = "C:\temp\VideoFilesInfo_$((Get-Date).ToString('MMM-d-yyyy')).csv"

# Define video file extensions
$VideoExtensions = @(".m4v, .mp4", ".avi", ".mkv", ".mov", ".flv", ".wmv")

# Function to Check and List Video Files
function Get-VideoFiles {
    param (
        [string]$Path,
        [string[]]$Extensions
    )

    $VideoFiles = @()

    function Get-FilesInDirectory {
        param (
            [string]$DirectoryPath
        )

        try {
            Get-ChildItem -Path $DirectoryPath -Recurse -File -ErrorAction Stop | ForEach-Object {
                try {
                    if ($Extensions -contains $_.Extension) {
                        $VideoFiles += [PSCustomObject]@{
                            FullName     = $_.FullName
                            DirectoryName  = $_.DirectoryName
                            Name           = $_.Name
                        }
                    }
                } catch {
                    Write-Warning "Error processing file $_.FullName: $_"
                }
            }
        } catch {
            Write-Warning "Error accessing path $DirectoryPath $_"
        }
    }

    try {
        Get-ChildItem -Path $Path -Directory -Recurse -ErrorAction Stop | ForEach-Object {
            Get-FilesInDirectory -DirectoryPath $_.FullName
        }
    } catch {
        Write-Warning "Error accessing path $Path $_"
    }

    return $VideoFiles
}

# Execution Block
try {
    $VideoFiles = Get-VideoFiles -Path $DriveLetter -Extensions $VideoExtensions
    if ($VideoFiles) {
        $VideoFiles | Export-Csv -Path $OutputFileName -NoTypeInformation
        Write-Host "Video file information has been successfully exported to $OutputFileName"
    } else {
        Write-Host "No video files found on the specified drive."
    }
} catch {
    Write-Error "An error occurred during script execution: $_"
}