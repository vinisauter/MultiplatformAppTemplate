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

#### Step 1 — Get the code

Pick one of the two flows below.

**Flow 1 — Use this template + clone your new repo (recommended).** First click **"Use this template" → Create a new repository** on GitHub (skip running the Actions workflow), then clone *your* repo locally:

```bash
# Replace <you>/<your-new-repo> with the repo you just created.
git clone https://github.com/<you>/<your-new-repo>.git my-app
cd my-app
```

```powershell
git clone https://github.com/<you>/<your-new-repo>.git my-app
Set-Location my-app
```

**Flow 2 — Clone the template directly and re-point origin.** Use this when you don't want a fork on GitHub yet, or you're targeting a different host (GitLab, Gitea, etc.):

```bash
git clone https://github.com/vinisauter/MultiplatformAppTemplate.git my-app
cd my-app
rm -rf .git                                  # detach the template's history
git init -b main
# Optional: point at your own remote when ready.
# git remote add origin git@github.com:<you>/<your-new-repo>.git
```

```powershell
git clone https://github.com/vinisauter/MultiplatformAppTemplate.git my-app
Set-Location my-app
Remove-Item -Recurse -Force .git              # detach the template's history
git init -b main
# Optional: point at your own remote when ready.
# git remote add origin git@github.com:<you>/<your-new-repo>.git
```

#### Step 2 — Run the init script

The script accepts arguments for non-interactive runs, **or prompts interactively** when any are omitted. It validates inputs, rewrites placeholders (`{{PROJECT_NAME}}`, `{{PACKAGE_NAME}}`, `{{PACKAGE_PATH}}`), renames the Kotlin source directories `org/company/app` → your dotted package, prunes unselected platforms via `// region <plat>` markers, writes `.template.config`, then **automatically runs `team.install`** (Git hooks + environment validation).

**macOS / Linux**

```bash
chmod +x scripts/init.sh scripts/team.install.sh scripts/hooks/*.sh
bash scripts/init.sh \
  --project-name "ImoBull" \
  --package-name "com.acme.app" \
  --android true --ios true --web true --desktop true
```

Or interactively: `bash scripts/init.sh`

**Windows (Windows PowerShell 5.1 or PowerShell 7+)**

```powershell
powershell -File scripts/init.ps1 `
  -ProjectName "ImoBull" `
  -PackageName "com.acme.app" `
  -IncludeAndroid:$true -IncludeIos:$true -IncludeWeb:$true -IncludeDesktop:$true
```

Or interactively: `powershell -File scripts/init.ps1`

> When the script finishes, it self-deletes (`scripts/init.sh`, `scripts/init.ps1`, and `.github/workflows/init.yml`). The repo is now committed-clean — only your tracked-but-modified files remain.

#### Step 3 — Initial commit + push

```bash
git add -A
git commit -m "chore: initialize ImoBull from MultiplatformAppTemplate"
git push -u origin main      # or master, depending on your default branch
```

```powershell
git add -A
git commit -m "chore: initialize ImoBull from MultiplatformAppTemplate"
git push -u origin main
```

#### Step 4 — Open in Android Studio

```bash
# macOS
open -a "Android Studio" .
```

```powershell
# Windows
Start-Process "studio64.exe" -ArgumentList (Get-Location).Path
```

The first sync will download Gradle dependencies. From here, follow the **▶️ Run locally** section below for each platform you kept.

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
