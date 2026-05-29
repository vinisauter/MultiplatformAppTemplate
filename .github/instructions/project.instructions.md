---
applyTo: "**"
---

# Approved Tech Stack — {{PROJECT_NAME}} (STRICT ALLOW-LIST)

You **MUST** use only the libraries below. They are already declared in `gradle/libs.versions.toml`. Never introduce a new dependency without updating the version catalog through the `explorer.md` persona workflow.

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

## Forbidden patterns

- ❌ Reflection-based mocking libraries (Mockito, MockK with reflective mode) — they break on Kotlin/Native (iOS).
- ❌ `kotlinx-coroutines-android` outside `androidMain`.
- ❌ Direct `java.net.HttpURLConnection`, `URLSession`, or `fetch` — always go through Ktor.
- ❌ Adding a `:shared` or `:composeApp` module — this template is **multi-module** and `commonMain` lives inside `:sharedUI`.
- ❌ Files or objects named `Utils`, `Util`, `Helpers`, `Helper`, `Common`, or any catch-all synonym — see the **Utility module antipattern** rule in `global.instructions.md` and `architecture.instructions.md`.

## Koin module convention

- Declare `commonModule`, `dataModule`, `presentationModule` in `commonMain`.
- Declare `platformModule` as `expect val`, `actual val` in each platform source set.
- Initialize via `startKoin { modules(commonModule, dataModule, presentationModule, platformModule) }` in every platform entry point (`AppActivity`, `iosApp.swift`, `main.kt` desktop, `main.kt` web).

