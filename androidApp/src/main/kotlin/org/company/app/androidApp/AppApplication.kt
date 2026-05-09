package org.company.app.androidApp

import android.app.Application
import org.company.app.di.initKoin
import org.koin.android.ext.koin.androidContext

/**
 * Application bootstrap. Starts Koin once with the Android context so platform bindings
 * (Room driver, OkHttp engine, KStore directory, etc.) can resolve `androidContext()`.
 */
class AppApplication : Application() {
    override fun onCreate() {
        super.onCreate()
        initKoin {
            androidContext(this@AppApplication)
        }
    }
}