---
applyTo: "**/*.kt"
---

# Global KMP Development Guidelines

## Concurrency

- Use **Kotlinx Coroutines** exclusively. No threads, no `Thread.sleep`, no `runBlocking` outside tests.
- ViewModels launch coroutines only through `viewModelScope`.
- Long-running cold flows must use `stateIn(scope, SharingStarted.WhileSubscribed(5_000), initial)`.

## Date and time

- Use **`kotlinx-datetime`** for every temporal manipulation in `commonMain`. Never use `java.time.*` or `kotlin.time.*` for wall-clock work.

## Logging

- Use **Kermit** (`co.touchlab.kermit.Logger`) on every platform. Lazy lambdas only:
  ```kotlin
  Logger.d { "User $id loaded" }
  ```
- `println`, `Log.d`, `NSLog`, and `console.log` are forbidden.

## Constants and secrets

- Use the **BuildConfig plugin** (`com.github.gmazzo.buildconfig`) to inject API keys, base URLs, and environment flags at compile time. Never hard-code secrets in Kotlin sources.

## Code style

- Ktlint (`./gradlew ktlintFormat`) is the formatter of record. The pre-commit hook runs it automatically.
- Prefer `data class` + `sealed interface` over enums for state modeling.
- Composable functions are PascalCase and stateless when possible (state hoisted to the ViewModel).

