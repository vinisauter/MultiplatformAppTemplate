# scripts/init.ps1
# Local Windows alternative to the `Initialize KMP Project Template` GitHub Actions workflow.
# Rewrites placeholders, prunes unselected platforms, writes .template.config,
# self-destructs init.yml, then runs scripts/team.install.ps1.
#
# Usage (interactive):
#   pwsh scripts/init.ps1
#
# Usage (non-interactive):
#   pwsh scripts/init.ps1 -ProjectName "MyApp" -PackageName "com.template.app" `
#       -IncludeAndroid -IncludeIos -IncludeWeb -IncludeDesktop

[CmdletBinding()]
param(
    [string]$ProjectName,
    [string]$PackageName,
    [string]$IncludeAndroid,
    [string]$IncludeIos,
    [string]$IncludeWeb,
    [string]$IncludeDesktop,
    [switch]$SkipInstall
)

$ErrorActionPreference = 'Stop'

function Read-StringIfEmpty {
    param([string]$Current, [string]$Prompt)
    if ([string]::IsNullOrWhiteSpace($Current)) {
        return (Read-Host $Prompt)
    }
    return $Current
}

function ConvertTo-NullableBool {
    param([string]$Value)
    if ([string]::IsNullOrWhiteSpace($Value)) { return $false }
    switch -Regex ($Value.Trim().ToLowerInvariant()) {
        '^(1|true|t|yes|y|\$true)$'  { return $true }
        '^(0|false|f|no|n|\$false)$' { return $false }
        default {
            Write-Error "Invalid boolean value '$Value'. Use true/false, yes/no, 1/0."
            exit 1
        }
    }
}

$ProjectName    = Read-StringIfEmpty $ProjectName 'Project name (e.g. MyApp)'
$PackageName    = Read-StringIfEmpty $PackageName 'Package name (e.g. com.myapp)'
[bool]$android  = ConvertTo-NullableBool     $IncludeAndroid 'Include Android target?'
[bool]$ios      = ConvertTo-NullableBool     $IncludeIos     'Include iOS target?'
[bool]$web      = ConvertTo-NullableBool     $IncludeWeb     'Include Web target?'
[bool]$desktop  = ConvertTo-NullableBool     $IncludeDesktop 'Include Desktop target?'

# Log the values of the platform include variables before removal logic
Write-Host "[DEBUG] ProjectName: $ProjectName" -ForegroundColor Magenta
Write-Host "[DEBUG] PackageName: $PackageName" -ForegroundColor Magenta
Write-Host "[DEBUG] IncludeAndroid: $android" -ForegroundColor Magenta
Write-Host "[DEBUG] IncludeIos: $ios" -ForegroundColor Magenta
Write-Host "[DEBUG] IncludeWeb: $web" -ForegroundColor Magenta
Write-Host "[DEBUG] IncludeDesktop: $desktop" -ForegroundColor Magenta

# ---- Validation ----
if ($ProjectName -notmatch '^[A-Za-z][A-Za-z0-9_-]*$') {
    Write-Error 'project_name must start with a letter and contain only [A-Za-z0-9_-].'
    exit 1
}
if ($PackageName -notmatch '^[a-z][a-z0-9_]*(\.[a-z][a-z0-9_]*)+$') {
    Write-Error 'package_name must be a valid dotted lowercase Kotlin package (e.g. com.myapp).'
    exit 1
}
if (-not ($android -or $ios -or $web -or $desktop)) {
    Write-Error 'At least one platform must be enabled.'
    exit 1
}

$RepoRoot = (& git rev-parse --show-toplevel).Trim()
Set-Location $RepoRoot

$PackagePath = $PackageName -replace '\.', '/'

Write-Host ""
Write-Host " Initializing template:" -ForegroundColor Cyan
Write-Host "   project_name = $ProjectName"
Write-Host "   package_name = $PackageName"
Write-Host "   package_path = $PackagePath"
Write-Host "   android=$android  ios=$ios  web=$web  desktop=$desktop"
Write-Host ""

function Get-RepoTextFiles {
    Get-ChildItem -Recurse -File -Force | Where-Object {
        $_.FullName -notmatch '\\(\.git|\.gradle|build|\.idea)\\' -and
        $_.Length -lt 5MB
    }
}

# ---- 1. Rewrite placeholders ----
Write-Host 'STEP 1: Rewriting {{PROJECT_NAME}} / {{PACKAGE_NAME}} / {{PACKAGE_PATH}} placeholders...'
$step1Success = $true
foreach ($file in Get-RepoTextFiles) {
    try {
        $content = [System.IO.File]::ReadAllText($file.FullName)
    } catch {
        $step1Success = $false
        Write-Error "[STEP 1] Failed to read $($file.FullName)"
        continue
    }
    if ($content -match '\{\{PROJECT_NAME\}\}|\{\{PACKAGE_NAME\}\}|\{\{PACKAGE_PATH\}\}') {
        try {
            $new = $content.Replace('{{PROJECT_NAME}}', $ProjectName).
                            Replace('{{PACKAGE_NAME}}', $PackageName).
                            Replace('{{PACKAGE_PATH}}', $PackagePath)
            [System.IO.File]::WriteAllText($file.FullName, $new)
        } catch {
            $step1Success = $false
            Write-Error "[STEP 1] Failed to write $($file.FullName)"
        }
    }
}
if ($step1Success) { Write-Host 'STEP 1: Success' -ForegroundColor Green } else { Write-Error 'STEP 1: Failed' }

