package org.company.app.di

import org.koin.core.context.startKoin
import org.koin.core.context.GlobalContext
import org.koin.dsl.KoinAppDeclaration

/**
 * Single entry point invoked from every platform's `main` / `Activity.onCreate` / SwiftUI bridge.
 * Idempotent: if Koin is already running, the existing context is preserved.
 */
fun initKoin(appDeclaration: KoinAppDeclaration = {}) {
    if (GlobalContext.getOrNull() != null) return
    startKoin {
        appDeclaration()
        modules(commonModule, dataModule, presentationModule, platformModule)
    }
}

