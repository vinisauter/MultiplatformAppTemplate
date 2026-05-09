package org.company.app.di

import org.koin.dsl.module

/**
 * Web (JS + WasmJS shared) bindings. Ktor JS engine, KStore in-memory storage.
 */
actual val platformModule = module {
    // single<HttpClientEngine> { Js.create() }
}

