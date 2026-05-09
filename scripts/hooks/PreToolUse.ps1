# scripts/hooks/PreToolUse.ps1 — installed as .git/hooks/pre-commit (Windows)
$ErrorActionPreference = 'Stop'
Write-Host "🛡️  pre-commit: running ktlint..."

& ./gradlew.bat ktlintFormat --quiet
if ($LASTEXITCODE -ne 0) { Write-Host "❌ ktlint failed."; exit 1 }

# Optional: enforce Clean Architecture via a custom JVM test once you write it.
# & ./gradlew.bat :sharedUI:jvmTest --tests "*ArchitectureRulesTest" --quiet

Write-Host "✅ pre-commit checks passed."
