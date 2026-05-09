package org.company.app

import androidx.compose.runtime.Composable
import androidx.compose.ui.tooling.preview.Preview
import org.company.app.feature.hello.presentation.HelloScreen
import org.company.app.theme.AppTheme

/**
 * Root composable. Assumes [org.company.app.di.initKoin] has already been called by the
 * hosting platform entry point (`AppApplication` on Android, `MainViewController` on iOS,
 * `main.kt` on Desktop/Web). For `@Preview` usage, wrap this call in
 * `KoinApplication { modules(commonModule, dataModule, presentationModule) }`.
 */
@Preview
@Composable
fun App(
    onThemeChanged: @Composable (isDark: Boolean) -> Unit = {},
) = AppTheme(onThemeChanged) {
    HelloScreen()
}
