import org.gradle.api.tasks.Exec

plugins {
    alias(libs.plugins.kotlin.multiplatform).apply(false)
    alias(libs.plugins.compose.compiler).apply(false)
    alias(libs.plugins.compose.multiplatform).apply(false)
    alias(libs.plugins.kotlin.android).apply(false)
    alias(libs.plugins.android.application).apply(false)
    alias(libs.plugins.android.kmp.library).apply(false)
    alias(libs.plugins.kotlin.jvm).apply(false)
    alias(libs.plugins.kotlinx.serialization).apply(false)
    alias(libs.plugins.ksp).apply(false)
    alias(libs.plugins.apollo).apply(false)
    alias(libs.plugins.buildConfig).apply(false)
    alias(libs.plugins.ktlint).apply(false)
}

tasks.register<Exec>("installGitHooks") {
    group = "setup"
    description = "Configures local git to use the shared .githooks directory."
    workingDir = rootDir
    commandLine = if (System.getProperty("os.name").lowercase().contains("windows")) {
        listOf("cmd", "/c", "git config --local core.hooksPath .githooks && echo Git hooks configured: core.hooksPath=.githooks")
    } else {
        listOf("bash", "-c", "git config --local core.hooksPath .githooks && echo Git hooks configured: core.hooksPath=.githooks")
    }
}

subprojects {
    apply(plugin = rootProject.libs.plugins.ktlint.get().pluginId)

    configure<org.jlleitschuh.gradle.ktlint.KtlintExtension> {
        android.set(false)
        ignoreFailures.set(false)
        verbose.set(true)
        outputToConsole.set(true)
        enableExperimentalRules.set(false)
        reporters {
            reporter(org.jlleitschuh.gradle.ktlint.reporter.ReporterType.PLAIN)
            reporter(org.jlleitschuh.gradle.ktlint.reporter.ReporterType.HTML)
            reporter(org.jlleitschuh.gradle.ktlint.reporter.ReporterType.SARIF)
        }
    }
}
