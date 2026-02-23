# Run Development Script
# Runs Flutter app with verbose logging

param(
    [string]$Device = "",
    [string]$Cooperative = "NORANDINO"
)

Write-Host "[RUN] Panela Sys - Development Mode" -ForegroundColor Cyan
Write-Host "====================================" -ForegroundColor Cyan
Write-Host ""

# Build dart-defines
$dartDefines = @(
    "COOPERATIVE_CODE=$Cooperative"
)

Write-Host "[CONFIG] Configuration:" -ForegroundColor Yellow
Write-Host "  Cooperative: $Cooperative" -ForegroundColor Gray
Write-Host ""

# Check for devices
if ($Device -eq "") {
    Write-Host "[DEVICES] Available devices:" -ForegroundColor Yellow
    flutter devices
    Write-Host ""
    Write-Host "Starting on default device..." -ForegroundColor Green
    Write-Host ""

    # Run without device specification
    $defineArgs = $dartDefines | ForEach-Object { "--dart-define=$_" }
    flutter run $defineArgs
} else {
    Write-Host "Starting on device: $Device" -ForegroundColor Green
    Write-Host ""

    # Run with device specification
    $defineArgs = $dartDefines | ForEach-Object { "--dart-define=$_" }
    flutter run -d $Device $defineArgs
}
