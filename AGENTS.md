# Agent Orchestration — {{PROJECT_NAME}}

This repository is designed for **AI-First development**. It contains specialized instructions and personas to ensure that any AI agent (Copilot, Cursor, etc.) adheres to the project's strict Kotlin Multiplatform (KMP) and Clean Architecture standards.

## 🤖 Available Personas

When working with an AI assistant, you can delegate specific tasks by invoking these personas from `.github/personas/`:

| Persona                 | Invocation Hint                                   | Primary Focus                                             |
|:------------------------|:--------------------------------------------------|:----------------------------------------------------------|
| **Code Reviewer**       | `@workspace Using code-reviewer.md, review...`    | Layer boundaries, DDD, Native interop, and thread safety. |
| **Test Runner**         | `@workspace Using test-runner.md, write tests...` | `commonTest` coverage using fakes and Ktor MockEngine.    |
| **Dependency Explorer** | `@workspace Using explorer.md, resolve...`        | Gradle version catalog conflicts and KMP compatibility.   |

## 📜 Instruction Sets

Agents are automatically configured to follow these rules via `.ai-instructions.md`, but you can also reference them manually:

- **[Architecture](.github/instructions/architecture.instructions.md)**: Layering (`presentation -> domain <- data`), folder structure, and DDD contracts.
- **[Global Conventions](.github/instructions/global.instructions.md)**: Coroutines usage, logging with Kermit, and the strict **No-Utility-Modules** rule.
- **[Project Library Catalog](.github/instructions/project.instructions.md)**: The strict allow-list of approved libraries (Koin, Ktor, Room, Nav3).

## 🛠 Central Architectural Rules

1.  **Maximize `commonMain`**: Logic only moves to platform source sets for hardware/OS entry points.
2.  **Unidirectional Flow**: UI observes StateFlow from ViewModels; ViewModels execute UseCases; UseCases interact with Repository interfaces.
3.  **Pure Domain**: The `domain` package must be framework-free (no `@Serializable`, no Compose).
4.  **Native-Safe Testing**: No MockK or Mockito. Use hand-rolled fakes for pure Kotlin and `MockEngine` for Ktor.

## 🔗 Entry Points for Agents

- **[.ai-instructions.md](.ai-instructions.md)**: The global summary for AI assistants.
- **[.cursorrules](.cursorrules)** / **[.clinerules](.clinerules)**: Auto-loading configuration for Cursor and Cline.
- **[context.md](context.md)**: Deep technical rationale for the stack (Navigation 3, ViewModel KMP, etc.).
