package org.company.app.feature.hello.data

import co.touchlab.kermit.Logger
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.asStateFlow
import org.company.app.feature.hello.domain.HelloMessage
import org.company.app.feature.hello.domain.HelloRepository

/**
 * In-memory implementation of [HelloRepository]. Replace `refresh()` with a Ktor / Apollo call
 * (e.g. the `HelloQuery.graphql` operation) when wiring real backends. The contract stays in
 * [domain] so the presentation layer never observes this change.
 */
class HelloRepositoryImpl : HelloRepository {

    private val state = MutableStateFlow(HelloMessage(text = "Hello, Multiplatform!"))

    override fun observeMessage() = state.asStateFlow()

    override suspend fun refresh() {
        Logger.d { "HelloRepositoryImpl.refresh()" }
        // TODO: replace with Apollo HelloQuery() execution or Ktor REST call.
        state.value = HelloMessage(text = "Hello, Multiplatform! (refreshed)")
    }
}

