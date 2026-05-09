package org.company.app.navigation

import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.navigation3.runtime.entry
import androidx.navigation3.runtime.entryProvider
import androidx.navigation3.runtime.rememberNavBackStack
import androidx.navigation3.ui.NavDisplay
import org.company.app.feature.detail.presentation.DetailScreen
import org.company.app.feature.hello.presentation.HelloScreen

/**
 * Single source of truth for the app's navigation graph. Every screen is wired here through
 * [entryProvider]; ViewModels obtained via `koinViewModel()` inside an `entry<T>` block are
 * automatically scoped to the corresponding backstack entry and disposed when popped.
 *
 * To add a new destination:
 *   1. Declare a `@Serializable` variant in [AppRoute].
 *   2. Add a matching `entry<AppRoute.YourScreen> { key -> YourScreen(...) }` block below.
 *   3. Push it onto the backstack via `backStack.add(AppRoute.YourScreen(...))`.
 */
@Composable
fun AppNavHost(modifier: Modifier = Modifier) {
    val backStack = rememberNavBackStack(AppRoute.Hello)

    NavDisplay(
        backStack = backStack,
        modifier = modifier,
        onBack = { count -> repeat(count) { backStack.removeLastOrNull() } },
        entryProvider = entryProvider {
            entry<AppRoute.Hello> {
                HelloScreen(
                    onNavigateToDetail = { id ->
                        backStack.add(AppRoute.Detail(id = id))
                    },
                )
            }
            entry<AppRoute.Detail> { key ->
                DetailScreen(
                    id = key.id,
                    onBack = { backStack.removeLastOrNull() },
                )
            }
        },
    )
}

