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
    # Accept as string so the script works with `powershell -File`
    # (which always passes args as strings) and with friendly forms like
    # `-IncludeAndroid:true`, `-IncludeAndroid yes`, `-IncludeAndroid 1`, or `-IncludeAndroid:$true`.
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

function Read-BoolIfNull {
    param([string]$Current, [string]$Prompt)
    $parsed = ConvertTo-NullableBool $Current
    if ($null -eq $parsed) {
        $ans = Read-Host "$Prompt [Y/n]"
        switch -Regex ($ans) {
            '^(n|no|false)$' { return $false }
            default          { return $true }
        }
    }
    return $parsed
}

$ProjectName    = Read-StringIfEmpty $ProjectName 'Project name (e.g. MyApp)'
$PackageName    = Read-StringIfEmpty $PackageName 'Package name (e.g. com.myapp)'
$IncludeAndroid = Read-BoolIfNull    $IncludeAndroid 'Include Android target?'
$IncludeIos     = Read-BoolIfNull    $IncludeIos     'Include iOS target?'
$IncludeWeb     = Read-BoolIfNull    $IncludeWeb     'Include Web target?'
$IncludeDesktop = Read-BoolIfNull    $IncludeDesktop 'Include Desktop target?'

# ---- Validation ----
if ($ProjectName -notmatch '^[A-Za-z][A-Za-z0-9_-]*$') {
    Write-Error 'project_name must start with a letter and contain only [A-Za-z0-9_-].'
    exit 1
}
if ($PackageName -notmatch '^[a-z][a-z0-9_]*(\.[a-z][a-z0-9_]*)+$') {
    Write-Error 'package_name must be a valid dotted lowercase Kotlin package (e.g. com.myapp).'
    exit 1
}
if (-not ($IncludeAndroid -or $IncludeIos -or $IncludeWeb -or $IncludeDesktop)) {
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
Write-Host "   android=$IncludeAndroid  ios=$IncludeIos  web=$IncludeWeb  desktop=$IncludeDesktop"
Write-Host ""

function Get-RepoTextFiles {
    Get-ChildItem -Recurse -File -Force | Where-Object {
        $_.FullName -notmatch '\\(\.git|\.gradle|build|\.idea)\\' -and
        $_.Length -lt 5MB
    }
}

# ---- 1. Rewrite placeholders ----
Write-Host ' Rewriting {{PROJECT_NAME}} / {{PACKAGE_NAME}} / {{PACKAGE_PATH}} placeholders...'
foreach ($file in Get-RepoTextFiles) {
    try {
        $content = [System.IO.File]::ReadAllText($file.FullName)
    } catch {
        continue
    }
    if ($content -match '\{\{PROJECT_NAME\}\}|\{\{PACKAGE_NAME\}\}|\{\{PACKAGE_PATH\}\}') {
        $new = $content.Replace('{{PROJECT_NAME}}', $ProjectName).
                        Replace('{{PACKAGE_NAME}}', $PackageName).
                        Replace('{{PACKAGE_PATH}}', $PackagePath)
        [System.IO.File]::WriteAllText($file.FullName, $new)
    }
}

# ---- 2. Rewrite Kotlin package declarations + rename directories ----
Write-Host " Renaming Kotlin package directories org.company.app -> $PackageName ..."
Get-ChildItem -Recurse -File -Filter *.kt | Where-Object {
    $_.FullName -notmatch '\\(build|\.gradle)\\'
} | ForEach-Object {
    $content = [System.IO.File]::ReadAllText($_.FullName)
    if ($content.Contains('org.company.app')) {
        [System.IO.File]::WriteAllText($_.FullName, $content.Replace('org.company.app', $PackageName))
    }
}

foreach ($module in @('sharedUI', 'androidApp', 'desktopApp', 'webApp', 'iosApp')) {
    if (-not (Test-Path $module)) { continue }
    $sourceRoots = Get-ChildItem -Path "$module/src" -Directory -ErrorAction SilentlyContinue |
        ForEach-Object { Join-Path $_.FullName 'kotlin' } |
        Where-Object { Test-Path $_ }
    foreach ($srcRoot in $sourceRoots) {
        $oldPkg = Join-Path $srcRoot 'org/company/app'
        if (-not (Test-Path $oldPkg)) { continue }
        $newPkg = Join-Path $srcRoot $PackagePath
        New-Item -ItemType Directory -Force -Path $newPkg | Out-Null
        Get-ChildItem -Path $oldPkg -Force | ForEach-Object {
            Move-Item -Force -Path $_.FullName -Destination $newPkg
        }
        Remove-Item -Recurse -Force (Join-Path $srcRoot 'org')
    }
}

# ---- 3. Prune unselected platforms ----
function Remove-Region {
    param([string]$Platform)
    $startMarker = "// region $Platform"
    $endMarker   = "// endregion $Platform"
    $files = Get-ChildItem -Recurse -File -Include 'build.gradle.kts','settings.gradle.kts' |
        Where-Object { $_.FullName -notmatch '\\(build|\.gradle)\\' }
    foreach ($file in $files) {
        $lines = [System.IO.File]::ReadAllLines($file.FullName)
        $out = New-Object System.Collections.Generic.List[string]
        $inside = $false
        foreach ($line in $lines) {
            if ($line -match [Regex]::Escape($startMarker) + '\b') { $inside = $true; continue }
            if ($line -match [Regex]::Escape($endMarker) + '\b')   { $inside = $false; continue }
            if (-not $inside) { $out.Add($line) }
        }
        [System.IO.File]::WriteAllLines($file.FullName, $out)
    }
}

function Remove-ModuleDir {
    param([string]$Module)
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
}

if (-not $IncludeAndroid) { Write-Host '-> Removing Android target...'; Remove-Region 'android'; Remove-ModuleDir 'androidApp' }
if (-not $IncludeIos)     { Write-Host '-> Removing iOS target...';     Remove-Region 'ios';     Remove-ModuleDir 'iosApp' }
if (-not $IncludeWeb)     { Write-Host '-> Removing Web target...';     Remove-Region 'web';     Remove-ModuleDir 'webApp' }
if (-not $IncludeDesktop) { Write-Host '-> Removing Desktop target...'; Remove-Region 'desktop'; Remove-ModuleDir 'desktopApp' }

# ---- 4. Write .template.config ----
Write-Host ' Writing .template.config...'
$templateConfig = @(
    "# Generated by scripts/init.ps1 - do not edit by hand.",
    "PROJECT_NAME=$ProjectName",
    "PACKAGE_NAME=$PackageName",
    "INCLUDE_ANDROID=$($IncludeAndroid.ToString().ToLower())",
    "INCLUDE_IOS=$($IncludeIos.ToString().ToLower())",
    "INCLUDE_WEB=$($IncludeWeb.ToString().ToLower())",
    "INCLUDE_DESKTOP=$($IncludeDesktop.ToString().ToLower())"
) -join "`n"
[System.IO.File]::WriteAllText('.template.config', $templateConfig + "`n")

# ---- 5. Self-destruct: remove init workflow + sibling init scripts ----
Write-Host ' Removing init workflow + scripts/init.* ...'
Remove-Item -Force '.github/workflows/init.yml' -ErrorAction SilentlyContinue
Remove-Item -Force 'scripts/init.sh'             -ErrorAction SilentlyContinue
$selfPath = $MyInvocation.MyCommand.Path

# ---- 6. Run team.install ----
if ($SkipInstall) {
    Write-Host '>> Skipping team.install (-SkipInstall).'
} else {
    Write-Host ''
    Write-Host '>> Running scripts/team.install.ps1...'
    # Prefer PowerShell 7+ (`pwsh`) when available, otherwise fall back to Windows PowerShell 5.1.
    $psHost = if (Get-Command pwsh -ErrorAction SilentlyContinue) { 'pwsh' } else { 'powershell' }
    & $psHost -NoProfile -File 'scripts/team.install.ps1'
}

# Remove this script last so it stays valid through execution.
if ($selfPath -and (Test-Path $selfPath)) {
    Remove-Item -Force $selfPath -ErrorAction SilentlyContinue
}

Write-Host ''
Write-Host " Template initialized as $ProjectName ($PackageName). Review the changes and commit." -ForegroundColor Green

