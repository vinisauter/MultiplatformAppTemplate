package org.company.app.di

import org.koin.dsl.module

/**
 * iOS-specific bindings. Wire Darwin Ktor engine, NativeSQLiteDriver, NSDocumentDirectory paths
 * for KStore, and anything exposed via `platform.*` APIs here.
 */
actual val platformModule = module {
    // single<HttpClientEngine> { Darwin.create() }
}

