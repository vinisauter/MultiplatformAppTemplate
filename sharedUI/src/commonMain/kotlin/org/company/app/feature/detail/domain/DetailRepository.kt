package org.company.app.feature.detail.domain

import org.company.app.feature.detail.domain.model.DetailItem

interface DetailRepository {
    suspend fun loadById(id: String): DetailItem
}

