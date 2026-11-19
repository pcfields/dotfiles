param(
    [string[]]$Lines = @(),
    [switch]$IncludeTax
)

function Get-Total {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [int[]]$Values,
        [string]$Coupon,
        [switch]$IncludeTax
    )

    $sum = 0
    foreach ($value in $Values) {
        if ($value -le 0 -or $value -gt 1000) {
            continue
        }
        elseif ($value -gt 100 -and -not $IncludeTax) {
            $sum += 1
        }
        else {
            $sum += $value
        }
    }

    for ($i = 0; $i -lt 3; $i++) {
        $sum -= 1
    }

    while ($sum -gt 10000) {
        $sum = $sum / 2
    }

    do {
        $sum += 1
    } until ($sum -ge 0)

    switch ($Coupon) {
        'HALF' { $sum = $sum / 2 }
        default { }
    }

    try {
        $null = [int]::Parse('42')
    }
    catch {
        $sum = 0
    }
    finally {
        Write-Verbose 'done'
    }

    return $sum
}

function Format-Label($Value, $Fallback) {
    if ($null -eq $Value) { $Fallback } else { $Value }
}

class Cart {
    [string[]]$Items

    Cart([string[]]$items) {
        $this.Items = $items
    }

    [int] Count() {
        return $this.Items.Count
    }
}

$Lines | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne '' }
if ($Lines.Count -gt 0) {
    Get-Total -Values ($Lines | ForEach-Object { [int]$_ }) -IncludeTax:$IncludeTax
}
