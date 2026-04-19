# PowerShell script para construir el APK unificado
# Un solo APK sirve para todas las cooperativas.
# La cooperativa se selecciona la primera vez que el usuario abre la app.

$ErrorColor = "Red"
$SuccessColor = "Green"
$InfoColor = "Cyan"

Write-Host ""
Write-Host "========================================"
Write-Host "  Building APK - Panela UDEP"
Write-Host "========================================"
Write-Host ""

# Verificar que estamos en el directorio flutter/
if (-not (Test-Path "pubspec.yaml")) {
    Write-Host "Error: Este script debe ejecutarse desde el directorio flutter/" -ForegroundColor $ErrorColor
    Write-Host "Directorio actual: $PWD" -ForegroundColor $ErrorColor
    exit 1
}

$buildCommand = "flutter build apk --release --dart-define=USE_LOCAL_SUPABASE=false"
Write-Host "Comando: $buildCommand" -ForegroundColor $InfoColor
Write-Host ""

Invoke-Expression $buildCommand

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "[OK] Build completado exitosamente!" -ForegroundColor $SuccessColor
    Write-Host ""
    Write-Host "APK generado en:" -ForegroundColor $InfoColor
    Write-Host "  build\app\outputs\flutter-apk\app-release.apk" -ForegroundColor $SuccessColor
    Write-Host ""
    Write-Host "Este APK único sirve para NORANDINO y CAES." -ForegroundColor $InfoColor
    Write-Host "Cada usuario ingresa el código de su cooperativa al abrir la app por primera vez." -ForegroundColor $InfoColor
    exit 0
} else {
    Write-Host ""
    Write-Host "[ERROR] El build falló!" -ForegroundColor $ErrorColor
    exit 1
}
