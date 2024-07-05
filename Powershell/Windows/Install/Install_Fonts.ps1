# Get all TTF font files in the current directory and its subdirectories
$fontFiles = Get-ChildItem -Path (Get-Location) -Filter "*.ttf" -Recurse -File
$totalFonts = $fontFiles.Count
$completedFonts = 0

# Check if there are fonts to install
if ($totalFonts -eq 0) {
    Write-Host "No fonts found to install."
    exit
}

# Load the System.Drawing assembly
Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;

public class FontInstaller
{
    [DllImport("gdi32.dll")]
    private static extern int AddFontResource(string lpszFilename);

    public static void InstallFont(string fontFile)
    {
        if (FontExists(fontFile))
        {
            throw New-Object System.Exception("Font already installed: $fontFile")
        }
        AddFontResource(fontFile);
    }

    private static bool FontExists(string fontFile)
    {
        $fontRegistryPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts"
        $fontRegistryKeys = Get-ChildItem -Path $fontRegistryPath -ErrorAction SilentlyContinue | Get-ItemProperty -ErrorAction SilentlyContinue
        $fontRegistryKeys.PSObject.Properties.Value -contains $fontFile
    }

"@ -ErrorAction Stop

# Install each font and update progress
foreach ($fontFile in $fontFiles) {
    try {
        [FontInstaller]::InstallFont($fontFile.FullName)
        $completedFonts++
        $progressPercentage = [math]::Round(($completedFonts / $totalFonts) * 100)
        Write-Progress -Activity "Installing Fonts" -Status "Progress: $progressPercentage%" -PercentComplete $progressPercentage
    } catch {
        Write-Host "Failed to install font: $($fontFile.FullName) with error: $($_.Message)"
    }
}

Write-Host "$completedFonts out of $totalFonts fonts were installed successfully."