# ---- 2. Rewrite Kotlin package declarations + rename directories ----
Write-Host "STEP 2: Renaming Kotlin package directories org.company.app -> $PackageName ..."
$step2Success = $true
Get-ChildItem -Recurse -File -Filter *.kt | Where-Object {
    $_.FullName -notmatch '\\(build|\.gradle)\\'
} | ForEach-Object {
    try {
        $content = [System.IO.File]::ReadAllText($_.FullName)
        if ($content.Contains('org.company.app')) {
            [System.IO.File]::WriteAllText($_.FullName, $content.Replace('org.company.app', $PackageName))
        }
    } catch {
        $step2Success = $false
        Write-Error "[STEP 2] Failed to process $($_.FullName)"
    }
}
if ($step2Success) { Write-Host 'STEP 2: Success' -ForegroundColor Green } else { Write-Error 'STEP 2: Failed' }

$step2bSuccess = $true
foreach ($module in @('sharedUI', 'androidApp', 'desktopApp', 'webApp', 'iosApp')) {
    if (-not (Test-Path $module)) { continue }
    $sourceRoots = Get-ChildItem -Path "$module/src" -Directory -ErrorAction SilentlyContinue |
        ForEach-Object { Join-Path $_.FullName 'kotlin' } |
        Where-Object { Test-Path $_ }
    foreach ($srcRoot in $sourceRoots) {
        $oldPkg = Join-Path $srcRoot 'org/company/app'
        $newPkg = Join-Path $srcRoot $PackagePath
        Write-Host "[STEP 2b] oldPkg: $oldPkg" -ForegroundColor Cyan
        Write-Host "[STEP 2b] newPkg: $newPkg" -ForegroundColor Cyan
        if (-not (Test-Path $oldPkg)) {
            Write-Host "[STEP 2b] Skipping: $oldPkg does not exist." -ForegroundColor DarkGray
            continue
        }
        try {
            if (-not (Test-Path $newPkg)) {
                New-Item -ItemType Directory -Force -Path $newPkg | Out-Null
            } else {
                Write-Host "[STEP 2b] $newPkg already exists, skipping directory creation." -ForegroundColor DarkGray
            }
            Get-ChildItem -Path $oldPkg -Force | ForEach-Object {
                $dest = Join-Path $newPkg $_.Name
                if (Test-Path $dest) {
                    Write-Host "[STEP 2b] Removing existing file before move: $dest" -ForegroundColor DarkGray
                    Remove-Item -Force $dest
                }
                Move-Item -Force -Path $_.FullName -Destination $newPkg
            }
            Remove-Item -Recurse -Force (Join-Path $srcRoot 'org')
        } catch {
            $step2bSuccess = $false
            Write-Error "[STEP 2b] Failed to move/rename in $srcRoot. Exception: $($_.Exception.Message)"
        }
    }
}

if ($step2bSuccess) { Write-Host 'STEP 2b: Success' -ForegroundColor Green } else { Write-Error 'STEP 2b: Failed' }

Write-Host 'STEP 3: Pruning unselected platforms...'
$step3Success = $true

function Remove-Region {
    param([string]$Platform)
    Write-Host "[Remove-Region] Called with Platform='$Platform'" -ForegroundColor Yellow
    $startMarker = "// region $Platform"
    $endMarker   = "// endregion $Platform"
    Write-Host "[Remove-Region] Start marker: '$startMarker' | End marker: '$endMarker'" -ForegroundColor Yellow
    $files = Get-ChildItem -Recurse -File | Where-Object {
        ($_.Name -eq 'build.gradle.kts' -or $_.Name -eq 'settings.gradle.kts' -or $_.Extension -eq '.kt') -and
        $_.FullName -notmatch '[\\/](build|\.gradle|\.git)[\\/]'
    }
    Write-Host "[Remove-Region] Files to process: $($files.Count)" -ForegroundColor Yellow
    foreach ($file in $files) {
        Write-Host "[Remove-Region] Processing file: $($file.FullName)" -ForegroundColor Yellow
        try {
            $lines = [System.IO.File]::ReadAllLines($file.FullName)
            $out = New-Object System.Collections.Generic.List[string]
            $inside = $false
            $changed = $false
            $lineNum = 0
            foreach ($line in $lines) {
                $lineNum++
                if ($line -match '^\s*' + [Regex]::Escape($startMarker) + '\b') {
                    Write-Host "[Remove-Region] Entering region at line $lineNum in $($file.Name)" -ForegroundColor Cyan
                    $inside = $true;  $changed = $true; continue
                }
                if ($line -match '^\s*' + [Regex]::Escape($endMarker)   + '\b') {
                    Write-Host "[Remove-Region] Exiting region at line $lineNum in $($file.Name)" -ForegroundColor Cyan
                    $inside = $false; $changed = $true; continue
                }
                if (-not $inside) { $out.Add($line) }
            }
            if ($changed) {
                [System.IO.File]::WriteAllLines($file.FullName, $out)
                Write-Host "   - pruned // region $Platform from $($file.FullName.Substring($RepoRoot.Length + 1))" -ForegroundColor Green
            } else {
                Write-Host "[Remove-Region] No region found in $($file.Name)" -ForegroundColor DarkGray
            }
        } catch {
            $script:step3Success = $false
            Write-Error "[STEP 3] Failed to prune region $Platform in $($file.FullName)"
        }
    }
}

