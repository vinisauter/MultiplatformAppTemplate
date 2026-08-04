package org.company.app.feature.hello.domain

import kotlinx.coroutines.flow.Flow
import org.company.app.feature.hello.domain.model.HelloMessage

/**
 * Use case (interactor). Pure orchestration over the domain repository.
 * Operator invocation lets callers write `getHelloMessage()`.
 */
class GetHelloMessageUseCase(
    private val repository: HelloRepository,
) {
    operator fun invoke(): Flow<HelloMessage> = repository.observeMessage()
}

