#!/usr/bin/env bash
# scripts/hooks/PreToolUse.sh — installed as .git/hooks/pre-commit
# Runs ktlint + ArchUnit checks locally to spare GitHub Actions minutes.

set -euo pipefail
echo "🛡️  pre-commit: running ktlint + architecture tests..."

./gradlew ktlintFormat --quiet
./gradlew :sharedUI:jvmTest --tests "*ArchitectureRulesTest" --quiet || {
  echo "❌ Clean Architecture violation detected. See ArchitectureRulesTest output."
  exit 1
}

echo "✅ pre-commit checks passed."

