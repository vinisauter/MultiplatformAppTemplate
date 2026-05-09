# scripts/hooks/SessionStart.ps1
$ErrorActionPreference = 'Stop'
Write-Host "🔍 Validating KMP environment..."

try {
    $javaOutput = & java -version 2>&1
    $javaVersion = ($javaOutput | Select-String -Pattern '"(\d+)' | Select-Object -First 1).Matches.Groups[1].Value
    if ([int]$javaVersion -lt 17) { throw "JDK 17+ required (found $javaVersion)." }
    Write-Host "✅ JDK $javaVersion"
} catch {
    Write-Host "❌ ERROR: $_"
    exit 1
}

if (-not (Test-Path './gradlew.bat')) {
    Write-Host "⚠️  WARNING: gradlew.bat not found at repository root."
}

Write-Host "✅ Environment ready."

