#!/usr/bin/env bash
# scripts/hooks/PreToolUse.sh — installed as .git/hooks/pre-commit
# Runs ktlint locally to spare GitHub Actions minutes.

set -euo pipefail
echo "🛡️  pre-commit: running ktlint..."

./gradlew ktlintFormat --quiet || {
  echo "❌ pre-commit checks failed. Please run './gradlew ktlintFormat' locally to fix formatting issues before committing."
  exit 1
}

echo "✅ pre-commit checks passed."
