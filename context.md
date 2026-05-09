# context.md — Deep Technical Context

## Why AndroidX ViewModel + Navigation 3 in KMP

Since 2024–2025, Google and JetBrains have officially shipped Kotlin Multiplatform builds of `androidx.lifecycle:lifecycle-viewmodel`, `lifecycle-runtime`, and `androidx.navigation3:navigation3-ui`. This collapses three previous ecosystems (MVIKotlin, Decompose, voyager) into a first-party stack.

### State retention guarantees

- **Android**: backed by the platform `ViewModelStore`, surviving configuration changes.
- **iOS**: bound to the Compose-Multiplatform-managed `ViewModelStoreOwner`, surviving SwiftUI re-renders that recreate the host `UIViewController`.
- **Desktop / Web**: the Compose Multiplatform integration owns a `ViewModelStore` per `NavBackStackEntry`, so navigating away and back preserves state without manual save/restore boilerplate.

This means in-flight Apollo queries, Coil image downloads, and Ktor calls launched from `viewModelScope` are **not** restarted on rotation, dark-mode toggle, or window resize.

### Navigation 3 backstack scoping

Each `NavKey` destination owns its `ViewModelStore`. When the entry is popped, the store is cleared, `viewModelScope` is cancelled, and Coil image requests targeting the destination's lifecycle are torn down automatically. Memory leaks from leaked coroutines are no longer a class of bug in this stack.

## Why we forbid reflective mocking

Kotlin/Native (iOS targets) does not support Java reflection. Mockito, MockK in `mock<T>()` mode, and PowerMock all fail to link. Tests must compile to native binaries on Apple Silicon CI runners, so we use:

- Hand-rolled fakes implementing the production interface.
- Koin test modules that swap real bindings for fakes.
- Ktor `MockEngine` for HTTP.
- Apollo `TestNetworkTransport` for GraphQL.

## Why iOS CI is gated

GitHub Actions Free tier: **2,000 minutes/month** for private repos, with a **10× multiplier** on `macos-latest`. A 6-minute Kotlin/Native compile burns 60 budget minutes. Our [`kmp-ci.yml`](.github/workflows/kmp-ci.yml) accordingly:

1. Runs ktlint + JVM tests + `compileCommonMainKotlinMetadata` on every PR using a Linux runner (1× cost).
2. Runs `compileKotlinIosX64` and `compileKotlinIosSimulatorArm64` **only on push to `main`** or **manual `workflow_dispatch`**.
3. Caches `~/.konan` aggressively.
4. Reads `.template.config` to skip the iOS job entirely if the project was initialized with iOS disabled.

## Why region markers in `sharedUI/build.gradle.kts`

The init workflow prunes platforms by deleting all lines between matching `// region <plat>` / `// endregion <plat>` markers. This keeps the source-of-truth template legible while allowing deterministic, idempotent removal.

## Why a committed `.template.config` file

CI reads platform flags from `.template.config` instead of `vars.INCLUDE_*` repository variables. This avoids requiring the init workflow to hold a `repo` token scope and keeps the configuration auditable in git history.

