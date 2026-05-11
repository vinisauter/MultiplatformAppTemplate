# scripts/hooks/PreToolUse.ps1 - installed as .git/hooks/pre-commit (Windows)
$ErrorActionPreference = 'Stop'
Write-Host "🛡️  pre-commit: running ktlint..."

& ./gradlew.bat ktlintFormat --quiet
if ($LASTEXITCODE -ne 0) { Write-Host " ❌ pre-commit checks failed. Please run './gradlew ktlintFormat' locally to fix formatting issues before committing."; exit 1 }

Write-Host "✅ pre-commit checks passed."
