package org.company.app.feature.hello.presentation

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import co.touchlab.kermit.Logger
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch
import org.company.app.feature.hello.domain.GetHelloMessageUseCase
import org.company.app.feature.hello.domain.RefreshHelloUseCase

/**
 * MVVM ViewModel for the Hello feature. Owns coroutine scope via [viewModelScope] and exposes
 * [uiState] for any platform UI (Compose Android/iOS/Desktop/Web).
 *
 * Dependencies are injected through Koin's `presentationModule`.
 */
class HelloViewModel(
    private val getHelloMessage: GetHelloMessageUseCase,
    private val refreshHello: RefreshHelloUseCase,
) : ViewModel() {

    private val internalState = MutableStateFlow(HelloUiState(isLoading = true))

    val uiState: StateFlow<HelloUiState> = combine(
        internalState,
        getHelloMessage(),
    ) { internal, message ->
        internal.copy(message = message.text, isLoading = false)
    }.stateIn(
        scope = viewModelScope,
        started = SharingStarted.WhileSubscribed(STOP_TIMEOUT_MILLIS),
        initialValue = HelloUiState(isLoading = true),
    )

    init {
        Logger.d { "HelloViewModel initialized" }
    }

    fun handleEvent(event: HelloUiEvent) {
        when (event) {
            HelloUiEvent.Refresh -> viewModelScope.launch {
                internalState.value = internalState.value.copy(isLoading = true, error = null)
                runCatching { refreshHello() }
                    .onFailure { throwable ->
                        Logger.e(throwable) { "HelloViewModel refresh failed" }
                        internalState.value = internalState.value.copy(
                            isLoading = false,
                            error = throwable.message,
                        )
                    }
                    .onSuccess {
                        internalState.value = internalState.value.copy(isLoading = false)
                    }
            }

            HelloUiEvent.DismissError -> {
                internalState.value = internalState.value.copy(error = null)
            }
        }
    }

    private companion object {
        const val STOP_TIMEOUT_MILLIS = 5_000L
    }
}

