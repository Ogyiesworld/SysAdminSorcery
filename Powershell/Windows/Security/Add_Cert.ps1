# Script to add a certificate to Windows Certificate Store for RADIUS server
param(
    [Parameter(Mandatory=$true)]
    [string]$CertificatePath,
    
    [Parameter(Mandatory=$false)]
    [string]$StoreName = "Root",
    
    [Parameter(Mandatory=$false)]
    [string]$StoreLocation = "LocalMachine"
)

# Function to write to log file
function Write-ToLog {
    param($Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] $Message"
    $logMessage | Out-File -FilePath "C:\temp\cert_install.log" -Append
    Write-Host $logMessage
}

# Ensure C:\temp exists
if (-not (Test-Path "C:\temp")) {
    New-Item -ItemType Directory -Path "C:\temp" | Out-Null
    Write-ToLog "Created C:\temp directory"
}

# Get computer name and user for logging
$computerName = $env:COMPUTERNAME
$userName = $env:USERNAME

Write-ToLog "Starting certificate installation on computer: $computerName by user: $userName"

# Check if running as administrator
$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    $errorMessage = "This script requires administrator privileges. Please run as administrator."
    Write-ToLog "ERROR: $errorMessage"
    Write-Error $errorMessage
    exit 1
}

try {
    # Verify the certificate file exists
    if (-not (Test-Path $CertificatePath)) {
        $errorMessage = "Certificate file not found at path: $CertificatePath"
        Write-ToLog "ERROR: $errorMessage"
        Write-Error $errorMessage
        exit 1
    }

    Write-ToLog "Found certificate file at: $CertificatePath"

    # Import the certificate
    $cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2
    $cert.Import($CertificatePath)
    Write-ToLog "Successfully loaded certificate"

    # Open the certificate store
    $store = New-Object System.Security.Cryptography.X509Certificates.X509Store($StoreName, $StoreLocation)
    $store.Open([System.Security.Cryptography.X509Certificates.OpenFlags]::ReadWrite)
    Write-ToLog "Opened certificate store: $StoreLocation\$StoreName"

    # Add the certificate
    $store.Add($cert)
    $store.Close()

    Write-ToLog "Certificate successfully imported to $StoreLocation\$StoreName store"
    Write-ToLog "Certificate Details:"
    Write-ToLog "- Subject: $($cert.Subject)"
    Write-ToLog "- Thumbprint: $($cert.Thumbprint)"
    Write-ToLog "- Valid from: $($cert.NotBefore) to $($cert.NotAfter)"
    
} catch {
    $errorMessage = "Error importing certificate: $_"
    Write-ToLog "ERROR: $errorMessage"
    Write-Error $errorMessage
    exit 1
}

Write-ToLog "Certificate installation completed successfully"