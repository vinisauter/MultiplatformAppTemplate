#!/usr/bin/env bash
# scripts/hooks/PostToolUse.sh — installed as .git/hooks/pre-push
# Final shift-left guardrail to protect the 2,000-min GitHub Actions Free budget.

set -euo pipefail
echo "🛡️  pre-push: running project checks + common metadata compile..."

./gradlew check compileCommonMainKotlinMetadata --parallel || {
  echo "❌ Push blocked. KMP integrity tests failed — fix locally before consuming CI minutes."
  exit 1
}

echo "✅ Push allowed."

