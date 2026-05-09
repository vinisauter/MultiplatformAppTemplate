package org.company.app.feature.hello.presentation

/**
 * Immutable UI state for the Hello feature. Hoisted into [HelloViewModel] and exposed via
 * `StateFlow<HelloUiState>` so every platform observes the same source of truth.
 */
data class HelloUiState(
    val message: String = "",
    val isLoading: Boolean = false,
    val error: String? = null,
)

