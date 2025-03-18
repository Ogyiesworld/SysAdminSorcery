# This script will connect to Exchange Online and return the oldest email in the tenant

# Import the Exchange Online Management module
Import-Module ExchangeOnlineManagement

# Connect to Exchange Online
Write-Host "Connecting to Exchange Online..." -ForegroundColor Cyan
Connect-ExchangeOnline

try {
    Write-Host "Retrieving all mailboxes..." -ForegroundColor Cyan
    # Only get user mailboxes, exclude shared mailboxes and resources
    $mailboxes = Get-EXOMailbox -ResultSize Unlimited -RecipientTypeDetails UserMailbox -Properties DisplayName, UserPrincipalName
    
    $maxConcurrentJobs = 25  # Reduced to avoid throttling
    $mailboxResults = @()
    $processedCount = 0
    $mailboxCount = $mailboxes.Count

    Write-Host "Processing $mailboxCount mailboxes in parallel batches..." -ForegroundColor Cyan

    # Process mailboxes in parallel batches
    for ($i = 0; $i -lt $mailboxes.Count; $i += $maxConcurrentJobs) {
        $batch = $mailboxes | Select-Object -Skip $i -First $maxConcurrentJobs
        
        # Process each mailbox in the current batch
        foreach ($mailbox in $batch) {
            try {
                Write-Progress -Activity "Processing Mailboxes" -Status "Checking $($mailbox.DisplayName)" -PercentComplete (($processedCount / $mailboxCount) * 100)
                
                $stats = Get-EXOMailboxFolderStatistics -Identity $mailbox.UserPrincipalName -IncludeOldestAndNewestItems -ErrorAction Stop |
                        Where-Object { $_.OldestItemReceivedDate -ne $null } |
                        Sort-Object OldestItemReceivedDate |
                        Select-Object -First 1

                if ($stats) {
                    $mailboxResults += @{
                        Mailbox = $mailbox.DisplayName
                        Email = $mailbox.UserPrincipalName
                        Folder = $stats.Name
                        Date = $stats.OldestItemReceivedDate
                        Success = $true
                    }
                }
            }
            catch {
                $mailboxResults += @{
                    Mailbox = $mailbox.DisplayName
                    Email = $mailbox.UserPrincipalName
                    Error = $_.Exception.Message
                    Success = $false
                }
                Write-Warning "Error processing mailbox $($mailbox.DisplayName): $_"
            }
            
            $processedCount++
        }
        
        # Add a small delay between batches to avoid throttling
        Start-Sleep -Seconds 2
    }

    Write-Progress -Activity "Processing Mailboxes" -Completed

    # Display results sorted by date
    Write-Host "`nOldest Emails by Mailbox:" -ForegroundColor Green
    $successfulResults = $mailboxResults | Where-Object { $_.Success -eq $true }
    
    if ($successfulResults) {
        # Create formatted table
        $formattedResults = $successfulResults | 
            Sort-Object { $_.Date } |
            Select-Object @{N='Display Name';E={$_.Mailbox}},
                        @{N='Email';E={$_.Email}},
                        @{N='Folder';E={$_.Folder}},
                        @{N='Oldest Email Date';E={$_.Date}}
        
        # Export to CSV
        $csvPath = ".\MailboxOldestEmails_$(Get-Date -Format 'yyyyMMdd_HHmmss').csv"
        $formattedResults | Export-Csv -Path $csvPath -NoTypeInformation
        
        # Display results in console
        $formattedResults | Format-Table -AutoSize
        Write-Host "`nResults have been exported to: $csvPath" -ForegroundColor Cyan
    } else {
        Write-Host "`nNo emails found in any mailboxes." -ForegroundColor Yellow
    }

    # Report any errors
    $errors = $mailboxResults | Where-Object { $_.Success -eq $false }
    if ($errors) {
        Write-Host "`nErrors occurred in the following mailboxes:" -ForegroundColor Yellow
        foreach ($error in $errors) {
            Write-Host "Mailbox: $($error.Mailbox) - Error: $($error.Error)"
        }
    }
}
catch {
    Write-Error "An error occurred: $_"
}
finally {
    # Disconnect from Exchange Online
    Disconnect-ExchangeOnline -Confirm:$false -ErrorAction SilentlyContinue
}
