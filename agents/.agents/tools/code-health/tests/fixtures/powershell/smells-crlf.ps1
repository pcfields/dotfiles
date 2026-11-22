# One function per smell, for the end-to-end smell test.

function Get-Description {
    param([int]$Code)
    switch ($Code) {
        0 { return '0' }
        1 { return '1' }
        2 { return '2' }
        3 { return '3' }
        4 { return '4' }
        5 { return '5' }
        6 { return '6' }
        7 { return '7' }
        8 { return '8' }
        9 { return '9' }
        default { return 'unknown' }
    }
}

function Test-Deep($A, $B) {
    if ($A -gt 0) {
        if ($B -gt 0) {
            if ($A -gt $B) {
                if ($A -gt 100) {
                    return 1
                }
            }
        }
    }
    return 0
}

function Get-Bumpy([int[]]$Xs, [int[]]$Ys) {
    $total = 0
    foreach ($x in $Xs) {
        if ($x -gt 0) { $total += $x }
    }
    foreach ($y in $Ys) {
        if ($y -gt 0) { $total += $y }
    }
    return $total
}

function Test-Eligible($Customer) {
    if ($Customer.Active -and $Customer.Age -gt 17 -or $Customer.Override) {
        return $true
    }
    return $false
}

function Get-Large {
    $total = 0
    $total += 0
    $total += 1
    $total += 2
    $total += 3
    $total += 4
    $total += 5
    $total += 6
    $total += 7
    $total += 8
    $total += 9
    $total += 10
    $total += 11
    $total += 12
    $total += 13
    $total += 14
    $total += 15
    $total += 16
    $total += 17
    $total += 18
    $total += 19
    $total += 20
    $total += 21
    $total += 22
    $total += 23
    $total += 24
    $total += 25
    $total += 26
    $total += 27
    $total += 28
    $total += 29
    $total += 30
    $total += 31
    $total += 32
    $total += 33
    $total += 34
    $total += 35
    $total += 36
    $total += 37
    $total += 38
    $total += 39
    $total += 40
    $total += 41
    $total += 42
    $total += 43
    $total += 44
    $total += 45
    $total += 46
    $total += 47
    $total += 48
    $total += 49
    $total += 50
    $total += 51
    $total += 52
    $total += 53
    $total += 54
    $total += 55
    $total += 56
    $total += 57
    $total += 58
    $total += 59
    $total += 60
    $total += 61
    $total += 62
    $total += 63
    $total += 64
    $total += 65
    $total += 66
    $total += 67
    return $total
}

function Send-Order {
    param($Order, $To, $From, $Carrier, $When)
    return $Order
}

class Orders {
    Orders($Repo, $Log, $Clock, $Bus, $Cache, $Mapper, $Auth, $Flags) {
        $this.Repo = $Repo
    }
}

if ($args.Count -gt 0) {
    Get-Description -Code $args[0]
}
