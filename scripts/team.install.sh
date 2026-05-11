#!/usr/bin/env bash
# scripts/team.install.sh
# Onboarding script: wires Copilot rules + Git hooks for a freshly cloned repo.

set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel)"
cd "$REPO_ROOT"

echo "📦 Installing ADK ecosystem for Android Studio + GitHub Copilot..."

# 1. Verify Copilot instructions are present (they ship in .github/ already)
for f in \
    .github/copilot-instructions.md \
    .github/instructions/architecture.instructions.md \
    .github/instructions/global.instructions.md \
    .github/instructions/project.instructions.md ; do
  if [ ! -f "$f" ]; then
    echo "❌ Missing $f — repository is in an inconsistent state."
    exit 1
  fi
done
echo "✅ Copilot instructions in place."

# 2. Install Git hooks (shift-left CI protection)
mkdir -p .git/hooks
cp scripts/hooks/PreToolUse.sh  .git/hooks/pre-commit
cp scripts/hooks/PostToolUse.sh .git/hooks/pre-push
chmod +x .git/hooks/pre-commit .git/hooks/pre-push
echo "✅ Git hooks installed (pre-commit, pre-push)."

# 3. Validate environment
bash scripts/hooks/SessionStart.sh

echo ""
echo "🎉 Done. Android Studio is now Copilot-aware and GitHub Actions Free minutes are guarded."

# 4. Self-destruct & clean up
rm -- "$0"
rm -- scripts/team.install.sh
echo "🧹 Onboarding script removed. Happy coding!"

