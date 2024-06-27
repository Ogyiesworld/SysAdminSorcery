# Prompt for the source and target groups
$Group1 = Read-Host -Prompt 'Select the group of users you want to move from'
$Group2 = Read-Host -Prompt 'Select the group where the users will be moved to'

# Retrieve distinguished names of members of the first group
$Members = Get-ADGroupMember -Identity $Group1 -ErrorAction Stop | Select-Object -ExpandProperty distinguishedName

# Determine the count to move, limiting to the first 100 members
$Count = $Members.Count
If ($Count -gt 100) { $Count = 100 }

# Prepare an array of members to move
$UsersToMove = $Members | Select-Object -First $Count

# Validate non-empty user list before proceeding
if ($UsersToMove.Count -gt 0) {
    try {
        # Copy the members to the second group
        Add-ADGroupMember -Identity $Group2 -Members $UsersToMove -ErrorAction Stop

        # Remove the members from the first group
        Remove-ADGroupMember -Identity $Group1 -Members $UsersToMove -Confirm:$false -ErrorAction Stop

        Write-Host "Successfully moved $Count member(s) from '$Group1' to '$Group2'." -ForegroundColor Green
    } catch {
        Write-Error "An error occurred: $_"
    }
} else {
    Write-Host "No members found in '$Group1' to move." -ForegroundColor Yellow
}
