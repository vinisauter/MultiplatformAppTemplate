package org.company.app.di

import org.koin.core.module.Module

/**
 * Platform-specific bindings. Each target source set must provide an `actual val` that
 * supplies the right Ktor engine, Room driver, KStore directory, etc.
 */
expect val platformModule: Module

