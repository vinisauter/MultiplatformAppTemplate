# scripts/hooks/PostToolUse.ps1 — installed as .git/hooks/pre-push (Windows)
$ErrorActionPreference = 'Stop'
Write-Host "🛡️  pre-push: running JVM + common metadata compile..."

& ./gradlew.bat check jvmTest compileCommonMainKotlinMetadata --parallel
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Push blocked. KMP integrity tests failed — fix locally before consuming CI minutes."
    exit 1
}
Write-Host "✅ Push allowed."

