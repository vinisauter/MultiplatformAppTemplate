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
$DebugEnabled = $true

function Write-DebugLog {
    param([string]$Message)
    if ($DebugEnabled) {
        Write-Host "[DEBUG] $Message" -ForegroundColor Magenta
    }
}

function Read-StringIfEmpty {
    param([string]$Current, [string]$Prompt)
    if ([string]::IsNullOrWhiteSpace($Current)) {
        return (Read-Host $Prompt)
    }
    return $Current
}

function ConvertTo-NullableBool {
    param([string]$Value)
    if ([string]::IsNullOrWhiteSpace($Value)) { return $null }
    switch -Regex ($Value.Trim().ToLowerInvariant()) {
        '^(1|true|t|yes|y|\$true)$'  { return $true }
        '^(0|false|f|no|n|\$false)$' { return $false }
        default {
            Write-Error "Invalid boolean value '$Value'. Use true/false, yes/no, 1/0."
            exit 1
        }
    }
}

function Resolve-BoolWithDefault {
    param(
        [string]$InputValue,
        [bool]$DefaultValue
    )
    $parsed = ConvertTo-NullableBool $InputValue
    if ($null -eq $parsed) {
        return $DefaultValue
    }
    return [bool]$parsed
}

$ProjectName    = Read-StringIfEmpty $ProjectName 'Project name (e.g. MyApp)'
$PackageName    = Read-StringIfEmpty $PackageName 'Package name (e.g. com.myapp)'
[bool]$android  = Resolve-BoolWithDefault $IncludeAndroid $true
[bool]$ios      = Resolve-BoolWithDefault $IncludeIos     $true
[bool]$web      = Resolve-BoolWithDefault $IncludeWeb     $false
[bool]$desktop  = Resolve-BoolWithDefault $IncludeDesktop $false

Write-DebugLog "ProjectName: $ProjectName"
Write-DebugLog "PackageName: $PackageName"
Write-DebugLog "IncludeAndroid: $android"
Write-DebugLog "IncludeIos: $ios"
Write-DebugLog "IncludeWeb: $web"
Write-DebugLog "IncludeDesktop: $desktop"

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
$repoTextFiles = @(Get-RepoTextFiles)
Write-DebugLog "Step 1 candidate files: $($repoTextFiles.Count)"
foreach ($file in $repoTextFiles) {
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
Write-Host "STEP 2: Renaming package org.company.app -> $PackageName in all text files..."
$step2Success = $true
# Use Get-RepoTextFiles so iOS (.pbxproj, .plist, .swift), XML, gradle files, etc. are all covered.
Write-DebugLog "Step 2 candidate files: $($repoTextFiles.Count)"
foreach ($file in $repoTextFiles) {
    try {
        $content = [System.IO.File]::ReadAllText($file.FullName)
        if ($content.Contains('org.company.app')) {
            [System.IO.File]::WriteAllText($file.FullName, $content.Replace('org.company.app', $PackageName))
        }
    } catch {
        $step2Success = $false
        Write-Error "[STEP 2] Failed to process $($file.FullName)"
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
    Write-DebugLog "Remove-Region platform='$Platform'"
    $startMarker = "// region $Platform"
    $endMarker   = "// endregion $Platform"
    $files = Get-ChildItem -Recurse -File | Where-Object {
        ($_.Name -eq 'build.gradle.kts' -or $_.Name -eq 'settings.gradle.kts') -and
        $_.FullName -notmatch '[\\/](build|\.gradle|\.git)[\\/]'
    }
    Write-DebugLog "Remove-Region files to process: $($files.Count)"
    foreach ($file in $files) {
        try {
            $lines = [System.IO.File]::ReadAllLines($file.FullName)
            $out = New-Object System.Collections.Generic.List[string]
            $inside = $false
            $changed = $false
            $lineNum = 0
            foreach ($line in $lines) {
                $lineNum++
                if ($line -match '^\s*' + [Regex]::Escape($startMarker) + '\b') {
                    $inside = $true;  $changed = $true; continue
                }
                if ($line -match '^\s*' + [Regex]::Escape($endMarker)   + '\b') {
                    $inside = $false; $changed = $true; continue
                }
                if (-not $inside) { $out.Add($line) }
            }
            if ($changed) {
                [System.IO.File]::WriteAllLines($file.FullName, $out)
                Write-Host "   - pruned // region $Platform from $($file.FullName.Substring($RepoRoot.Length + 1))" -ForegroundColor Green
            }
        } catch {
            $script:step3Success = $false
            Write-Error "[STEP 3] Failed to prune region $Platform in $($file.FullName)"
        }
    }
}

function Remove-RegionMarkers {
    param([string]$Platform)
    Write-DebugLog "Remove-RegionMarkers platform='$Platform'"
    $startMarker = "// region $Platform"
    $endMarker   = "// endregion $Platform"
    $files = Get-ChildItem -Recurse -File | Where-Object {
        ($_.Name -eq 'build.gradle.kts' -or $_.Name -eq 'settings.gradle.kts') -and
        $_.FullName -notmatch '[\\/](build|\.gradle|\.git)[\\/]'
    }
    Write-DebugLog "Remove-RegionMarkers files to process: $($files.Count)"
    foreach ($file in $files) {
        try {
            $lines = [System.IO.File]::ReadAllLines($file.FullName)
            $out = New-Object System.Collections.Generic.List[string]
            $changed = $false
            $lineNum = 0
            foreach ($line in $lines) {
                $lineNum++
                if ($line -match '^\s*' + [Regex]::Escape($startMarker) + '\b') {
                    $changed = $true; continue
                }
                if ($line -match '^\s*' + [Regex]::Escape($endMarker) + '\b') {
                    $changed = $true; continue
                }
                $out.Add($line)
            }
            if ($changed) {
                [System.IO.File]::WriteAllLines($file.FullName, $out)
                Write-Host "   - cleaned region markers for $Platform in $($file.FullName.Substring($RepoRoot.Length + 1))" -ForegroundColor Green
            }
        } catch {
            $script:step3Success = $false
            Write-Error "[STEP 3] Failed to clean region markers for $Platform in $($file.FullName)"
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

if (-not $android) { Write-Host '-> Removing Android target...'; Remove-Region 'android'; Remove-ModuleDir 'androidApp' } else { Write-Host '-> Cleaning Android region markers...'; Remove-RegionMarkers 'android' }
if (-not $ios)     { Write-Host '-> Removing iOS target...';     Remove-Region 'ios';     Remove-ModuleDir 'iosApp' }     else { Write-Host '-> Cleaning iOS region markers...';     Remove-RegionMarkers 'ios' }
if (-not $web)     { Write-Host '-> Removing Web target...';     Remove-Region 'web';     Remove-ModuleDir 'webApp' }     else { Write-Host '-> Cleaning Web region markers...';     Remove-RegionMarkers 'web' }
if (-not $desktop) { Write-Host '-> Removing Desktop target...'; Remove-Region 'desktop'; Remove-ModuleDir 'desktopApp' } else { Write-Host '-> Cleaning Desktop region markers...'; Remove-RegionMarkers 'desktop' }
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
try {
    Remove-Item -Force '.github/workflows/init.yml' -ErrorAction SilentlyContinue
    Remove-Item -Force 'scripts/init.sh'             -ErrorAction SilentlyContinue
} catch {
    $step5Success = $false
    Write-Error '[STEP 5] Failed to remove init workflow or init.sh'
}
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
