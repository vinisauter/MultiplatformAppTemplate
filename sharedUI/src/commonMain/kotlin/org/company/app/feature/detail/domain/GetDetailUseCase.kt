package org.company.app.feature.detail.domain

class GetDetailUseCase(
    private val repository: DetailRepository,
) {
    suspend operator fun invoke(id: String): DetailItem = repository.loadById(id)
}

