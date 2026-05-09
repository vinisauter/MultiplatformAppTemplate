package org.company.app.feature.hello.domain

class RefreshHelloUseCase(
    private val repository: HelloRepository,
) {
    suspend operator fun invoke() = repository.refresh()
}

