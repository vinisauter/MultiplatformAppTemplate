package org.company.app.di

import org.koin.core.context.startKoin
import org.koin.dsl.KoinAppDeclaration
import org.koin.mp.KoinPlatformTools

/**
 * Single entry point invoked from every platform's `main` / `Activity.onCreate` / SwiftUI bridge.
 * Idempotent: if Koin is already running, the existing context is preserved.
 */
fun initKoin(appDeclaration: KoinAppDeclaration = {}) {
    val allModules = listOf(commonModule, dataModule, presentationModule, platformModule)
    KoinPlatformTools.defaultContext().getOrNull()?.apply {
        loadModules(
            allModules,
        )
    } ?: startKoin {
        appDeclaration()
        modules(allModules)
    }
}
