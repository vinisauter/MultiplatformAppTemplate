---
applyTo: "sharedUI/**"
---

# Architectural Rules — KMP + MVVM + Clean Architecture

## Rule precedence and conflict resolution

- If two instructions conflict, resolve in this order: `architecture.instructions.md` -> `global.instructions.md` -> `project.instructions.md`.
- When uncertain where code belongs, prefer stricter placement: `domain` before `data`, `domain` before `presentation`, and `commonMain` before platform source sets.
- Every pull request that adds or changes behavior must explain, in its description, which layer owns the behavior and why.

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
├── feature/
│   ├── <featureName>/
│   │   ├── domain/          # definiction of the repository interface and use cases
│   │   │   └── model/       # Pure Kotlin domain entities/value objects.
│   │   ├── data/            # Repository IMPLEMENTATIONS.
│   │   │   ├── remote/      # API clients.
│   │   │   └── local/       # Local data sources.
│   │   └── presentation/    # ViewModels (AndroidX) + Compose screens + UiState/UiEvent.
│   └── common/              # Shared domain/data logic consumed by multiple features.
│   │   ├── domain/          # definiction of the repository interface and use cases
│   │   │   └── model/       # Shared domain models reused by 2+ features.
│   │   └── data/            # Repository shared IMPLEMENTATIONS, API clients, local sources.
├── navigation/              # App-wide routes and the single NavHost.
├── di/                      # App-level Koin modules.
└── theme/                   # Global Compose UI styling.
```

## Folder definitions (required)

- Use the `org.company.app` package style and keep feature-specific code under `feature/<featureName>/`. App-wide configurations go in root folders like `navigation/`, `di/`, or `theme/`.
- `feature/<featureName>/domain/model/` — domain entities and value objects only.
- `feature/<featureName>/domain/` — use cases and repository interface only (no implementation details)
- `feature/<featureName>/data/repository/` — repository implementations that satisfy domain repository contracts.
- `feature/<featureName>/data/remote/` — API clients, DTOs, and network mappers.
- `feature/<featureName>/data/local/` — Room, KStore, and Settings sources plus persistence mappers.
- `feature/<featureName>/presentation/` — feature-scoped `UiState`, `UiEvent`, `ViewModel`, and screen files.
- `navigation/` — app-wide routes and the single nav host (lives at `{{PACKAGE_PATH}}/navigation/`, outside features).
- If two or more features share the same domain model/use case/repository contract, extract it to `feature/common/` (`feature/common/domain/...`, `feature/common/data/...`) and consume it from feature-specific folders.
- Cross-layer imports are forbidden except through the declared dependency direction (`presentation -> domain`, `data -> domain`).
- `domain` must remain framework-agnostic and may only depend on Kotlin stdlib, coroutines primitives, and other `domain` packages.

## Domain-Driven Design (DDD) modeling contract

- **Bounded context = feature folder**: each `feature/<featureName>/` is a bounded context and owns its ubiquitous language, models, and use cases.
- **Shared kernel only when necessary**: move code to `feature/common/` only after at least two feature contexts actively reuse it.
- **Domain models are the source of truth**: API DTOs, DB entities, and UI models must map from/to domain models; they never replace them.
- **Entity identity rule**: if lifecycle identity matters, model as an entity (stable id + behavior invariants); otherwise use value objects.
- **Use case granularity**: each use case represents one business capability and one reason to change. Avoid "god" use cases.
- **Domain errors**: expose business failures as domain-specific sealed hierarchies (for example, `CreateOrderError`) instead of transport/driver exceptions.

## Mapper and boundary rules (required)

- Place mappers close to boundary they cross:
  - `data/remote/` for DTO <-> domain transformations.
  - `data/local/` for Entity <-> domain transformations.
  - `presentation/` for domain <-> UI model/state transformations.
- Never expose DTOs/Entities outside `data` packages.
- Never expose Compose/UI models outside `presentation` packages.
- Use extension functions when mapping is straightforward; use dedicated mapper classes only when dependencies are required.

## Mapping decision matrix (domain as SSOT)

- Treat domain models as the only business source of truth; boundary models are adapters, never owners of business rules.
- Mapping is **mandatory** when crossing boundaries with different concerns (`remote DTO`, `local entity`, `UiState`/`UiModel`).
- Mapping may be **minimal** (single extension function per direction) when structures are currently identical, but boundary ownership must still remain explicit.
- Do not introduce generic mapping frameworks or reflection-based mappers; prefer explicit, local, testable functions.
- If a boundary starts identical and later diverges, evolve mapper functions in place instead of letting external models leak into domain.

## Class Responsibilities

To ensure strict separation of concerns, each layer and class type must adhere to explicit rules for what it **can** and **cannot** contain:

### Domain Layer
**Architectural Responsibility:** Encapsulates the core business rules and enterprise logic. It is completely isolated and must not depend on any outer layers (Data, Presentation, or platform frameworks).
- **Models (`domain/model/`)**
  - **Can:** Be pure Kotlin `data class`, `value class`, or `sealed interface` representing business concepts.
  - **Cannot:** Contain framework annotations (e.g., `@Serializable`, `@Entity`), platform imports, or functions that perform I/O.
- **Repository Interfaces (`domain/repository/`)**
  - **Can:** Define `suspend` functions and `Flow`s returning pure Domain Models.
  - **Cannot:** Expose implementation details like `HttpResponse`, Room queries, or specific exception types from data sources.
- **Use Cases (`domain/usecase/`)**
  - **Can:** Orchestrate one specific business rule combining multiple repositories. Must be stateless (`operator fun invoke`).
  - **Cannot:** Hold mutable state, use `runBlocking`, or depend on any UI/Data-layer class.

### Data Layer
**Architectural Responsibility:** Manages data retrieval, storage, and API communications. It implements the interfaces defined by the Domain layer and translates external data formats (DTOs, DB Entities) into pure Domain Models.
- **Repository Implementations (`data/repository/`)**
  - **Can:** Fetch from `remote/` or `local/` sources and map DTOs/Entities to Domain Models. Cache data.
  - **Cannot:** Leak DTOs/Entities to the domain layer. Hold UI-specific state.
- **Data Sources & DTOs (`data/remote/`, `data/local/`)**
  - **Can:** Use `@Serializable` for network payloads, `@Entity` for Room tables, and specify data mapping logic.
  - **Cannot:** Be used directly by the Presentation layer or Use Cases.

### Presentation Layer
**Architectural Responsibility:** Handles UI rendering, user interactions, and state management. It observes data from the Domain layer and translates user actions into Domain Use Case invocations.
- **UiState & UiEvent (`presentation/`)**
  - **Can:** `UiState` must be a 100% immutable `data class`. `UiEvent` must be a `sealed interface` of user actions.
  - **Cannot:** Contain business logic, mutable `var` properties, or framework/platform instances.
- **ViewModels (`presentation/`)**
  - **Can:** Map Domain Models to `UiState`, process `UiEvent`s, and manage async work exclusively via `viewModelScope`.
  - **Cannot:** Contain direct Android/iOS references (e.g., Context, UIViews), or access repositories directly if a Use Case exists.
- **Compose Screens (`presentation/`)**
  - **Can:** Map `UiState` into visual components and emit UI events/callbacks back to the ViewModel.
  - **Cannot:** Inject Repositories/Use Cases directly, or perform business/validation logic inside the Composable.

### Hard dependency rules (enforced by ArchUnit in `:sharedUI`'s commonTest)

- `domain` MUST NOT import anything from `data` or `presentation`.
- `presentation` MUST NOT import from `data`. It depends on `domain` only.
- `data` may depend on `domain` only.
- `runBlocking` is forbidden everywhere except test sources.
- Direct Android (`android.*`) or Apple (`platform.*`) imports are forbidden in `commonMain`.

## Feature minimum structure (must exist for new business capability)

For each new business capability, add all of the following artifacts unless explicitly not applicable:

- `domain/model/` model(s) representing the business concept.
- `domain/repository/` interface(s) for required data access.
- `domain/usecase/VerbNounUseCase.kt` entry point for the behavior.
- `data/repository/` implementation(s) fulfilling repository contracts.
- `presentation/` `UiState`, `UiEvent`, `ViewModel`, and screen/composable entry.
- `commonTest/` tests for at least the use case and ViewModel behavior.

If any item is skipped, document the reason in the PR description.

### No utility-module antipattern

- ❌ **Never** create catch-all files or objects named `Utils`, `Helpers`, `Common`, `Util`, `Helper`, or any synonym — in any layer or source set. *(Note: the directory `feature/common/` is allowed for shared feature code, but a file named `Common.kt` is forbidden).*
- Every helper/extension must live in a file whose name communicates its **domain** (e.g., `DateFormatting.kt`, `AuthTokenParser.kt`, `FlowExtensions.kt`).
- ❌ Catch-all files are forbidden.
- Prefer extension functions scoped to the exact type they operate on over free-standing top-level helpers whenever possible.

## MVVM contract

- ViewModels extend `androidx.lifecycle.ViewModel` and launch coroutines exclusively via `viewModelScope`.
- Each ViewModel exposes an immutable `data class XxxUiState` via a `StateFlow<XxxUiState>` and accepts a `sealed interface XxxUiEvent` through a single `handleEvent(event)` entry point.
- Navigation uses **AndroidX Navigation 3** (Compose Multiplatform). ViewModels are scoped to backstack entries.

## Composition root and DI boundaries

- DI wiring is allowed in `di/` and platform entry points only.
- `presentation` depends on abstractions from `domain`; concrete implementations are provided by Koin modules.
- Do not call `startKoin` from feature files; initialize once per platform app entry point.
- Constructor injection is mandatory for ViewModels, use cases, and repositories.

## Navigation contract

- All destinations live in `commonMain/kotlin/{{PACKAGE_PATH}}/navigation/AppRoute.kt` as `@Serializable` variants of a single `sealed interface AppRoute : NavKey`.
- The graph is declared **once** in `navigation/AppNavHost.kt` using `rememberNavBackStack(...)` + `NavDisplay(...)` + `entryProvider { entry<AppRoute.X> { key -> XScreen(...) } }`.
- Screens receive navigation lambdas (`onNavigateToY`, `onBack`) as **parameters**; they MUST NOT import the backstack directly.
- ViewModels with route arguments are registered with `viewModel { (arg: T) -> XxxViewModel(arg, get()) }` and resolved at the call site via `koinViewModel { parametersOf(key.arg) }` so each backstack entry owns a fresh instance.
- Back navigation: `onBack = { count -> repeat(count) { backStack.removeLastOrNull() } }` on `NavDisplay`.

## Definition of done for architecture compliance

- New/changed behavior keeps dependency direction valid (`presentation -> domain`, `data -> domain`, never inverse).
- No platform imports, no `runBlocking`, and no direct data-source types leaking across boundaries.
- PR includes tests for business logic changes in `commonTest`.
- Naming follows domain language; no generic utility file names.


