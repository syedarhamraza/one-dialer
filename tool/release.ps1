<#
.SYNOPSIS
  Bumps the One Dialer version, adds its Changelog entry, builds for Google Play, commits and tags.

.DESCRIPTION
  pubspec.yaml is the one place the version lives:

      version: MAJOR.MINOR.PATCH[-alpha.N|-beta.N]+CODE

  The name (before +) is what users see. CODE (after +) is the Android versionCode;
  every run of this script (except -Debug) raises it by one, so each upload is accepted.

  Run it from a clean working tree, only when you are about to upload to Play Console.
  Day-to-day development stays `flutter run`.

.EXAMPLE
  ./tool/release.ps1 -Bump minor -Pre beta   # 1.0.0         -> 1.1.0-beta.1   (start a feature version in beta)
.EXAMPLE
  ./tool/release.ps1 -Pre beta               # 1.1.0-beta.1  -> 1.1.0-beta.2   (next beta; alpha.N -> beta.1)
.EXAMPLE
  ./tool/release.ps1 -Promote                # 1.1.0-beta.2  -> 1.1.0          (the real release)
.EXAMPLE
  ./tool/release.ps1 -Bump patch             # 1.1.0         -> 1.1.1          (bug-fix release)
.EXAMPLE
  ./tool/release.ps1 -Rebuild                # same name, new build number      (re-upload)
.EXAMPLE
  ./tool/release.ps1 -Debug                  # debug APK of the current version; changes nothing
#>
param(
  [ValidateSet('major', 'minor', 'patch')]
  [string]$Bump,
  [ValidateSet('alpha', 'beta')]
  [string]$Pre,
  [switch]$Promote,
  [switch]$Rebuild,
  [switch]$Debug,
  [ValidateSet('appbundle', 'apk')]
  [string]$Target,
  # Don't pause for release notes (they must already be written).
  [switch]$Yes,
  # Markdown whose "- " or "* " lines become the notes when the Changelog has no entry for
  # this version yet (the release workflow passes the GitHub draft release's text).
  [string]$NotesFile,
  # Bump, commit and tag without building (for trying the script out).
  [switch]$SkipBuild,
  [switch]$Help
)

$ErrorActionPreference = 'Stop'
Set-Location (Split-Path $PSScriptRoot -Parent)

$pubspecPath = 'pubspec.yaml'
$changelogPath = 'lib/core/config/changelog.dart'
# This release's notes for Software update (Play gives none) and the website's "What's new";
# the site is site/ in this repo, so the file is served as one-dialer/changelog.json.
$notesJson = 'site/public/changelog.json'
$utf8 = New-Object System.Text.UTF8Encoding $false

