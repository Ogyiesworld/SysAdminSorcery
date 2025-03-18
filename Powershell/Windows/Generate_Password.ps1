function Generate-Password {
    param (
        [int]$Length = 12,
        [bool]$IncludeLower = $true,
        [bool]$IncludeUpper = $true,
        [bool]$IncludeNumber = $true,
        [bool]$IncludeSymbol = $true
    )

    $chars = ""
    if ($IncludeLower) { $chars += "abcdefghijklmnopqrstuvwxyz" }
    if ($IncludeUpper) { $chars += "ABCDEFGHIJKLMNOPQRSTUVWXYZ" }
    if ($IncludeNumber) { $chars += "0123456789" }
    if ($IncludeSymbol) { $chars += "!@#$%^&*()_+" }

    $password = ""
    for ($i = 0; $i -lt $Length; $i++) {
        $randomIndex = Get-Random -Maximum $chars.Length
        $password += $chars[$randomIndex]
    }

    return $password
}

# Generate a 16-character password with all character types
$password = Generate-Password -Length 16
$password