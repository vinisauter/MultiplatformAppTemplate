# scripts/team.install.ps1
# Onboarding script (Windows): wires Copilot rules + Git hooks for a freshly cloned repo.

$ErrorActionPreference = 'Stop'
$RepoRoot = (& git rev-parse --show-toplevel).Trim()
Set-Location $RepoRoot

Write-Host " Installing ADK ecosystem for Android Studio + GitHub Copilot..."

$required = @(
    '.github/copilot-instructions.md',
    '.github/instructions/architecture.instructions.md',
    '.github/instructions/global.instructions.md',
    '.github/instructions/project.instructions.md'
)
foreach ($f in $required) {
    if (-not (Test-Path $f)) {
        Write-Host " Missing $f - repository is in an inconsistent state."
        exit 1
    }
}
Write-Host " Copilot instructions in place."

# Install Git hooks. On Windows, Git for Windows still executes hooks via bash if the file
# starts with a shebang, so we copy the .sh variants. The .ps1 variants are kept for manual runs.
New-Item -ItemType Directory -Force -Path '.git/hooks' | Out-Null
Copy-Item -Force 'scripts/hooks/PreToolUse.sh'  '.git/hooks/pre-commit'
Copy-Item -Force 'scripts/hooks/PostToolUse.sh' '.git/hooks/pre-push'
Write-Host " Git hooks installed (pre-commit, pre-push)."

# Validate environment
& "$PSHOME\powershell.exe" -NoProfile -File scripts/hooks/SessionStart.ps1

Write-Host ""
Write-Host " Done. Android Studio is now Copilot-aware and GitHub Actions Free minutes are guarded."

# Self-destruct & clean up
Remove-Item -Recurse -Force 'scripts' -ErrorAction SilentlyContinue
Write-Host "🧹 Onboarding scripts removed. Happy coding!"
