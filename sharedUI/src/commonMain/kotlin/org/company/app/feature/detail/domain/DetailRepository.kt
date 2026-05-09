package org.company.app.feature.detail.domain

interface DetailRepository {
    suspend fun loadById(id: String): DetailItem
}

