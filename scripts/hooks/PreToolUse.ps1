# scripts/hooks/PreToolUse.ps1 — installed as .git/hooks/pre-commit (Windows)
$ErrorActionPreference = 'Stop'
Write-Host "🛡️  pre-commit: running ktlint + architecture tests..."

& ./gradlew.bat ktlintFormat --quiet
if ($LASTEXITCODE -ne 0) { Write-Host "❌ ktlint failed."; exit 1 }

& ./gradlew.bat :sharedUI:jvmTest --tests "*ArchitectureRulesTest" --quiet
if ($LASTEXITCODE -ne 0) { Write-Host "❌ Clean Architecture violation."; exit 1 }

Write-Host "✅ pre-commit checks passed."

