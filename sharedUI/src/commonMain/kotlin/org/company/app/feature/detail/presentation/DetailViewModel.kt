package org.company.app.feature.detail.presentation

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import co.touchlab.kermit.Logger
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import org.company.app.feature.detail.domain.GetDetailUseCase

/**
 * MVVM ViewModel for the Detail screen. The route argument [id] is passed in as a parameter
 * via Koin (`koinViewModel { parametersOf(key.id) }`) so a fresh instance is created per
 * backstack entry and discarded when the entry is popped.
 */
class DetailViewModel(
    private val id: String,
    private val getDetail: GetDetailUseCase,
) : ViewModel() {

    private val _uiState = MutableStateFlow(DetailUiState())
    val uiState: StateFlow<DetailUiState> = _uiState.asStateFlow()

    init {
        Logger.d { "DetailViewModel($id) initialized" }
        load()
    }

    fun handleEvent(event: DetailUiEvent) {
        when (event) {
            DetailUiEvent.Reload -> load()
        }
    }

    private fun load() {
        viewModelScope.launch {
            _uiState.value = _uiState.value.copy(isLoading = true, error = null)
            runCatching { getDetail(id) }
                .onSuccess { item ->
                    _uiState.value = DetailUiState(isLoading = false, item = item)
                }
                .onFailure { throwable ->
                    Logger.e(throwable) { "DetailViewModel load failed for id=$id" }
                    _uiState.value = _uiState.value.copy(
                        isLoading = false,
                        error = throwable.message,
                    )
                }
        }
    }
}

