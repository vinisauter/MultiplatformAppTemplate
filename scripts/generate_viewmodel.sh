#!/usr/bin/env bash
# scripts/generate_viewmodel.sh
# Scaffolds a KMP ViewModel + UiState + UiEvent for a feature.
# Usage: bash scripts/generate_viewmodel.sh <FeatureName>

set -euo pipefail

FEATURE_NAME="${1:-}"
if [ -z "$FEATURE_NAME" ]; then
  echo "Usage: $0 <FeatureName>" >&2
  exit 1
fi

PACKAGE_PATH="{{PACKAGE_PATH}}"
PACKAGE_NAME="{{PACKAGE_NAME}}"
FEATURE_LOWER="$(echo "$FEATURE_NAME" | tr '[:upper:]' '[:lower:]')"
TARGET_DIR="sharedUI/src/commonMain/kotlin/${PACKAGE_PATH}/feature/${FEATURE_LOWER}/presentation"

mkdir -p "$TARGET_DIR"

cat > "$TARGET_DIR/${FEATURE_NAME}ViewModel.kt" <<EOF
package ${PACKAGE_NAME}.feature.${FEATURE_LOWER}.presentation

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import co.touchlab.kermit.Logger
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch

data class ${FEATURE_NAME}UiState(
    val isLoading: Boolean = false,
    val error: String? = null,
)

sealed interface ${FEATURE_NAME}UiEvent {
    data object Refresh : ${FEATURE_NAME}UiEvent
}

class ${FEATURE_NAME}ViewModel : ViewModel() {

    private val _uiState = MutableStateFlow(${FEATURE_NAME}UiState())
    val uiState: StateFlow<${FEATURE_NAME}UiState> = _uiState.asStateFlow()

    init {
        Logger.d { "${FEATURE_NAME}ViewModel initialized" }
    }

    fun handleEvent(event: ${FEATURE_NAME}UiEvent) {
        when (event) {
            ${FEATURE_NAME}UiEvent.Refresh -> viewModelScope.launch {
                _uiState.value = _uiState.value.copy(isLoading = true)
                // TODO: invoke use case via injected dependency
                _uiState.value = _uiState.value.copy(isLoading = false)
            }
        }
    }
}
EOF

echo "Created $TARGET_DIR/${FEATURE_NAME}ViewModel.kt"

