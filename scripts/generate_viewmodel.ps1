# scripts/generate_viewmodel.ps1
# Scaffolds a KMP ViewModel + UiState + UiEvent for a feature.
# Usage: pwsh scripts/generate_viewmodel.ps1 -FeatureName <Name>

param(
    [Parameter(Mandatory = $true)][string]$FeatureName
)

$ErrorActionPreference = 'Stop'

# {{PACKAGE_PATH}} is replaced during template initialization (e.g. com/imobull/app).
$PackagePath = '{{PACKAGE_PATH}}'
$PackageName = '{{PACKAGE_NAME}}'
$FeatureLower = $FeatureName.ToLower()
$TargetDir = "sharedUI/src/commonMain/kotlin/$PackagePath/feature/$FeatureLower/presentation"

New-Item -ItemType Directory -Force -Path $TargetDir | Out-Null

$content = @"
package $PackageName.feature.$FeatureLower.presentation

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import co.touchlab.kermit.Logger
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch

data class ${FeatureName}UiState(
    val isLoading: Boolean = false,
    val error: String? = null,
)

sealed interface ${FeatureName}UiEvent {
    data object Refresh : ${FeatureName}UiEvent
}

class ${FeatureName}ViewModel : ViewModel() {

    private val _uiState = MutableStateFlow(${FeatureName}UiState())
    val uiState: StateFlow<${FeatureName}UiState> = _uiState.asStateFlow()

    init {
        Logger.d { "${FeatureName}ViewModel initialized" }
    }

    fun handleEvent(event: ${FeatureName}UiEvent) {
        when (event) {
            ${FeatureName}UiEvent.Refresh -> viewModelScope.launch {
                _uiState.value = _uiState.value.copy(isLoading = true)
                // TODO: invoke use case via injected dependency
                _uiState.value = _uiState.value.copy(isLoading = false)
            }
        }
    }
}
"@

$file = "$TargetDir/${FeatureName}ViewModel.kt"
Set-Content -Path $file -Value $content -Encoding utf8
Write-Host "Created $file"

