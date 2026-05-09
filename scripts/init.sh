#!/usr/bin/env bash
# scripts/init.sh
# Local alternative to the `Initialize KMP Project Template` GitHub Actions workflow.
# Rewrites placeholders, prunes unselected platforms, writes .template.config,
# self-destructs init.yml, then runs scripts/team.install.sh.
#
# Usage (interactive):   bash scripts/init.sh
# Usage (non-interactive):
#   bash scripts/init.sh \
#     --project-name "Multiplatform Template App" \
#     --package-name "com.template.app" \
#     --android true --ios true --web true --desktop true

set -euo pipefail

# -----------------------------------------------------------------------------
# Argument parsing
# -----------------------------------------------------------------------------
PROJECT_NAME=""
PACKAGE_NAME=""
INC_AND="true"
INC_IOS="true"
INC_WEB="false"
INC_DSK="false"
SKIP_INSTALL="false"

while [ $# -gt 0 ]; do
  case "$1" in
    --project-name) PROJECT_NAME="$2"; shift 2 ;;
    --package-name) PACKAGE_NAME="$2"; shift 2 ;;
    --android)      INC_AND="$2"; shift 2 ;;
    --ios)          INC_IOS="$2"; shift 2 ;;
    --web)          INC_WEB="$2"; shift 2 ;;
    --desktop)      INC_DSK="$2"; shift 2 ;;
    --skip-install) SKIP_INSTALL="true"; shift ;;
    -h|--help)
      grep -E '^# ' "$0" | sed 's/^# \{0,1\}//'
      exit 0
      ;;
    *) echo "Unknown argument: $1" >&2; exit 1 ;;
  esac
done

prompt_if_empty() {
  local var="$1" message="$2" current
  current="$(eval "echo \"\$$var\"")"
  if [ -z "$current" ]; then
    read -r -p "$message: " value
    eval "$var=\"\$value\""
  fi
}

prompt_yesno_if_empty() {
  local var="$1" message="$2" current
  current="$(eval "echo \"\$$var\"")"
  if [ "$current" != "true" ] && [ "$current" != "false" ]; then
    read -r -p "$message [Y/n]: " ans
    case "$ans" in
      n|N|no|NO|false) eval "$var=false" ;;
      *) eval "$var=true" ;;
    esac
  fi
}

prompt_if_empty PROJECT_NAME "Project name (e.g. MyApp)"
prompt_if_empty PACKAGE_NAME "Package name (e.g. com.myapp)"
prompt_yesno_if_empty INC_AND "Include Android target?"
prompt_yesno_if_empty INC_IOS "Include iOS target?"
prompt_yesno_if_empty INC_WEB "Include Web target?"
prompt_yesno_if_empty INC_DSK "Include Desktop target?"

# -----------------------------------------------------------------------------
# Validation
# -----------------------------------------------------------------------------
if ! printf '%s' "$PROJECT_NAME" | grep -Eq '^[A-Za-z][A-Za-z0-9_-]*$'; then
  echo "❌ project_name must start with a letter and contain only [A-Za-z0-9_-]." >&2
  exit 1
fi
if ! printf '%s' "$PACKAGE_NAME" | grep -Eq '^[a-z][a-z0-9_]*(\.[a-z][a-z0-9_]*)+$'; then
  echo "❌ package_name must be a valid dotted lowercase Kotlin package (e.g. com.myapp)." >&2
  exit 1
fi
if [ "$INC_AND" != "true" ] && [ "$INC_IOS" != "true" ] && [ "$INC_WEB" != "true" ] && [ "$INC_DSK" != "true" ]; then
  echo "❌ At least one platform must be enabled." >&2
  exit 1
fi

REPO_ROOT="$(git rev-parse --show-toplevel)"
cd "$REPO_ROOT"

PACKAGE_PATH="${PACKAGE_NAME//./\/}"

echo ""
echo "🚀 Initializing template:"
echo "   project_name = $PROJECT_NAME"
echo "   package_name = $PACKAGE_NAME"
echo "   package_path = $PACKAGE_PATH"
echo "   android=$INC_AND  ios=$INC_IOS  web=$INC_WEB  desktop=$INC_DSK"
echo ""

# -----------------------------------------------------------------------------
# 1. Rewrite placeholders across all text files.
# -----------------------------------------------------------------------------
echo "🔁 Rewriting {{PROJECT_NAME}} / {{PACKAGE_NAME}} / {{PACKAGE_PATH}} placeholders..."
step1_success=true
mapfile -t FILES < <(grep -rIl --exclude-dir=.git --exclude-dir=build --exclude-dir=.gradle \
  -e '{{PROJECT_NAME}}' -e '{{PACKAGE_NAME}}' -e '{{PACKAGE_PATH}}' . || true)
for f in "${FILES[@]}"; do
  if sed -i.bak \
    -e "s|{{PROJECT_NAME}}|${PROJECT_NAME}|g" \
    -e "s|{{PACKAGE_NAME}}|${PACKAGE_NAME}|g" \
    -e "s|{{PACKAGE_PATH}}|${PACKAGE_PATH}|g" \
    "$f"; then
    rm -f "$f.bak"
  else
    echo "[STEP 1] Failed to rewrite $f" >&2
    step1_success=false
  fi
  rm -f "$f.bak"
done
if [ "$step1_success" = true ]; then echo "STEP 1: Success"; else echo "STEP 1: Failed" >&2; fi

# -----------------------------------------------------------------------------
# 2. Rewrite Kotlin package declarations and rename source directories.
# -----------------------------------------------------------------------------
echo "📦 Renaming Kotlin package directories org.company.app -> $PACKAGE_NAME ..."
step2_success=true
find . -type f -name '*.kt' -not -path './build/*' -not -path './.gradle/*' \
  -exec sed -i.bak "s|org\\.company\\.app|${PACKAGE_NAME}|g" {} + || step2_success=false
