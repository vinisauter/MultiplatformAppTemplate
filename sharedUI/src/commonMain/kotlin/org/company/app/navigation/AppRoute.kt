package org.company.app.navigation

import androidx.navigation3.runtime.NavKey
import kotlinx.serialization.Serializable

/**
 * Type-safe destinations for the app. Each variant is a `@Serializable` `data class` / `data
 * object` so AndroidX Navigation 3 can save & restore the backstack across configuration
 * changes on every platform.
 *
 * Add new screens here. Keep route arguments primitive (or `@Serializable` value classes).
 */
@Serializable
sealed interface AppRoute : NavKey {

    /** Entry destination — Hello feature. */
    @Serializable
    data object Hello : AppRoute

    /** Detail screen, parameterised by id. */
    @Serializable
    data class Detail(val id: String) : AppRoute
}

