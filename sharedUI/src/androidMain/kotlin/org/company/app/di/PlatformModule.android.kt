package org.company.app.di

import org.koin.dsl.module

/**
 * Android-specific bindings. Wire OkHttp Ktor engine, Room driver, file-based KStore directory,
 * and any Android-only singletons (Context-bound, WorkManager, etc.) here.
 */
actual val platformModule = module {
    // single<HttpClientEngine> { OkHttp.create() }
    // single<RoomDatabase.Builder<AppDatabase>> { getRoomBuilder(androidContext()) }
}

