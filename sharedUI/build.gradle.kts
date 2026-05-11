import org.jetbrains.kotlin.gradle.dsl.JvmTarget
import org.gradle.kotlin.dsl.withType
import org.jetbrains.kotlin.gradle.plugin.mpp.KotlinNativeTarget

plugins {
    alias(libs.plugins.kotlin.multiplatform)
    alias(libs.plugins.compose.compiler)
    alias(libs.plugins.compose.multiplatform)
    alias(libs.plugins.android.kmp.library)
    alias(libs.plugins.kotlinx.serialization)
    alias(libs.plugins.ktlint)
    alias(libs.plugins.room)
    alias(libs.plugins.ksp)
    alias(libs.plugins.apollo)
    alias(libs.plugins.buildConfig)
}

kotlin {
    // region android
    androidTarget { //We need the deprecated target to have working previews
        compilerOptions { jvmTarget = JvmTarget.JVM_17 }
    }
    // endregion android
    // region desktop
    jvm {
        compilerOptions { jvmTarget = JvmTarget.JVM_17 }
    }
    // endregion desktop
    // region web
    js { browser() }
    wasmJs { browser() }
    // endregion web
    // region ios
    iosArm64()
    iosSimulatorArm64()
    // endregion ios
    sourceSets {
        commonMain.dependencies {
            api(libs.compose.runtime)
            api(libs.compose.ui)
            api(libs.compose.foundation)
            api(libs.compose.resources)
            api(libs.compose.ui.tooling.preview)
            api(libs.compose.material3)
            implementation(libs.kermit)
            implementation(libs.kotlinx.coroutines.core)
            implementation(libs.ktor.client.core)
            implementation(libs.ktor.client.content.negotiation)
            implementation(libs.ktor.client.serialization)
            implementation(libs.ktor.serialization.json)
            implementation(libs.ktor.client.logging)
            implementation(libs.androidx.lifecycle.viewmodel)
            implementation(libs.androidx.lifecycle.runtime)
            implementation(libs.compose.nav3)
            implementation(libs.kotlinx.serialization.json)
            implementation(libs.koin.core)
            implementation(libs.koin.compose)
            implementation(libs.koin.compose.viewmodel)
            implementation(libs.coil)
            implementation(libs.coil.network.ktor)
            implementation(libs.multiplatformSettings)
            implementation(libs.kotlinx.datetime)
            implementation(libs.room.runtime)
            implementation(libs.apollo.runtime)
            implementation(libs.kstore)
            implementation(libs.materialKolor)
        }

        commonTest.dependencies {
            implementation(kotlin("test"))
            implementation(libs.compose.ui.test)
            implementation(libs.kotlinx.coroutines.test)
        }
        // region android
        androidMain.dependencies {
            implementation(libs.kotlinx.coroutines.android)
            implementation(libs.ktor.client.okhttp)
            implementation(libs.kstore.file)
            implementation(libs.koin.android)
        }
        // endregion android
        // region desktop
        jvmMain.dependencies {
            implementation(compose.desktop.currentOs)
            implementation(libs.kotlinx.coroutines.swing)
            implementation(libs.ktor.client.okhttp)
            implementation(libs.kstore.file)
        }
        // endregion desktop
        // region web
        webMain.dependencies {
            implementation(libs.kstore.storage)
        }
        // endregion web
        // region ios
        iosMain.dependencies {
            implementation(libs.ktor.client.darwin)
            implementation(libs.kstore.file)
        }
        // endregion ios
    }
    // region ios
    targets
        .withType<KotlinNativeTarget>()
        .matching { it.konanTarget.family.isAppleFamily }
        .configureEach {
            binaries {
                framework {
                    baseName = "SharedUI"
                    isStatic = true
                }
            }
        }
    // endregion ios
}

dependencies {
    debugImplementation(libs.compose.ui.tooling)
}
// region android
android {
    namespace = "{{PACKAGE_NAME}}"
    compileSdk = 36
    defaultConfig {
        minSdk = 23
    }
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
}
// endregion android
buildConfig {
    // BuildConfig configuration here.
    // https://github.com/gmazzo/gradle-buildconfig-plugin#usage-in-kts
}

compose.resources {
    // Pin the generated `Res` package so it does NOT depend on rootProject.name.
    // The init script rewrites `org.company.app` -> the user's package, so the import
    // path stays stable as `<your.package>.resources.Res` after initialization.
    publicResClass = false
    packageOfResClass = "org.company.app.resources"
}

room {
    schemaDirectory("$projectDir/schemas")
}

apollo {
    service("api") {
        // GraphQL configuration here.
        // https://www.apollographql.com/docs/kotlin/advanced/plugin-configuration/
        packageName.set("{{PACKAGE_NAME}}.graphql")
    }
}

dependencies {
    with(libs.room.compiler) {
        // region android
        add("kspAndroid", this)
        // endregion android
        // region desktop
        add("kspJvm", this)
        // endregion desktop
        // region ios
        add("kspIosArm64", this)
        add("kspIosSimulatorArm64", this)
        // endregion ios
    }
}
