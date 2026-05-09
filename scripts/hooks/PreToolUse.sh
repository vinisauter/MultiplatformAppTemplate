#!/usr/bin/env bash
# scripts/hooks/PreToolUse.sh — installed as .git/hooks/pre-commit
# Runs ktlint locally to spare GitHub Actions minutes.

set -euo pipefail
echo "🛡️  pre-commit: running ktlint..."

./gradlew ktlintFormat --quiet

# Optional: enforce Clean Architecture via a custom JVM test once you write it.
# ./gradlew :sharedUI:jvmTest --tests "*ArchitectureRulesTest" --quiet

echo "✅ pre-commit checks passed."
