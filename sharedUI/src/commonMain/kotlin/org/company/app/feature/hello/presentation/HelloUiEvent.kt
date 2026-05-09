package org.company.app.feature.hello.presentation

/**
 * Discrete user/system events. Use `sealed interface` (not enum) so each variant can carry data.
 */
sealed interface HelloUiEvent {
    data object Refresh : HelloUiEvent
    data object DismissError : HelloUiEvent
}

