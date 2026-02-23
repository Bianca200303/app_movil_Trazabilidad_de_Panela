# Debug Logs Filter Script
# Filters and displays debug logs from Flutter app

param(
    [switch]$SyncOnly,
    [switch]$ErrorsOnly,
    [switch]$All
)

Write-Host "[DEBUG] Debug Logs Filter" -ForegroundColor Cyan
Write-Host "=========================" -ForegroundColor Cyan
Write-Host ""

if ($SyncOnly) {
    Write-Host "Filtering: Sync operations only" -ForegroundColor Yellow
    Write-Host "Press Ctrl+C to stop." -ForegroundColor Gray
    Write-Host ""
    flutter run | Select-String -Pattern "Sync|sync|DAO|Dao"
}
elseif ($ErrorsOnly) {
    Write-Host "Filtering: Errors and warnings only" -ForegroundColor Yellow
    Write-Host "Press Ctrl+C to stop." -ForegroundColor Gray
    Write-Host ""
    flutter run | Select-String -Pattern "ERROR|WARNING|error|warning|Exception"
}
elseif ($All) {
    Write-Host "Showing: All logs" -ForegroundColor Yellow
    Write-Host "Press Ctrl+C to stop." -ForegroundColor Gray
    Write-Host ""
    flutter run
}
else {
    Write-Host "Usage:" -ForegroundColor Yellow
    Write-Host "  .\debug_logs.ps1 -SyncOnly    # Show only sync operations"
    Write-Host "  .\debug_logs.ps1 -ErrorsOnly  # Show only errors and warnings"
    Write-Host "  .\debug_logs.ps1 -All         # Show all logs"
    Write-Host ""
    Write-Host "Examples:" -ForegroundColor Gray
    Write-Host "  .\debug_logs.ps1 -SyncOnly    # Track synchronization"
    Write-Host "  .\debug_logs.ps1 -ErrorsOnly  # Debug errors"
    Write-Host ""
}
