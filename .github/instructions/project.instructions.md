---
applyTo: "**"
---

# Approved Tech Stack — {{PROJECT_NAME}} (STRICT ALLOW-LIST)

You **MUST** use only the libraries below. They are already declared in `gradle/libs.versions.toml`. Never introduce a new dependency without updating the version catalog through the `explorer.md` persona workflow.

## Layer usage constraints (required)

- `domain`: Kotlin stdlib + coroutines primitives only; no networking, persistence, DI, Compose, or platform-specific APIs.
- `data`: may use Ktor, Apollo, Room, Settings, KStore, kotlinx-serialization, kotlinx-datetime, Kermit.
- `presentation`: may use Compose Multiplatform, Navigation 3, Lifecycle ViewModel/runtime, Coil, MaterialKolor, Kermit.
- `di`: may use Koin to bind `domain` contracts to `data` implementations and expose `presentation` ViewModels.
- Platform source sets (`androidMain`/`iosMain`/`jvmMain`/`webMain`): only platform adapters, `actual` implementations, and app entry wiring.

| Concern               | Library                                      | Catalog alias                                                                                           |
|-----------------------|----------------------------------------------|---------------------------------------------------------------------------------------------------------|
| Dependency Injection  | Koin                                         | `koin-core`, `koin-compose`                                                                             |
| HTTP REST client      | Ktor Client                                  | `ktor-client-core` + content negotiation + json + logging                                               |
| HTTP platform engines | Ktor (OkHttp / Darwin / JS / Curl / WinHTTP) | `ktor-client-okhttp`, `ktor-client-darwin`, `ktor-client-js`, `ktor-client-curl`, `ktor-client-winhttp` |
| GraphQL               | Apollo Kotlin                                | `apollo-runtime` (plugin `apollo`)                                                                      |
| Serialization         | Kotlinx Serialization (JSON)                 | `kotlinx-serialization-json`                                                                            |
| State / lifecycle     | AndroidX Lifecycle KMP                       | `androidx-lifecycle-viewmodel`, `androidx-lifecycle-runtime`                                            |
| Navigation            | AndroidX Navigation 3 KMP                    | `compose-nav3`                                                                                          |
| Persistent SQL        | Room KMP                                     | `room-runtime`, `room-compiler` (KSP)                                                                   |
| Key-value             | Multiplatform Settings                       | `multiplatformSettings`                                                                                 |
| Object persistence    | KStore                                       | `kstore`, `kstore-file`, `kstore-storage`                                                               |
| Image loading         | Coil 3 (Compose Multiplatform)               | `coil`, `coil-network-ktor`                                                                             |
| Material You colors   | MaterialKolor                                | `materialKolor`                                                                                         |
| Logging               | Kermit                                       | `kermit`                                                                                                |
| Date/Time             | kotlinx-datetime                             | `kotlinx-datetime`                                                                                      |
| BuildConfig           | `com.github.gmazzo.buildconfig` plugin       | `buildConfig`                                                                                           |
| Resources             | Compose Multiplatform Resources              | `compose-resources` (built-in with `compose.multiplatform` plugin)                                      |
| Math Expression       | Keval                                        | `keval`                                                                                                 |

## Forbidden patterns

- ❌ Reflection-based mocking libraries (Mockito, MockK with reflective mode) — they break on Kotlin/Native (iOS).
- ❌ `kotlinx-coroutines-android` outside `androidMain`.
- ❌ Direct `java.net.HttpURLConnection`, `URLSession`, or `fetch` — always go through Ktor.
- ❌ Adding a `:shared` or `:composeApp` module — this template is **multi-module** and `commonMain` lives inside `:sharedUI`.
- ❌ Files or objects named `Utils`, `Util`, `Helpers`, `Helper`, `Common`, or any catch-all synonym — see the **Utility module antipattern** rule in `global.instructions.md` and `architecture.instructions.md`.
- ❌ `moko-resources` or any third-party resource library — use **Compose Multiplatform Resources** (`compose.resources`) which is already configured.
- ❌ Adding any architecture framework that overlaps with existing MVVM/Clean Architecture responsibilities (for example Redux/MVI frameworks) without explicit architecture decision and version-catalog update.

## String resources convention

- All user-facing strings **MUST** be defined in `sharedUI/src/commonMain/composeResources/values/strings.xml` (English default).
- Localized translations go in qualifier directories: `values-pt-rBR/strings.xml` (Portuguese Brazil), `values-es/strings.xml` (Spanish), etc.
- In Composable functions, use `stringResource(Res.string.key_name)` instead of hardcoded text.
- String keys follow the pattern `<screen>_<description>` (e.g., `dashboard_title`, `builder_save`, `strategies_test_btn`).
- Parameterized strings use Android-style `%1$s`, `%1$d` format placeholders.
- Currently supported locales: **en** (default), **pt-rBR** (Portuguese — Brazil).

## Koin module convention

- Declare `commonModule`, `dataModule`, `presentationModule` in `commonMain`.
- Declare `platformModule` as `expect val`, `actual val` in each platform source set.
- Initialize via `startKoin { modules(commonModule, dataModule, presentationModule, platformModule) }` in every platform entry point (`AppActivity`, `iosApp.swift`, `main.kt` desktop, `main.kt` web).

