import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.ui.window.ComposeUIViewController
import org.company.app.App
import org.company.app.di.initKoin
import platform.UIKit.UIApplication
import platform.UIKit.UIStatusBarStyleDarkContent
import platform.UIKit.UIStatusBarStyleLightContent
import platform.UIKit.UIViewController
import platform.UIKit.setStatusBarStyle

/**
 * Bridge consumed by `iosApp.swift`. Boots Koin lazily on the first call so SwiftUI previews
 * that recreate the controller don't crash on duplicate `startKoin`.
 */
fun MainViewController(): UIViewController {
    initKoin()
    return ComposeUIViewController {
        App(onThemeChanged = { ThemeChanged(it) })
    }
}

@Composable
private fun ThemeChanged(isDark: Boolean) {
    LaunchedEffect(isDark) {
        UIApplication.sharedApplication.setStatusBarStyle(
            if (isDark) UIStatusBarStyleDarkContent else UIStatusBarStyleLightContent,
        )
    }
}