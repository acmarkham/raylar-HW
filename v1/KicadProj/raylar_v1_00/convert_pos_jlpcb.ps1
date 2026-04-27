param(
    [Parameter(Mandatory = $true)]
    [string]$InputCsv,

    [Parameter(Mandatory = $true)]
    [string]$OutputCsv
)

$ErrorActionPreference = 'Stop'

try {
    if (-not (Test-Path $InputCsv)) {
        throw "Input file not found: $InputCsv"
    }

    $rows = Import-Csv -Path $InputCsv -Delimiter ','

    $rows |
        Select-Object `
            @{Name='Designator'; Expression = { $_.Ref }},
            @{Name='Val';        Expression = { $_.Val }},
            @{Name='Package';    Expression = { $_.Package }},
            @{Name='Mid X';      Expression = { $_.PosX }},
            @{Name='Mid Y';      Expression = { $_.PosY }},
            @{Name='Rotation';   Expression = { $_.Rot }},
            @{Name='Layer';      Expression = { $_.Side }} |
        Export-Csv -Path $OutputCsv -NoTypeInformation -Encoding UTF8

    Write-Host "Wrote: $OutputCsv"
}
catch {
    Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}