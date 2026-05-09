package org.company.app.feature.detail.data

import org.company.app.feature.detail.domain.DetailItem
import org.company.app.feature.detail.domain.DetailRepository

/**
 * Stub implementation. Replace with Apollo / Ktor / Room access — the contract in [domain]
 * stays untouched, so the presentation layer is unaffected.
 */
class DetailRepositoryImpl : DetailRepository {
    override suspend fun loadById(id: String): DetailItem = DetailItem(
        id = id,
        title = "Item #$id",
        body = "Detail body for $id. Replace with data fetched from a real source.",
    )
}

