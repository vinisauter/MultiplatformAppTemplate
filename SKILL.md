# SKILL.md — Copilot Chat Prompt Catalog

These prompts are battle-tested templates. Paste into **GitHub Copilot Chat** inside Android Studio. The `@workspace` participant gives Copilot access to the rules in `.github/`.

---

## 1. Generate a ViewModel (MVVM Multiplatform)

```
@workspace Create a KMP ViewModel for the entity [NAME] under sharedUI/src/commonMain/kotlin/<package>/feature/[name]/presentation/. Use androidx.lifecycle.ViewModel, define an immutable data class [NAME]UiState, expose state via StateFlow, and handle events through a sealed interface [NAME]UiEvent + handleEvent(event). Launch coroutines exclusively via viewModelScope. Log initialization with Kermit.
```

## 2. Create a Repository (interface + implementation)

```
@workspace Generate the repository interface [NAME]Repository under domain/ and the implementation [NAME]RepositoryImpl under data/. Inject Ktor HttpClient (and/or the Apollo ApolloClient and/or the Room DAO) via Koin. Wire the binding in dataModule.
```

## 3. Add a GraphQL operation

```
@workspace Add a GraphQL [query|mutation] for [ACTION] using Apollo Kotlin syntax in sharedUI/src/commonMain/graphql/. Update schema.graphqls if needed and call it from the relevant repository implementation. Map the response into the domain model.
```

## 4. Add a Room entity + DAO

```
@workspace Create a Room entity [NAME] and DAO [NAME]Dao in data/local/. Update the AppDatabase abstract class. Provide expect getDatabaseBuilder() in commonMain and actual factories in androidMain/iosMain/jvmMain using BundledSQLiteDriver / NativeSQLiteDriver. Annotate the database with @ConstructedBy.
```

## 5. Add a Compose screen with Nav3 destination

```
@workspace Add a new feature [NAME] with full Clean Architecture slice (domain/data/presentation). In sharedUI/src/commonMain/kotlin/<package>/navigation/AppRoute.kt, add a `@Serializable` variant `data class [NAME](...)` (or `data object` for argument-free routes) to the `AppRoute` sealed interface. In AppNavHost.kt, register an `entry<AppRoute.[NAME]> { key -> [NAME]Screen(... onBack = { backStack.removeLastOrNull() }) }` block. The screen must observe its ViewModel.uiState via collectAsState(), pass events through viewModel.handleEvent(...), and obtain the ViewModel via koinViewModel { parametersOf(key.arg) } if it takes route arguments. Register the new bindings in di/Modules.kt.
```

## 6. Refactor for Clean Architecture violation

```
@workspace I have a Clean Architecture violation: [paste class]. Using .github/personas/code-reviewer.md, propose a refactor that respects the dependency direction (presentation → domain ← data) and produces a unified diff.
```

## 7. Resolve a libs.versions.toml conflict

```
@workspace Using .github/personas/explorer.md, resolve this dependency error: [paste error]. Output the diff for libs.versions.toml plus the verification Gradle command.
```

## 8. Generate KMP-safe tests

```
@workspace Using .github/personas/test-runner.md, write commonTest tests for [class]. Use Ktor MockEngine, Apollo TestNetworkTransport, hand-rolled fakes (no reflective mocks), and runTest with StandardTestDispatcher.
```

---
