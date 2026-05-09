package org.company.app.feature.detail.presentation

import org.company.app.feature.detail.domain.DetailItem

data class DetailUiState(
    val isLoading: Boolean = true,
    val item: DetailItem? = null,
    val error: String? = null,
)

