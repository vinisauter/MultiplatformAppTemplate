#!/usr/bin/env bash
# scripts/hooks/SessionStart.sh
# Validates the local environment for a KMP + Copilot session.

set -euo pipefail

echo "🔍 Validating KMP environment..."

# JDK 17+
if ! command -v java >/dev/null 2>&1; then
  echo "❌ ERROR: Java not installed."
  exit 1
fi
JAVA_VERSION=$(java -version 2>&1 | awk -F '"' '/version/ {print $2}' | cut -d. -f1)
if [ "$JAVA_VERSION" -lt 17 ]; then
  echo "❌ ERROR: JDK 17+ required (found $JAVA_VERSION)."
  exit 1
fi
echo "✅ JDK $JAVA_VERSION"

# kdoctor (only matters on macOS for iOS targets)
if [ "$(uname -s)" = "Darwin" ]; then
  if ! command -v kdoctor >/dev/null 2>&1; then
    echo "⚠️  WARNING: kdoctor not installed. Run: brew install kdoctor"
  else
    echo "✅ kdoctor available"
  fi
fi

# gradlew
if [ ! -x ./gradlew ]; then
  echo "⚠️  WARNING: ./gradlew not executable. Run: chmod +x ./gradlew"
fi

echo "✅ Environment ready."

