# Ejecutar desde la raíz del repositorio (PowerShell): .\ejecutar.ps1
Set-Location $PSScriptRoot
flutter doctor
if (-not (Test-Path android)) { flutter create --project-name matrlab --platforms android,web . }
flutter pub get
flutter analyze 2>&1 | Tee-Object -FilePath salida_analyze.txt
flutter test --reporter expanded 2>&1 | Tee-Object -FilePath salida_test.txt
Write-Host "Capturas en .\capturas ; salidas en salida_analyze.txt y salida_test.txt"
