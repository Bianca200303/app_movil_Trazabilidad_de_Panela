# PowerShell script to build APKs for both cooperatives
# This script builds release APKs for NORANDINO and CAES flavors

# Colors for output
$ErrorColor = "Red"
$SuccessColor = "Green"
$InfoColor = "Cyan"

Write-Host ""
Write-Host "========================================"
Write-Host "  Building APKs for Both Cooperatives"
Write-Host "========================================"
Write-Host ""

# Verify we're in the flutter directory
if (-not (Test-Path "pubspec.yaml")) {
    Write-Host "Error: This script must be run from the flutter/ directory" -ForegroundColor $ErrorColor
    Write-Host "Current directory: $PWD" -ForegroundColor $ErrorColor
    exit 1
}

# Function to build APK for a specific flavor
function Build-FlavorAPK {
    param(
        [string]$FlavorName,
        [string]$CooperativeCode,
        [string]$DisplayName
    )

    Write-Host ""
    Write-Host "----------------------------------------" -ForegroundColor $InfoColor
    Write-Host "Building $DisplayName" -ForegroundColor $InfoColor
    Write-Host "----------------------------------------" -ForegroundColor $InfoColor

    $buildCommand = "flutter build apk --release --flavor $FlavorName --dart-define=COOPERATIVE_CODE=$CooperativeCode --dart-define=USE_LOCAL_SUPABASE=false"
    Write-Host "Command: $buildCommand" -ForegroundColor $InfoColor

    # Execute the build command
    Invoke-Expression $buildCommand

    if ($LASTEXITCODE -eq 0) {
        Write-Host ""
        Write-Host "[OK] $DisplayName build completed successfully!" -ForegroundColor $SuccessColor
        return $true
    } else {
        Write-Host ""
        Write-Host "[ERROR] $DisplayName build failed!" -ForegroundColor $ErrorColor
        return $false
    }
}

# Build counters
$successCount = 0
$totalBuilds = 2

# Build NORANDINO APK
if (Build-FlavorAPK -FlavorName "norandino" -CooperativeCode "NORANDINO" -DisplayName "NORANDINO - Captura UDEP") {
    $successCount++
}

# Build CAES APK
if (Build-FlavorAPK -FlavorName "caes" -CooperativeCode "CAES" -DisplayName "CAES - Captura UDEP") {
    $successCount++
}
# Summary
Write-Host ""
Write-Host "========================================"
Write-Host "  Build Summary"
Write-Host "========================================"
Write-Host "Successful builds: $successCount / $totalBuilds" -ForegroundColor $(if ($successCount -eq $totalBuilds) { $SuccessColor } else { $ErrorColor })

if ($successCount -gt 0) {
    Write-Host ""
    Write-Host "APK locations:" -ForegroundColor $InfoColor

    if (Test-Path "build\app\outputs\flutter-apk\app-norandino-release.apk") {
        Write-Host "  - NORANDINO: build\app\outputs\flutter-apk\app-norandino-release.apk" -ForegroundColor $SuccessColor
    }

    if (Test-Path "build\app\outputs\flutter-apk\app-caes-release.apk") {
        Write-Host "  - CAES: build\app\outputs\flutter-apk\app-caes-release.apk" -ForegroundColor $SuccessColor
    }
}

Write-Host ""
Write-Host "Done!"
Write-Host ""

# Exit with appropriate code
if ($successCount -eq $totalBuilds) {
    exit 0
} else {
    exit 1
}
