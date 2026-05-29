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

## Utility module antipattern (forbidden)

- ❌ Do **not** create files or Kotlin objects named `Utils`, `Util`, `Helpers`, `Helper`, `Common`, or any equivalent catch-all name.
- Name every file after its **specific domain**: `DateFormatting.kt`, `AuthTokenParser.kt`, `StringExtensions.kt`, etc. The name must tell a reader what belongs there and, equally importantly, what does **not**.
- When the right name is unclear (e.g., early-stage feature exploration), use a file explicitly named `UnstableTemporaryUtils.kt` as a **temporary** holding area. Its unwieldy name is intentional — it signals instability and applies pressure to refactor.
- Before adding a new declaration to `UnstableTemporaryUtils.kt`, ask: can I find a proper domain name right now? If yes, create the correctly-named file instead.
- CI must reject any `UnstableTemporaryUtils.kt` file that exceeds **5 top-level declarations**.

