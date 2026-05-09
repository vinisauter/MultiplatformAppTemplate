# {{PROJECT_NAME}} — KMP + MVVM Template

A **GitHub Template Repository** for production-grade Kotlin Multiplatform apps with Jetpack Compose, MVVM, Clean Architecture, and a Copilot-aware ADK ecosystem.

> Modules: `:sharedUI` (commonMain logic + Compose UI) • `:androidApp` • `:iosApp` • `:desktopApp` • `:webApp`.
> Stack: Koin, Ktor, Apollo Kotlin, Room KMP, AndroidX ViewModel + Navigation 3, Kermit, kotlinx-datetime, Multiplatform Settings, KStore, Coil 3, MaterialKolor, BuildConfig.

---

## 🚀 Use this template

You have **two equivalent ways** to initialize a new project from this template — both delegate to the same logic in [`scripts/init.sh`](scripts/init.sh), so behavior is identical.

### Option A — GitHub Actions (no local clone required)

1. Click **"Use this template" → Create a new repository** on GitHub.
2. In the new repo, open **Actions → `Initialize KMP Project Template` → Run workflow**.
3. Fill the inputs:

   | Input             | Description                                                                          |
   |-------------------|--------------------------------------------------------------------------------------|
   | `project_name`    | Human-readable name. Used in app labels, manifest, settings.                         |
   | `package_name`    | Dotted Kotlin package (e.g. `com.acme.app`). Used as namespace + applicationId root. |
   | `include_android` | Keep the `:androidApp` module + Android target.                                      |
   | `include_ios`     | Keep the `:iosApp` module + Apple Kotlin/Native targets.                             |
   | `include_web`     | Keep the `:webApp` module + JS/WasmJS targets.                                       |
   | `include_desktop` | Keep the `:desktopApp` module + JVM target.                                          |

4. The workflow runs `scripts/init.sh --skip-install` with your inputs (the script rewrites placeholders, prunes any unselected platform via `// region <plat>` markers, writes `.template.config`, and self-destructs `init.yml` + the `init.{sh,ps1}` scripts), then commits and pushes the result.
5. Pull the resulting commit locally and run the onboarding script (next section).

> ⚠️ At least one platform checkbox must be enabled. The script validates inputs and fails fast otherwise.

### Option B — Local script (no GitHub Actions minutes consumed)

If Actions are disabled on your fork, or you'd rather initialize offline, run the **same** script directly after cloning. It performs the rewrite + prune steps and **automatically chains into `team.install`** at the end.

- **macOS / Linux:** `bash scripts/init.sh`
- **Windows (Windows PowerShell 5.1 or PowerShell 7+):** `powershell -File scripts/init.ps1` (or `pwsh -File scripts/init.ps1`)

Both scripts accept arguments for non-interactive runs:

```bash
bash scripts/init.sh \
  --project-name "ImoBull" \
  --package-name "com.acme.app" \
  --android true --ios true --web true --desktop true
```

```powershell
pwsh scripts/init.ps1 -ProjectName "ImoBull" -PackageName "com.acme.app" `
    -IncludeAndroid:$true -IncludeIos:$true -IncludeWeb:$true -IncludeDesktop:$true
```

When finished, the scripts self-destruct (`init.sh` / `init.ps1` and `.github/workflows/init.yml`), commit-ready.

## 🛠️ Post-clone bootstrap

After cloning the initialized repo:

- **macOS / Linux:** `bash scripts/team.install.sh`
- **Windows (Windows PowerShell 5.1 or PowerShell 7+):** `powershell -File scripts/team.install.ps1`

This verifies the Copilot instructions in `.github/`, installs `pre-commit` (ktlint + ArchUnit) and `pre-push` (`check jvmTest compileCommonMainKotlinMetadata`) Git hooks, and validates JDK 17+ (and `kdoctor` on macOS for iOS work).

## 📁 Repository layout

```
.github/
  copilot-instructions.md           Memory layer (Copilot global rules)
  instructions/                     Path-scoped rules
    architecture.instructions.md
    global.instructions.md
    project.instructions.md
  personas/                         Delegation layer (Chat personas)
    code-reviewer.md
    test-runner.md
    explorer.md
  workflows/
    init.yml                        Template initialization (self-destructs)
    kmp-ci.yml                      Optimized CI (Linux fast path + gated iOS)
scripts/
  init.sh / .ps1                    Local alternative to init.yml (chains into team.install)
  generate_viewmodel.sh / .ps1      Knowledge layer scaffolders
  team.install.sh / .ps1            Distribution layer (onboarding)
  hooks/                            Protection layer
    SessionStart.sh / .ps1
    PreToolUse.sh / .ps1            Installed as pre-commit
    PostToolUse.sh / .ps1           Installed as pre-push
sharedUI/                           commonMain ViewModels, repos, UI
androidApp/  iosApp/  desktopApp/  webApp/   Platform entry points
manifest.json                       Distribution manifest
SKILL.md                            Copilot Chat prompt catalog
context.md                          Deep technical context
.template.config                    Per-project flags consumed by CI
```

## 🤖 ADK 5-layer model

| Layer            | Files                                                       |
|------------------|-------------------------------------------------------------|
| **Memory**       | `.github/copilot-instructions.md`, `.github/instructions/*` |
| **Knowledge**    | `SKILL.md`, `context.md`, `scripts/generate_*.{sh,ps1}`     |
| **Protection**   | `scripts/hooks/*.{sh,ps1}`                                  |
| **Delegation**   | `.github/personas/*.md`                                     |
| **Distribution** | `manifest.json`, `scripts/team.install.{sh,ps1}`            |

## 💸 GitHub Actions Free-tier strategy

The 2,000-minute monthly budget is protected by:

1. **Local shift-left:** ktlint + ArchUnit + JVM tests + `compileCommonMainKotlinMetadata` run in pre-commit / pre-push hooks.
2. **Linux-first CI:** every PR runs only the Linux fast-path job (1× cost).
3. **iOS gating:** `compileKotlinIosX64` + `compileKotlinIosSimulatorArm64` (10× cost) run **only on push to `main`** or via manual `workflow_dispatch`, and only if `INCLUDE_IOS=true` in `.template.config`.
4. **Konan cache:** `~/.konan` is keyed on `gradle/libs.versions.toml`.

## ▶️ Run locally

### Android
- Open in Android Studio and run the `androidApp` configuration, **or** `./gradlew :androidApp:assembleDebug`.

### Desktop
- `./gradlew :desktopApp:run`

### iOS
- Open `iosApp/iosApp.xcodeproj` in Xcode, or use the [Kotlin Multiplatform plugin](https://plugins.jetbrains.com/plugin/14936-kotlin-multiplatform-mobile) for Android Studio.

### Web
- Distribution: `./gradlew :webApp:composeCompatibilityBrowserDistribution` (output in `webApp/build/dist/composeWebCompatibility/productionExecutable`).
- Dev server: `./gradlew :webApp:jsBrowserDevelopmentRun` or `:webApp:wasmJsBrowserDevelopmentRun`.

## 📑 `.template.config` schema

```
PROJECT_NAME=<string>
PACKAGE_NAME=<dotted-lowercase>
INCLUDE_ANDROID=true|false
INCLUDE_IOS=true|false
INCLUDE_WEB=true|false
INCLUDE_DESKTOP=true|false
```

The CI `setup` job reads this file and exposes the flags as job outputs gating each platform job.
