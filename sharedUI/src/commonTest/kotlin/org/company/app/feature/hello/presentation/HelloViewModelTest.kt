package org.company.app.feature.hello.presentation

import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.test.StandardTestDispatcher
import kotlinx.coroutines.test.advanceUntilIdle
import kotlinx.coroutines.test.resetMain
import kotlinx.coroutines.test.runTest
import kotlinx.coroutines.test.setMain
import org.company.app.feature.hello.domain.GetHelloMessageUseCase
import org.company.app.feature.hello.domain.HelloRepository
import org.company.app.feature.hello.domain.RefreshHelloUseCase
import org.company.app.feature.hello.domain.model.HelloMessage
import kotlin.test.AfterTest
import kotlin.test.BeforeTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse

/**
 * Hand-rolled fake — no reflective mocking (which breaks on Kotlin/Native).
 */
private class FakeHelloRepository : HelloRepository {
    private val flow = MutableStateFlow(HelloMessage("initial"))
    var refreshCount: Int = 0
    override fun observeMessage() = flow.asStateFlow()
    override suspend fun refresh() {
        refreshCount++
        flow.value = HelloMessage("refreshed-$refreshCount")
    }
}

@OptIn(ExperimentalCoroutinesApi::class)
class HelloViewModelTest {

    private val dispatcher = StandardTestDispatcher()

    @BeforeTest
    fun setUp() {
        Dispatchers.setMain(dispatcher)
    }

    @AfterTest
    fun tearDown() {
        Dispatchers.resetMain()
    }

    @Test
    fun emitsInitialMessageFromRepository() = runTest(dispatcher) {
        val repo = FakeHelloRepository()
        val viewModel = HelloViewModel(
            getHelloMessage = GetHelloMessageUseCase(repo),
            refreshHello = RefreshHelloUseCase(repo),
        )

        val state = viewModel.uiState.first { !it.isLoading }
        assertEquals("initial", state.message)
        assertFalse(state.isLoading)
    }

    @Test
    fun refreshEventInvokesRepositoryAndUpdatesMessage() = runTest(dispatcher) {
        val repo = FakeHelloRepository()
        val viewModel = HelloViewModel(
            getHelloMessage = GetHelloMessageUseCase(repo),
            refreshHello = RefreshHelloUseCase(repo),
        )

        viewModel.handleEvent(HelloUiEvent.Refresh)
        advanceUntilIdle()

        assertEquals(1, repo.refreshCount)
        assertEquals("refreshed-1", viewModel.uiState.value.message)
        assertFalse(viewModel.uiState.value.isLoading)
    }
}

