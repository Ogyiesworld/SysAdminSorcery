<#
********************************************************************************
# SUMMARY:      Export GPO Details to Markdown with Enhanced Formatting
# AUTHOR:       Joshua Ogden
# DESCRIPTION:  This script exports Group Policy Objects (GPOs) details to markdown files with improved readability and formatting, uniquely identifying GPOs using GUIDs.
# COMPATIBILITY: Windows with Active Directory and Group Policy Management Console installed.
# NOTES:        Ensure you have the necessary permissions to access GPO details.
********************************************************************************
#>

# Variable Declaration
$outputFolder = Join-Path -Path ([Environment]::GetFolderPath('Desktop')) -ChildPath "GPO_Policies"

# Create the output folder if it doesn't exist
if (-not (Test-Path -Path $outputFolder)) {
    New-Item -Path $outputFolder -ItemType Directory | Out-Null
    Write-Output "Created output folder: $outputFolder"
}

# Function to export GPO details to a markdown file
function Export-GPODetailsToMarkdown {
    param (
        [Parameter(Mandatory = $true)]
        [string]$GpoName,
        [Parameter(Mandatory = $true)]
        [string]$GpoGuid,
        [string]$OutputFolder
    )
    
    # Sanitize GPO name to create a valid filename
    $sanitizedGpoName = $GpoName -replace '[^\w\s-]', '' -replace '\s+', '_' 
    
    # Define the output markdown file path
    $outputFilePath = Join-Path -Path $OutputFolder -ChildPath ("$sanitizedGpoName.md")
    
    # Retrieve the GPO details
    try {
        $gpo = Get-GPO -Guid $GpoGuid -ErrorAction Stop
        $report = Get-GPOReport -Guid $gpo.Id -ReportType Html -ErrorAction Stop
        $gpoDetails = [System.Text.RegularExpressions.Regex]::Replace($report, '<[^>]*>', '')

        # Write GPO details to markdown file
        @"
# Group Policy Object: **$($gpo.DisplayName)**

- **GUID:** $($gpo.Id)
- **Domain:** $($gpo.DomainName)
- **Created:** $($gpo.CreationTime.ToString("MMMM d, yyyy"))
- **Modified:** $($gpo.ModificationTime.ToString("MMMM d, yyyy"))

## Settings:
$gpoDetails
"@ | Set-Content -Path $outputFilePath

        Write-Output "Exported GPO details for '$GpoName' to $outputFilePath"
    }
    catch {
        Write-Warning "Failed to export GPO details for '$GpoName'. Error: $_"
    }
}

# Get all GPOs in the domain and export them
$allGPOs = Get-GPO -All -ErrorAction SilentlyContinue

if ($allGPOs) {
    foreach ($gpo in $allGPOs) {
        Export-GPODetailsToMarkdown -GpoName $gpo.DisplayName -GpoGuid $gpo.Id -OutputFolder $outputFolder
    }
}
else {
    Write-Warning "No GPOs found in the domain."
}

Write-Output "Export complete. Markdown files are located in $outputFolder"