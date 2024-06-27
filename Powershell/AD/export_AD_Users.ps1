# Get the current date in the format "yyyyMMdd"
$date = Get-Date -Format "yyyyMMdd"

# Define the CSV file path
$csvPath = "C:\temp\ad_users_$date.csv"

# Get all properties of all AD users and export them to a CSV file
Get-ADUser -Filter * -Properties * |
    Select-Object -Property * |
    Export-Csv -Path $csvPath -NoTypeInformation
