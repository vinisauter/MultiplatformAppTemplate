package org.company.app.di

import org.koin.dsl.module

/**
 * Desktop (JVM) bindings. Ktor OkHttp engine, file-system KStore directory, Swing dispatchers.
 */
actual val platformModule = module {
    // single<HttpClientEngine> { OkHttp.create() }
}

