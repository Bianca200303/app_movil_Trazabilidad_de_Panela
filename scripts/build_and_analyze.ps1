# Build and Analyze Script
# Runs full build with Drift code generation and static analysis

Write-Host "[BUILD] Panela Sys - Build and Analyze" -ForegroundColor Cyan
Write-Host "=======================================" -ForegroundColor Cyan
Write-Host ""

# Step 1: Clean build
Write-Host "[STEP 1] Cleaning build artifacts..." -ForegroundColor Yellow
flutter clean
if ($LASTEXITCODE -ne 0) {
    Write-Host "[ERROR] Clean failed" -ForegroundColor Red
    exit 1
}
Write-Host "[OK] Clean complete" -ForegroundColor Green
Write-Host ""

# Step 2: Get dependencies
Write-Host "[STEP 2] Getting dependencies..." -ForegroundColor Yellow
flutter pub get
if ($LASTEXITCODE -ne 0) {
    Write-Host "[ERROR] Pub get failed" -ForegroundColor Red
    exit 1
}
Write-Host "[OK] Dependencies installed" -ForegroundColor Green
Write-Host ""

# Step 3: Generate Drift code
Write-Host "[STEP 3] Generating Drift code..." -ForegroundColor Yellow
dart run build_runner build --delete-conflicting-outputs
if ($LASTEXITCODE -ne 0) {
    Write-Host "[ERROR] Build runner failed" -ForegroundColor Red
    exit 1
}
Write-Host "[OK] Code generation complete" -ForegroundColor Green
Write-Host ""

# Step 4: Analyze code
Write-Host "[STEP 4] Running static analysis..." -ForegroundColor Yellow
flutter analyze
if ($LASTEXITCODE -ne 0) {
    Write-Host "[WARNING] Analysis found issues" -ForegroundColor Yellow
} else {
    Write-Host "[OK] No analysis issues" -ForegroundColor Green
}
Write-Host ""

Write-Host "[DONE] Build and analyze complete!" -ForegroundColor Green
