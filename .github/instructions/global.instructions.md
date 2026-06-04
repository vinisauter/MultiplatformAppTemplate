---
applyTo: "**/*.kt"
---

# Global KMP Development Guidelines

## Scope and intent

- These rules apply to all Kotlin sources matched by `applyTo` and are complementary to architectural layering rules.
- If guidance conflicts, follow `.github/instructions/architecture.instructions.md` first.

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

## Error handling and result contracts

- Model business failures with domain-specific sealed interfaces/classes in `domain`, not with transport-specific exceptions.
- Convert network/database exceptions in `data` into domain-level error contracts before returning to `domain`/`presentation`.
- ViewModels should map domain errors into user-facing `UiState` fields; they must not expose raw exceptions to screens.

## Layer-safe naming conventions

- Use names that reveal layer role: `...UseCase`, `...Repository`, `...RepositoryImpl`, `...UiState`, `...UiEvent`, `...ViewModel`, `...Mappers`.
- Keep one primary declaration per file when practical, especially for use cases and ViewModels, to simplify reviews and architecture checks.

## Testing baseline for behavior changes

- Any business-rule change requires `commonTest` coverage for the affected use case or repository behavior.
- Any state-transition change in a ViewModel requires `commonTest` coverage validating initial state and at least one event-driven transition.

## Utility module antipattern (forbidden)

- ❌ Do **not** create files or Kotlin objects named `Utils`, `Util`, `Helpers`, `Helper`, `Common`, or any equivalent catch-all name.
- Name every file after its **specific domain**: `DateFormatting.kt`, `AuthTokenParser.kt`, `StringExtensions.kt`, etc. The name must tell a reader what belongs there and, equally importantly, what does **not**.
- ❌ Catch-all utility files are forbidden.
- If the right domain name is unclear, pause and define the bounded context first; then create a properly named file.

