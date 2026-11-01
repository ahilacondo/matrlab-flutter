# Ejecutar desde la raíz del repositorio (PowerShell): .\ejecutar.ps1
Set-Location $PSScriptRoot
flutter doctor
if (-not (Test-Path android)) { flutter create --project-name matrlab --platforms android,web . }
flutter pub get
flutter analyze 2>&1 | Tee-Object -FilePath salida_analyze.txt
flutter test --reporter expanded 2>&1 | Tee-Object -FilePath salida_test.txt
git log --reverse --date=iso --pretty=format:"%h|%ad|%s" | Out-File -Encoding utf8 historial_git.txt
Write-Host "Capturas en .\capturas ; salidas en salida_analyze.txt, salida_test.txt e historial_git.txt"