function Remove-ModuleDir {
    param([string]$Module)
    try {
        if (Test-Path $Module) {
            Remove-Item -Recurse -Force $Module
        }
        $settings = 'settings.gradle.kts'
        if (Test-Path $settings) {
            $lines = [System.IO.File]::ReadAllLines($settings) | Where-Object {
                $_ -notmatch [Regex]::Escape("include(`":$Module`")")
            }
            [System.IO.File]::WriteAllLines($settings, $lines)
        }
    } catch {
        $script:step3Success = $false
        Write-Error "[STEP 3] Failed to remove module dir $Module"
    }
}

if (-not $android) { Write-Host '-> Removing Android target...'; Remove-Region 'android'; Remove-ModuleDir 'androidApp' }
if (-not $ios)     { Write-Host '-> Removing iOS target...';     Remove-Region 'ios';     Remove-ModuleDir 'iosApp' }
if (-not $web)     { Write-Host '-> Removing Web target...';     Remove-Region 'web';     Remove-ModuleDir 'webApp' }
if (-not $desktop) { Write-Host '-> Removing Desktop target...'; Remove-Region 'desktop'; Remove-ModuleDir 'desktopApp' }
if ($step3Success) { Write-Host 'STEP 3: Success' -ForegroundColor Green } else { Write-Error 'STEP 3: Failed' }

# ---- 4. Write .template.config ----
Write-Host 'STEP 4: Writing .template.config...'
$step4Success = $true
try {
    $templateConfig = @(
        "# Generated by scripts/init.ps1 - do not edit by hand.",
        "PROJECT_NAME=$ProjectName",
        "PACKAGE_NAME=$PackageName",
        "INCLUDE_ANDROID=$($android.ToString().ToLower())",
        "INCLUDE_IOS=$($ios.ToString().ToLower())",
        "INCLUDE_WEB=$($web.ToString().ToLower())",
        "INCLUDE_DESKTOP=$($desktop.ToString().ToLower())"
    ) -join "`n"
    [System.IO.File]::WriteAllText('.template.config', $templateConfig + "`n")
} catch {
    $step4Success = $false
    Write-Error '[STEP 4] Failed to write .template.config'
}
if ($step4Success) { Write-Host 'STEP 4: Success' -ForegroundColor Green } else { Write-Error 'STEP 4: Failed' }

# ---- 5. Self-destruct: remove init workflow + sibling init scripts ----
Write-Host 'STEP 5: Removing init workflow + scripts/init.* ...'
$step5Success = $true
# try {
#     Remove-Item -Force '.github/workflows/init.yml' -ErrorAction SilentlyContinue
#     Remove-Item -Force 'scripts/init.sh'             -ErrorAction SilentlyContinue
# } catch {
#     $step5Success = $false
#     Write-Error '[STEP 5] Failed to remove init workflow or init.sh'
# }
$selfPath = $MyInvocation.MyCommand.Path
if ($step5Success) { Write-Host 'STEP 5: Success' -ForegroundColor Green } else { Write-Error 'STEP 5: Failed' }

# ---- 6. Run team.install ----
Write-Host 'STEP 6: Running team.install...'
$step6Success = $true
if ($SkipInstall) {
    Write-Host '>> Skipping team.install (-SkipInstall).'
} else {
    Write-Host ''
    Write-Host '>> Running scripts/team.install.ps1...'
    try {
        $psHost = if (Get-Command pwsh -ErrorAction SilentlyContinue) { 'pwsh' } else { 'powershell' }
        & $psHost -NoProfile -File 'scripts/team.install.ps1'
    } catch {
        $step6Success = $false
        Write-Error '[STEP 6] Failed to run team.install.ps1'
    }
}
if ($step6Success) { Write-Host 'STEP 6: Success' -ForegroundColor Green } else { Write-Error 'STEP 6: Failed' }

# Remove this script last so it stays valid through execution.
Write-Host 'Final step: Self-destruct (removing this script)...'
try {
    if ($selfPath -and (Test-Path $selfPath)) {
        Remove-Item -Force $selfPath -ErrorAction SilentlyContinue
    }
    Write-Host 'Self-destruct: Success' -ForegroundColor Green
} catch {
    Write-Error 'Self-destruct: Failed'
}

Write-Host ''
Write-Host " Template initialized as $ProjectName ($PackageName). Review the changes and commit." -ForegroundColor Green
