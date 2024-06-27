<#
********************************************************************************
# SUMMARY:      Launch Microsoft Edge in app mode with specified settings
# AUTHOR:       Joshua Ogden
# DESCRIPTION:  This script launches Microsoft Edge in application mode to access
#               Microsoft Teams with custom window size and position.
# COMPATIBILITY: Windows 10, Windows Server 2016 or later
# NOTES:        Ensure Microsoft Edge is installed at the specified path.
********************************************************************************
#>

# Define the path to the Microsoft Edge executable
$EdgePath = "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"

# Define the URL for Microsoft Teams
$TeamsURL = "https://teams.microsoft.com"

# Define custom window size and position
$WindowSize = "800,600"
$WindowPosition = "100,100"

# Launch Microsoft Edge in app mode with the specified URL, size, and position
Start-Process -FilePath $EdgePath -ArgumentList "--app=$TeamsURL --window-size=$WindowSize --window-position=$WindowPosition"