function Show-Usage {
  Write-Host @'

One Dialer release  -  version lives in pubspec.yaml as MAJOR.MINOR.PATCH[-alpha.N|-beta.N]+CODE

  ./tool/release.ps1 -Bump minor -Pre beta   start a new feature version as beta.1
  ./tool/release.ps1 -Bump major|minor|patch new release (add -Pre alpha|beta for a pre-release)
  ./tool/release.ps1 -Pre beta               next beta of the same version (or alpha -> beta)
  ./tool/release.ps1 -Promote                turn the alpha/beta into the real release
  ./tool/release.ps1 -Rebuild                same version, new build number (re-upload)
  ./tool/release.ps1 -Debug [-Target apk]    debug build of the current version (no bump)

  Extra: -Yes (don't pause for release notes), -SkipBuild (bump/commit/tag only)

  MAJOR = big redesigns or breaking changes, MINOR = new features, PATCH = fixes only.
  alpha -> Play "Internal/Closed testing", beta -> "Open testing", no suffix -> "Production".
'@
}

function Fail([string]$message) {
  Write-Host "`n$message" -ForegroundColor Red
  exit 1
}

function Read-Version {
  $line = (Get-Content $pubspecPath | Where-Object { $_ -match '^version:' } | Select-Object -First 1)
  if ($line -notmatch '^version:\s*(\d+)\.(\d+)\.(\d+)(?:-(alpha|beta)\.(\d+))?\+(\d+)\s*$') {
    Fail "pubspec.yaml has '$line', expected version: MAJOR.MINOR.PATCH[-alpha.N|-beta.N]+CODE"
  }
  $preNumber = 0
  if ($Matches[5]) { $preNumber = [int]$Matches[5] }
  return [pscustomobject]@{
    Major = [int]$Matches[1]; Minor = [int]$Matches[2]; Patch = [int]$Matches[3]
    Pre = $Matches[4]; PreNumber = $preNumber; Code = [int]$Matches[6]
  }
}

function Get-Name($v) {
  $name = "$($v.Major).$($v.Minor).$($v.Patch)"
  if ($v.Pre) { $name = "$name-$($v.Pre).$($v.PreNumber)" }
  return $name
}

# Runs git or flutter and returns what they print on stdout; their stderr is shown as text.
# They write harmless warnings there (git's line-ending notes, pub's version list), and under
# 'Stop' Windows PowerShell turns any stderr line into a fatal error as soon as the output is
# redirected or captured (a log file, a pipe, $x = ...). Failures are caught by exit code.
function Invoke-Native([scriptblock]$command) {
  $ErrorActionPreference = 'Continue'
  & $command 2>&1 | ForEach-Object {
    if ($_ -is [System.Management.Automation.ErrorRecord]) { Write-Host $_.ToString() } else { $_ }
  }
}

function Invoke-Checked([string]$what, [scriptblock]$command) {
  Invoke-Native $command
  if ($LASTEXITCODE -ne 0) { Fail "$what failed (exit $LASTEXITCODE)." }
}

if ($Help) { Show-Usage; exit 0 }

$current = Read-Version
$sha = (Invoke-Native { git rev-parse --short HEAD }).Trim()

# --- Debug build: nothing changes -------------------------------------------------
if ($Debug) {
  if (-not $Target) { $Target = 'apk' }
  if (Invoke-Native { git status --porcelain }) { $sha = "$sha-dirty" }
  Write-Host "Debug $Target of $(Get-Name $current)+$($current.Code) from $sha"
  Invoke-Checked 'flutter build' { flutter build $Target --debug "--dart-define=GIT_SHA=$sha" }
  exit 0
}

# --- Work out the next version ----------------------------------------------------
$modes = @($Bump, $Promote, $Rebuild) | Where-Object { $_ }
if ($modes.Count -eq 0 -and $Pre) { $modes = @('pre') }
if ($modes.Count -ne 1 -or ($Pre -and ($Promote -or $Rebuild))) { Show-Usage; exit 1 }

$next = $current.PSObject.Copy()
$next.Code = $current.Code + 1

if ($Bump) {
  switch ($Bump) {
    'major' { $next.Major++; $next.Minor = 0; $next.Patch = 0 }
    'minor' { $next.Minor++; $next.Patch = 0 }
    'patch' { $next.Patch++ }
  }
  $next.Pre = $null; $next.PreNumber = 0
  if ($Pre) { $next.Pre = $Pre; $next.PreNumber = 1 }
}
elseif ($Promote) {
  if (-not $current.Pre) { Fail "$(Get-Name $current) is already a release. Use -Bump to start the next version." }
  $next.Pre = $null; $next.PreNumber = 0
}
elseif ($Pre) {
  if (-not $current.Pre) { Fail "$(Get-Name $current) is a release. Start the next one with -Bump patch|minor|major -Pre $Pre." }
  if ($current.Pre -eq $Pre) { $next.PreNumber++ }
  elseif ($current.Pre -eq 'alpha' -and $Pre -eq 'beta') { $next.Pre = 'beta'; $next.PreNumber = 1 }
  else { Fail "Can't go from beta back to alpha. Use -Pre beta or -Promote." }
}
# -Rebuild keeps the name.

$oldName = Get-Name $current
$newName = Get-Name $next
$newVersion = "$newName+$($next.Code)"

# --- Safety checks ----------------------------------------------------------------
if (Invoke-Native { git status --porcelain }) { Fail 'Commit or stash your changes first; a release is built from a clean tree.' }
$branch = (Invoke-Native { git rev-parse --abbrev-ref HEAD }).Trim()
if ($branch -ne 'main') { Write-Host "Note: releasing from '$branch', not main." -ForegroundColor Yellow }
if (Invoke-Native { git tag --list "v$newName" }) {
  if (-not $Rebuild) { Fail "Tag v$newName already exists." }
}
if (-not $SkipBuild -and -not (Test-Path 'android/key.properties')) {
  # Without it Gradle falls back to the DEBUG key, which Google Play rejects after the
  # version code and tag are already used up.
  Fail 'android/key.properties is missing, so the release would be signed with the DEBUG key. See docs/play-release.md to set up your upload key (or use -SkipBuild).'
}

# Nothing has changed yet, so a failure here leaves the tree untouched.
Write-Host 'Checking the code (flutter analyze, flutter test)...'
Invoke-Checked 'flutter analyze' { flutter analyze }
Invoke-Checked 'flutter test' { flutter test --reporter failures-only }

Write-Host "`n$oldName+$($current.Code)  ->  $newVersion`n" -ForegroundColor Cyan

# --- pubspec.yaml -----------------------------------------------------------------
$pubspec = [System.IO.File]::ReadAllText((Resolve-Path $pubspecPath), $utf8)
$pubspec = [regex]::Replace($pubspec, '(?m)^version:.*?(\r?)$', "version: $newVersion`$1")
[System.IO.File]::WriteAllText((Resolve-Path $pubspecPath), $pubspec, $utf8)

# --- Changelog ---------------------------------------------------------------------
$month = (Get-Date).ToString('MMM yyyy', [Globalization.CultureInfo]::InvariantCulture)
$changelog = [System.IO.File]::ReadAllText((Resolve-Path $changelogPath), $utf8)
$nl = "`n"
if ($changelog.Contains("`r`n")) { $nl = "`r`n" }
# The date is a quoted string or, for notes written ahead, Changelog.inDevelopment.
$entryPattern = "version: '" + [regex]::Escape($newName) + "',(\s*)date: (?:'[^']*'|(?:Changelog\.)?inDevelopment)"
if ([regex]::IsMatch($changelog, $entryPattern)) {
  # The entry exists (e.g. written while "In development"): stamp this month.
  $changelog = [regex]::Replace($changelog, $entryPattern, "version: '$newName',`$1date: '$month'")
}
else {
  $changes = @("'TODO: what changed'")
  if ($NotesFile) {
    $changes = @(Get-Content $NotesFile -Encoding UTF8 | ForEach-Object {
        if ($_ -match '^\s*[*-]\s+(\S.*?)\s*$') { "'" + $Matches[1].Replace('\', '\\').Replace("'", "\'").Replace('$', '\$') + "'" }
      })
    if (-not $changes) {
      Invoke-Native { git checkout -- $pubspecPath } | Out-Null
      Fail "No '- ' lines in $NotesFile, so there are no release notes for $newName."
    }
  }
  $entry = "    ChangelogEntry($nl      version: '$newName',$nl      date: '$month',$nl      changes: [$nl" + (($changes | ForEach-Object { "        $_,$nl" }) -join '') + "      ],$nl    ),$nl"
  $marker = 'static const List<ChangelogEntry> entries = ['
  $at = $changelog.IndexOf($marker)
  if ($at -lt 0) { Fail "Couldn't find the entries list in $changelogPath." }
  $insertAt = $changelog.IndexOf($nl, $at) + $nl.Length
  $changelog = $changelog.Insert($insertAt, $entry)
}
[System.IO.File]::WriteAllText((Resolve-Path $changelogPath), $changelog, $utf8)

function Restore-Files {
  Invoke-Native { git checkout -- $pubspecPath $changelogPath $notesJson } | Out-Null
}

if ((Get-Content $changelogPath -Raw).Contains("'TODO: what changed'")) {
  if ($Yes) { Restore-Files; Fail "Release notes for $newName are still TODO. Write them in $changelogPath first." }
  Write-Host "Write the release notes for $newName in $changelogPath (replace the TODO line)," -ForegroundColor Yellow
  Read-Host 'then save the file and press Enter'
  if ((Get-Content $changelogPath -Raw).Contains("'TODO: what changed'")) {
    Restore-Files
    Fail 'The release notes are still TODO, so nothing was changed. Run the script again when ready.'
  }
}

# The version tests check pubspec and the Changelog agree.
Invoke-Checked 'Version check' { flutter test test/app_version_test.dart --reporter failures-only }
Invoke-Checked 'Export release notes' { dart run tool/export_changelog.dart $newName $next.Code $notesJson }

# --- Commit, build, tag -----------------------------------------------------------
Invoke-Checked 'git add' { git add $pubspecPath $changelogPath $notesJson }
Invoke-Checked 'git commit' { git commit -q -m "chore(release): $newName ($($next.Code))" }
$sha = (Invoke-Native { git rev-parse --short HEAD }).Trim()

if (-not $SkipBuild) {
  if (-not $Target) { $Target = 'appbundle' }
  # Dart code is obfuscated; its symbols go to symbols/<version> (git-ignored, kept per
  # release) and are needed to read Crashlytics stack traces.
  $symbolsDir = "symbols/$newVersion"
  # Crashlytics never deobfuscates exception messages ("Field '_Dgb@...' has not been
  # initialized"), so keep the rename map to decode them. It sits beside the symbols folder,
  # not in it, so the upload below never sees it; gen_snapshot needs an absolute path.
  $obfuscationMap = Join-Path (Get-Location) "symbols/$newVersion.obfuscation-map.json"
  # One universal APK, so its versionCode matches the bundle's (split APKs add 1000 * ABI).
  $buildArgs = @($Target, '--release', '--obfuscate', "--split-debug-info=$symbolsDir",
    "--extra-gen-snapshot-options=--save-obfuscation-map=$obfuscationMap", "--dart-define=GIT_SHA=$sha")
  # x86_64 is only for emulators; the bundle keeps it since Play serves per-ABI splits anyway.
  if ($Target -eq 'apk') { $buildArgs += '--target-platform=android-arm,android-arm64' }
  Write-Host "`nBuilding $Target for $newVersion ($sha)..."
  Invoke-Native { flutter build @buildArgs }
  if ($LASTEXITCODE -ne 0) {
    Invoke-Native { git reset -q --soft HEAD~1 }
    Fail 'The build failed. The release commit was undone; your version changes are still staged.'
  }

  # Upload the Dart symbols so Crashlytics can deobfuscate. A failure only warns: the build
  # is done and the symbols stay in $symbolsDir for a manual upload.
  $appId = (Get-Content 'android/app/google-services.json' -Raw | ConvertFrom-Json).client[0].client_info.mobilesdk_app_id
  $uploadCommand = "npx --yes firebase-tools crashlytics:symbols:upload --app=$appId $symbolsDir"
  Write-Host "`nUploading Dart symbols to Crashlytics..."
  try { Invoke-Expression $uploadCommand } catch { $global:LASTEXITCODE = 1 }
  if ($LASTEXITCODE -ne 0) {
    Write-Host 'Symbol upload failed (run `npx firebase-tools login` once). Upload them later with:' -ForegroundColor Yellow
    Write-Host "  $uploadCommand" -ForegroundColor Yellow
  }

  # One Dialer Recorder (companion/): the sideloaded call recorder, shared from the website, never Play.
  Write-Host "`nBuilding One Dialer Recorder..."
  $gradlew = 'companion/gradlew'
  if ($env:OS -eq 'Windows_NT') { $gradlew = 'companion/gradlew.bat' }
  Invoke-Native { & $gradlew -p companion assembleRelease -q }
  if ($LASTEXITCODE -ne 0) {
    Write-Host 'The recorder build failed. Build it later with: companion/gradlew.bat -p companion assembleRelease' -ForegroundColor Yellow
  }
}

if (-not (Invoke-Native { git tag --list "v$newName" })) { Invoke-Checked 'git tag' { git tag -a "v$newName" -m "One Dialer $newName" } }

# The release workflow's later steps (Play upload, GitHub release) read these.
if ($env:GITHUB_OUTPUT) { Add-Content $env:GITHUB_OUTPUT "name=$newName`ncode=$($next.Code)`npre=$($next.Pre)" }

# --- Next steps -------------------------------------------------------------------
$track = 'Production'
if ($next.Pre -eq 'beta') { $track = 'Open testing' }
if ($next.Pre -eq 'alpha') { $track = 'Internal or Closed testing' }
Write-Host "`nDone: One Dialer $newName (build $($next.Code))" -ForegroundColor Green
if (-not $SkipBuild) {
  if ($Target -eq 'appbundle') {
    Write-Host '  1. Upload build/app/outputs/bundle/release/app-release.aab'
    Write-Host "     to Play Console > $track."
  }
  else { Write-Host '  1. Install or share build/app/outputs/flutter-apk/app-release.apk (Play needs the .aab).' }
}
if (-not $SkipBuild) { Write-Host '     Recorder (website only): companion/app/build/outputs/apk/release/app-release.apk' }
Write-Host '  2. Push the release commit and tag:  git push --follow-tags'
Write-Host "     (the website redeploys from it, so Software update shows the notes)."
