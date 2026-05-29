import java.io.ByteArrayOutputStream
import java.util.concurrent.atomic.AtomicBoolean

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

val gitHooksConfigured = AtomicBoolean(false)

fun runCommand(command: List<String>) {
    val process = ProcessBuilder(command)
        .directory(rootDir)
        .inheritIO()
        .start()
    check(process.waitFor() == 0) {
        "Command failed: ${command.joinToString(" ")}"
    }
}

fun getCommandOutput(command: List<String>): Pair<Int, String> {
    val stdout = ByteArrayOutputStream()
    val process = ProcessBuilder(command)
        .directory(rootDir)
        .redirectError(ProcessBuilder.Redirect.DISCARD)
        .start()
    process.inputStream.copyTo(stdout)
    val exitCode = process.waitFor()
    return exitCode to stdout.toString().trim()
}

fun configureGitHooksPath() {
    val gitDir = rootProject.file(".git")
    val hooksDir = rootProject.file(".githooks")
    if (!gitDir.exists()) {
        logger.lifecycle("Skipping git hook setup: .git directory not found.")
        return
    }
    check(hooksDir.exists()) {
        "Missing .githooks directory. Expected committed hooks at ${hooksDir.absolutePath}"
    }

    runCommand(listOf("git", "config", "--local", "core.hooksPath", ".githooks"))
    logger.lifecycle("Git hooks configured: core.hooksPath=.githooks")
}

val installGitHooks = tasks.register("installGitHooks") {
    group = "setup"
    description = "Configures local git to use the shared .githooks directory."
    doLast { configureGitHooksPath() }
}

gradle.taskGraph.whenReady {
    allTasks.forEach { task ->
        if (task.path == installGitHooks.get().path) return@forEach
        task.doFirst {
            if (!gitHooksConfigured.compareAndSet(false, true)) return@doFirst

            val (exitCode, hooksPath) = getCommandOutput(
                listOf("git", "config", "--local", "--get", "core.hooksPath"),
            )
            if (exitCode != 0 || hooksPath != ".githooks") {
                configureGitHooksPath()
            }
        }
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
