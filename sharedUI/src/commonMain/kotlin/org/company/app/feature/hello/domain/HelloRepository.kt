package org.company.app.feature.hello.domain

import kotlinx.coroutines.flow.Flow

/**
 * Repository contract. Lives in [domain]; implemented in [data].
 * The presentation layer must depend on this interface, never on a concrete implementation.
 */
interface HelloRepository {
    fun observeMessage(): Flow<HelloMessage>
    suspend fun refresh()
}

