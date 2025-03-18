# Import necessary module
Import-Module ActiveDirectory

# Function to log messages
Function Log-Message {
    param (
        [string]$message
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$timestamp - $message" | Out-File -Append -FilePath "script.log"
}

# Validate username input
Function Validate-Username {
    param (
        [string]$username
    )
    if (-not (Get-ADUser -Identity $username -ErrorAction SilentlyContinue)) {
        Write-Host "Invalid username. Please check and try again."
        Log-Message "Invalid username: $username"
        exit
    }
}

# Main script execution
try {
    # Prompt for username
    $username = Read-Host "Enter the username"
    Validate-Username -username $username

    # Prompt user for action choice
    $choice = Read-Host "Enter 1 to hide or 2 to unhide the user from Exchange Global Address List"
    
    # Confirm action
    $confirm = Read-Host "Are you sure you want to proceed with this action? (yes/no)"
    if ($confirm -ne "yes") {
        Write-Host "Action cancelled."
        Log-Message "Action cancelled by user."
        exit
    }

    switch ($choice) {
        "1" {
            Get-ADUser -Identity $username -Properties msExchHideFromAddressLists | 
            Set-ADUser -Replace @{msExchHideFromAddressLists = $true}
            Write-Host "User hidden from Exchange Global Address List."
            Log-Message "User $username hidden from Exchange Global Address List."
        }
        "2" {
            Get-ADUser -Identity $username -Properties msExchHideFromAddressLists | 
            Set-ADUser -Clear msExchHideFromAddressLists
            Write-Host "User unhidden from Exchange Global Address List."
            Log-Message "User $username unhidden from Exchange Global Address List."
        }
        default {
            Write-Host "Invalid choice. No action taken."
            Log-Message "Invalid choice entered: $choice"
        }
    }

    # Display the user's new exchange global address status
    Get-ADUser -Identity $username -Properties msExchHideFromAddressLists | Select-Object msExchHideFromAddressLists | Format-Table -AutoSize
    Log-Message "Displayed new status for user $username."
}
catch {
    Write-Host "An error occurred: $_"
    Log-Message "Error: $_"
}