<#
********************************************************************************
# SUMMARY:      Audit File Search
# AUTHOR:       Your Name
# DESCRIPTION:  This script recursively searches through a specified drive for 
#               files matching a given pattern and exports their names and 
#               directory locations to a CSV file.
# COMPATIBILITY: Windows PowerShell 5.1 and above
# NOTES:        Ensure the script is run with sufficient permissions to access 
#               all directories on the target drive.
# PARAMETERS:   
#   -DriveLetter: The letter of the drive to search.
#   -FileName: The file name or pattern to search for.
#   -Extensions: The file extensions to include in the search.
********************************************************************************
#>

# Function to Check and List Files
function Get-Files {
    param (
        [Parameter(Mandatory=$true)][string]$Path,
        [Parameter(Mandatory=$true)][string[]]$Extensions,
        [Parameter(Mandatory=$true)][string]$FileName
    )

    $Files = @()

    function Get-FilesInDirectory {
        param (
            [string]$DirectoryPath
        )

        try {
            Get-ChildItem -Path $DirectoryPath -Recurse -File -ErrorAction Stop | ForEach-Object {
                try {
                    if ($Extensions -contains $_.Extension -or $_.Name -like "*$FileName*") {
                        $Files += [PSCustomObject]@{
                            FullName     = $_.FullName
                            DirectoryName  = $_.DirectoryName
                            Name           = $_.Name
                        }
                    }
                } catch {
                    Write-Warning "Error processing file $($_.FullName): $_"
                }
            }
        } catch {
            Write-Warning "Error accessing path $DirectoryPath: $_"
        }
    }

    try {
        Get-ChildItem -Path $Path -Directory -Recurse -ErrorAction Stop | ForEach-Object {
            Get-FilesInDirectory -DirectoryPath $_.FullName
        }
    } catch {
        Write-Warning "Error accessing path $Path: $_"
    }

    return $Files
}

# Main Script Execution
try {
    # Variable Declaration
    $DriveLetter = Read-Host "Enter the drive letter you want to search (e.g. D:\)"
    $OutputFileName = "C:\temp\FilesInfo_$((Get-Date).ToString('MMM-d-yyyy')).csv"

    # Input the file name or part of the file name
    $FileName = Read-Host "Enter the file name or part of the file name"

    # Define file extensions
    $Extensions = Read-Host "Enter the extensions separated by commas (e.g. .txt, .docx, *)"
    $Extensions = $Extensions -split ','

    # Get files and export to CSV
    $Files = Get-Files -Path $DriveLetter -Extensions $Extensions -FileName $FileName
    if ($Files.Count -gt 0) {
        $Files | Export-Csv -Path $OutputFileName -NoTypeInformation
        Write-Host "File information has been successfully exported to $OutputFileName" -ForegroundColor Green
    } else {
        Write-Host "No files found on the specified drive." -ForegroundColor Yellow
    }
} catch {
    Write-Error "An error occurred during script execution: $_"
}
