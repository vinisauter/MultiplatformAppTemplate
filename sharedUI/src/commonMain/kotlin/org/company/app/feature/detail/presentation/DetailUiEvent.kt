package org.company.app.feature.detail.presentation

sealed interface DetailUiEvent {
    data object Reload : DetailUiEvent
}