find . -type f -name '*.kt.bak' -delete

for module in sharedUI androidApp desktopApp webApp iosApp; do
  for src_root in "$module"/src/*/kotlin; do
    [ -d "$src_root/org/company/app" ] || continue
    mkdir -p "$src_root/$PACKAGE_PATH"
    shopt -s dotglob nullglob
    if ! mv "$src_root/org/company/app/"* "$src_root/$PACKAGE_PATH/" 2>/dev/null; then
      step2_success=false
      echo "[STEP 2b] Failed to move/rename in $src_root" >&2
    fi
    shopt -u dotglob nullglob
    rm -rf "$src_root/org"
  done

  # Check if all moves were successful
  if [ "$step2_success" = true ]; then echo "STEP 2: Success"; else echo "STEP 2: Failed" >&2; fi

done

# -----------------------------------------------------------------------------
# 3. Prune unselected platforms via // region <plat> markers + module dirs.
# -----------------------------------------------------------------------------
echo "✂️  Pruning unselected platforms..."
step3_success=true
delete_region() {
  local plat="$1"
  local files=()
  while IFS= read -r -d '' f; do files+=("$f"); done < <(
    find . -type f \( -name 'build.gradle.kts' -o -name 'settings.gradle.kts' \) \
      -not -path './build/*' -not -path './.gradle/*' -not -path './.git/*' -print0
  )
  for f in "${files[@]}"; do
    if sed -i.bak "/^[[:space:]]*\/\/ region ${plat}\([^[:alnum:]_]\|$\)/,/^[[:space:]]*\/\/ endregion ${plat}\([^[:alnum:]_]\|$\)/d" "$f"; then
      rm -f "$f.bak"
    else
      echo "[STEP 3] Failed to prune region $plat in $f" >&2
      step3_success=false
    fi
  done
}

drop_module() {
  local module="$1"
  if ! rm -rf "$module"; then
    echo "[STEP 3] Failed to remove module dir $module" >&2
    step3_success=false
  fi
  if ! sed -i.bak "/include(\":${module}\")/d" settings.gradle.kts; then
    echo "[STEP 3] Failed to remove module include for $module" >&2
    step3_success=false
  fi
  rm -f settings.gradle.kts.bak
}

[ "$INC_AND" = "true" ] || { echo "✂️  Removing Android target..."; delete_region android; drop_module androidApp; }
[ "$INC_IOS" = "true" ] || { echo "✂️  Removing iOS target...";     delete_region ios;     drop_module iosApp; }
[ "$INC_WEB" = "true" ] || { echo "✂️  Removing Web target...";     delete_region web;     drop_module webApp; }
[ "$INC_DSK" = "true" ] || { echo "✂️  Removing Desktop target..."; delete_region desktop; drop_module desktopApp; }
if [ "$step3_success" = true ]; then echo "STEP 3: Success"; else echo "STEP 3: Failed" >&2; fi

# -----------------------------------------------------------------------------
# 4. Write .template.config consumed by .github/workflows/kmp-ci.yml.
# -----------------------------------------------------------------------------
echo "📝 Writing .template.config..."
step4_success=true
{
  echo "# Generated by scripts/init.sh - do not edit by hand."
  echo "PROJECT_NAME=${PROJECT_NAME}"
  echo "PACKAGE_NAME=${PACKAGE_NAME}"
  echo "INCLUDE_ANDROID=${INC_AND}"
  echo "INCLUDE_IOS=${INC_IOS}"
  echo "INCLUDE_WEB=${INC_WEB}"
  echo "INCLUDE_DESKTOP=${INC_DSK}"
} > .template.config || step4_success=false
if [ "$step4_success" = true ]; then echo "STEP 4: Success"; else echo "STEP 4: Failed" >&2; fi

# -----------------------------------------------------------------------------
# 5. Self-destruct: remove init workflow + this script.
# -----------------------------------------------------------------------------
echo "🧨 Removing init workflow + scripts/init.* ..."
step5_success=true
if ! rm -f .github/workflows/init.yml; then
  echo "[STEP 5] Failed to remove .github/workflows/init.yml" >&2
  step5_success=false
fi
if ! rm -f scripts/init.ps1; then
  echo "[STEP 5] Failed to remove scripts/init.ps1" >&2
  step5_success=false
fi
SCRIPT_PATH="$0"
if [ "$step5_success" = true ]; then echo "STEP 5: Success"; else echo "STEP 5: Failed" >&2; fi

# -----------------------------------------------------------------------------
# 6. Run team.install (hooks + environment validation).
# -----------------------------------------------------------------------------
echo "▶️  Running scripts/team.install.sh..."
step6_success=true
if [ "$SKIP_INSTALL" = "true" ]; then
  echo "⏭  Skipping team.install (--skip-install)."
else
  if ! bash scripts/team.install.sh; then
    echo "[STEP 6] Failed to run scripts/team.install.sh" >&2
    step6_success=false
  fi
fi
if [ "$step6_success" = true ]; then echo "STEP 6: Success"; else echo "STEP 6: Failed" >&2; fi

# Remove this script last, so it remains valid throughout execution.
if ! rm -f "$SCRIPT_PATH"; then
  echo "[FINAL] Failed to remove this script ($SCRIPT_PATH)" >&2
else
  echo "Self-destruct: Success"
fi

echo ""
echo "🎉 Template initialized as $PROJECT_NAME ($PACKAGE_NAME). Review the changes and commit."

