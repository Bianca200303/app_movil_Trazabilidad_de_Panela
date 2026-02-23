# Drift Database Sync Script
# Runs build_runner in watch mode for continuous code generation

Write-Host "[WATCH] Drift Watch Mode - Sync Database" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "This will watch for changes in database tables and generate code automatically." -ForegroundColor Gray
Write-Host "Press Ctrl+C to stop." -ForegroundColor Gray
Write-Host ""

# Ensure dependencies are up to date
Write-Host "[DEPS] Checking dependencies..." -ForegroundColor Yellow
flutter pub get
if ($LASTEXITCODE -ne 0) {
    Write-Host "[ERROR] Pub get failed" -ForegroundColor Red
    exit 1
}
Write-Host ""

# Start watch mode
Write-Host "[SYNC] Starting watch mode..." -ForegroundColor Green
Write-Host ""
dart run build_runner watch --delete-conflicting-outputs
