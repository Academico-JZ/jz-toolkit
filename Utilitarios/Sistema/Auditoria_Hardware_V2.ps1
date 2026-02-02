<#
.SYNOPSIS
    Hardware & Account Audit V2
    Collects system info for SRE reports.
#>

$Report = @{
    PC          = $env:COMPUTERNAME
    User        = $env:USERNAME
    OS          = (Get-CimInstance Win32_OperatingSystem).Caption
    RAM         = "$(round((Get-CimInstance Win32_PhysicalMemory | Measure-Object Capacity -Sum).Sum / 1GB)) GB"
    CPU         = (Get-CimInstance Win32_Processor).Name
    Serial      = (Get-CimInstance Win32_BIOS).SerialNumber
    DiskFree    = "$(round((Get-PSDrive C).Free / 1GB)) GB"
}

$Report.GetEnumerator() | Sort-Object Name | ForEach-Object {
    Write-Host "$($_.Name):" -NoNewline -ForegroundColor Cyan
    Write-Host " $($_.Value)" -ForegroundColor White
}
