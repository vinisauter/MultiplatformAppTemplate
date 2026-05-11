---
applyTo: "sharedUI/**"
---

# Architectural Rules — KMP + MVVM + Clean Architecture

## Source-set topology (`sharedUI/src/`)

| Source set    | Responsibility                                                                                                                         |
|---------------|----------------------------------------------------------------------------------------------------------------------------------------|
| `commonMain`  | Domain models, use cases, repository **interfaces**, repository **implementations**, ViewModels, Compose UI, Koin module declarations. |
| `androidMain` | `actual` declarations for Android-only APIs, Activity bindings, Android Koin module wiring.                                            |
| `iosMain`     | `actual` declarations for iOS-only APIs, ViewController bindings (exposed to Swift).                                                   |
| `jvmMain`     | `actual` declarations for desktop JVM (Compose for Desktop).                                                                           |
| `webMain`     | `actual` declarations shared by `jsMain` + `wasmJsMain`.                                                                               |

## Clean Architecture layering (inside `commonMain/kotlin/{{PACKAGE_PATH}}/`)

```
{{PACKAGE_PATH}}/
├── domain/        # Pure Kotlin: data classes, sealed interfaces, repository INTERFACES, use cases.
├── data/          # Repository IMPLEMENTATIONS consuming Ktor / Apollo / Room / Multiplatform Settings / KStore.
└── presentation/  # ViewModels (AndroidX) + Compose screens + Nav3 destinations.
```

### Hard dependency rules (enforced by ArchUnit in `:sharedUI`'s commonTest)

- `domain` MUST NOT import anything from `data` or `presentation`.
- `presentation` MUST NOT import from `data`. It depends on `domain` only.
- `data` may depend on `domain` only.
- `runBlocking` is forbidden everywhere except test sources.
- Direct Android (`android.*`) or Apple (`platform.*`) imports are forbidden in `commonMain`.

## MVVM contract

- ViewModels extend `androidx.lifecycle.ViewModel` and launch coroutines exclusively via `viewModelScope`.
- Each ViewModel exposes an immutable `data class XxxUiState` via a `StateFlow<XxxUiState>` and accepts a `sealed interface XxxUiEvent` through a single `handleEvent(event)` entry point.
- Navigation uses **AndroidX Navigation 3** (Compose Multiplatform). ViewModels are scoped to backstack entries.

## Navigation contract

- All destinations live in `commonMain/kotlin/{{PACKAGE_PATH}}/navigation/AppRoute.kt` as `@Serializable` variants of a single `sealed interface AppRoute : NavKey`.
- The graph is declared **once** in `navigation/AppNavHost.kt` using `rememberNavBackStack(...)` + `NavDisplay(...)` + `entryProvider { entry<AppRoute.X> { key -> XScreen(...) } }`.
- Screens receive navigation lambdas (`onNavigateToY`, `onBack`) as **parameters**; they MUST NOT import the backstack directly.
- ViewModels with route arguments are registered with `viewModel { (arg: T) -> XxxViewModel(arg, get()) }` and resolved at the call site via `koinViewModel { parametersOf(key.arg) }` so each backstack entry owns a fresh instance.
- Back navigation: `onBack = { count -> repeat(count) { backStack.removeLastOrNull() } }` on `NavDisplay`.

