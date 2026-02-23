# Check Offline Features Script
# Displays current state of offline feature flags

Write-Host "[CHECK] Offline Features Status" -ForegroundColor Cyan
Write-Host "===============================" -ForegroundColor Cyan
Write-Host ""

# Check if offline_config.dart exists
$configFile = "lib/core/offline/offline_config.dart"
if (-Not (Test-Path $configFile)) {
    Write-Host "[ERROR] Config file not found: $configFile" -ForegroundColor Red
    exit 1
}

# Read and parse config file
$content = Get-Content $configFile -Raw

# Extract feature flags
$producersEnabled = $content -match 'producers:\s*true'
$productionEnabled = $content -match 'production:\s*true'
$exitsEnabled = $content -match 'exits:\s*true'

# Display status
Write-Host "[STATUS] Feature Status:" -ForegroundColor Yellow
Write-Host ""

if ($producersEnabled) {
    Write-Host "  [ON] Producers:   ENABLED" -ForegroundColor Green
} else {
    Write-Host "  [OFF] Producers:   DISABLED" -ForegroundColor Gray
}

if ($productionEnabled) {
    Write-Host "  [ON] Production:  ENABLED" -ForegroundColor Green
} else {
    Write-Host "  [OFF] Production:  DISABLED" -ForegroundColor Gray
}

if ($exitsEnabled) {
    Write-Host "  [ON] Exits:       ENABLED" -ForegroundColor Green
} else {
    Write-Host "  [OFF] Exits:       DISABLED" -ForegroundColor Gray
}

Write-Host ""

# Count enabled features
$enabledCount = 0
if ($producersEnabled) { $enabledCount++ }
if ($productionEnabled) { $enabledCount++ }
if ($exitsEnabled) { $enabledCount++ }

Write-Host "[SUMMARY] $enabledCount/3 modules enabled" -ForegroundColor Cyan
Write-Host ""

# Check database files
Write-Host "[FILES] Database Files:" -ForegroundColor Yellow
Write-Host ""

$dbPath = "lib/core/database"
if (Test-Path $dbPath) {
    $tables = Get-ChildItem "$dbPath/tables" -Filter "*.dart" -ErrorAction SilentlyContinue | Measure-Object
    $daos = Get-ChildItem "$dbPath/daos" -Filter "*.dart" -ErrorAction SilentlyContinue | Measure-Object

    Write-Host "  Tables: $($tables.Count)" -ForegroundColor Gray
    Write-Host "  DAOs:   $($daos.Count)" -ForegroundColor Gray
} else {
    Write-Host "  [WARNING] Database folder not found (normal for Phase 1)" -ForegroundColor Yellow
}

Write-Host ""
