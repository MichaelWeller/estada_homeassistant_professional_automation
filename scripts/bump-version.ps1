[CmdletBinding()]
param(
  [ValidateSet("patch", "minor", "major")]
  [string]$Type = "patch",
  [string]$SetVersion,
  [string]$ReleaseNote = "- Describe changes.",
  [switch]$Commit,
  [switch]$DryRun
)

$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$addonDir = Join-Path $repoRoot "estada_professional_automation"
$configPath = Join-Path $addonDir "config.yaml"
$packagePath = Join-Path $addonDir "package.json"
$changelogPath = Join-Path $addonDir "CHANGELOG.md"

if (-not (Test-Path $configPath)) {
  throw "config.yaml not found at $configPath"
}
if (-not (Test-Path $packagePath)) {
  throw "package.json not found at $packagePath"
}
if (-not (Test-Path $changelogPath)) {
  throw "CHANGELOG.md not found at $changelogPath"
}

function Get-NextVersion {
  param(
    [Parameter(Mandatory = $true)]
    [string]$Current,
    [Parameter(Mandatory = $true)]
    [string]$BumpType
  )

  $parts = $Current.Split(".")
  if ($parts.Length -ne 3) {
    throw "Current version '$Current' is not semver-like (x.y.z)."
  }

  [int]$major = $parts[0]
  [int]$minor = $parts[1]
  [int]$patch = $parts[2]

  switch ($BumpType) {
    "major" { $major += 1; $minor = 0; $patch = 0 }
    "minor" { $minor += 1; $patch = 0 }
    "patch" { $patch += 1 }
    default { throw "Unsupported bump type: $BumpType" }
  }

  return "$major.$minor.$patch"
}

$configContent = Get-Content -Path $configPath -Raw
if ($configContent -notmatch 'version:\s*"([0-9]+\.[0-9]+\.[0-9]+)"') {
  throw "Unable to find version in $configPath"
}
$currentVersion = $Matches[1]

if ([string]::IsNullOrWhiteSpace($SetVersion)) {
  $newVersion = Get-NextVersion -Current $currentVersion -BumpType $Type
} else {
  if ($SetVersion -notmatch '^[0-9]+\.[0-9]+\.[0-9]+$') {
    throw "SetVersion must match x.y.z"
  }
  $newVersion = $SetVersion
}

if ($newVersion -eq $currentVersion) {
  throw "New version is identical to current version ($currentVersion)."
}

Write-Host "Current version: $currentVersion"
Write-Host "New version:     $newVersion"

$configUpdated = $configContent -replace 'version:\s*"[0-9]+\.[0-9]+\.[0-9]+"', "version: `"$newVersion`""

$packageJson = Get-Content -Path $packagePath -Raw | ConvertFrom-Json
$packageJson.version = $newVersion
$packageUpdated = $packageJson | ConvertTo-Json -Depth 100

$changelogContent = Get-Content -Path $changelogPath -Raw
$newHeading = "## $newVersion"
if ($changelogContent -match [regex]::Escape($newHeading)) {
  Write-Host "CHANGELOG already contains heading $newHeading"
  $changelogUpdated = $changelogContent
} else {
  $entry = "## $newVersion`r`n`r`n$ReleaseNote`r`n`r`n"
  if ($changelogContent -match '^# Changelog\r?\n\r?\n') {
    $changelogUpdated = [regex]::Replace(
      $changelogContent,
      '^# Changelog\r?\n\r?\n',
      "# Changelog`r`n`r`n$entry",
      [System.Text.RegularExpressions.RegexOptions]::Multiline
    )
  } else {
    $changelogUpdated = "# Changelog`r`n`r`n$entry$changelogContent"
  }
}

if ($DryRun) {
  Write-Host "Dry run enabled. No files changed."
} else {
  Set-Content -Path $configPath -Value $configUpdated -Encoding UTF8
  Set-Content -Path $packagePath -Value $packageUpdated -Encoding UTF8
  Set-Content -Path $changelogPath -Value $changelogUpdated -Encoding UTF8

  npm --prefix $addonDir install | Out-Null

  Write-Host "Updated files:"
  Write-Host " - $configPath"
  Write-Host " - $packagePath"
  Write-Host " - $changelogPath"
  Write-Host " - $addonDir/package-lock.json"

  if ($Commit) {
    git -C $repoRoot add $configPath $packagePath $changelogPath (Join-Path $addonDir "package-lock.json")
    git -C $repoRoot commit -m "release: $newVersion"
    Write-Host "Created commit: release: $newVersion"
  }
}
