# fairpage-cli installer for Windows, in Windows PowerShell 5.1 or PowerShell 7.
#   powershell -c "irm https://raw.githubusercontent.com/softkittens/fairpage-cli-dist/main/install.ps1 | iex"
#   $env:FAIRPAGE_VERSION = "v0.1.0"; irm https://raw.githubusercontent.com/softkittens/fairpage-cli-dist/main/install.ps1 | iex
#     (pin a version; this is the rollback path)
#   $env:FAIRPAGE_PREFIX = "C:\tools\fairpage"; irm https://raw.githubusercontent.com/softkittens/fairpage-cli-dist/main/install.ps1 | iex
#
# fairpage.exe goes to %LOCALAPPDATA%\Programs\fairpage unless FAIRPAGE_PREFIX
# names another folder, and that folder is added to the user's PATH.
#
# Run through iex, the script must not call exit, which would close the
# window it runs in; it throws instead, which ends the script and leaves the
# window open.

& {
  $ErrorActionPreference = 'Stop'
  # Windows PowerShell 5.1 redraws a progress bar per chunk, which makes a
  # download several times slower.
  $ProgressPreference = 'SilentlyContinue'
  # GitHub answers only TLS 1.2 and later; older Windows PowerShell offers
  # less by default.
  [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12

  $repo = 'softkittens/fairpage-cli-dist'
  $asset = 'fairpage-windows-x86_64.exe'

  # PROCESSOR_ARCHITEW6432 is set when 32-bit PowerShell runs on 64-bit
  # Windows, and then names the machine's architecture.
  $arch = $env:PROCESSOR_ARCHITEW6432
  if (-not $arch) { $arch = $env:PROCESSOR_ARCHITECTURE }
  switch ($arch) {
    'AMD64' { }
    'ARM64' { Write-Host 'Windows on ARM: installing the x86_64 build, which Windows runs under emulation.' }
    default { throw "No prebuilt fairpage binary for Windows/$arch. Supported: x86_64, and ARM64 through emulation." }
  }

  $version = $env:FAIRPAGE_VERSION
  if ($version) {
    if (-not $version.StartsWith('v')) { $version = "v$version" }
    $base = "https://github.com/$repo/releases/download/$version"
  } else {
    $base = "https://github.com/$repo/releases/latest/download"
  }

  $prefix = $env:FAIRPAGE_PREFIX
  if (-not $prefix) { $prefix = Join-Path $env:LOCALAPPDATA 'Programs\fairpage' }
  New-Item -ItemType Directory -Force -Path $prefix | Out-Null

  # Downloaded next to its destination, so the final move stays on one volume.
  $tmp = Join-Path $prefix ('.fairpage-install.' + [IO.Path]::GetRandomFileName())
  New-Item -ItemType Directory -Path $tmp | Out-Null
  try {
    $exe = Join-Path $tmp 'fairpage.exe'
    $sum = Join-Path $tmp 'sum'
    $pinned = if ($version) { " $version" } else { '' }
    Write-Host "Downloading the fairpage CLI$pinned for Windows (x86_64)..."
    Invoke-WebRequest -UseBasicParsing -Uri "$base/$asset" -OutFile $exe
    Invoke-WebRequest -UseBasicParsing -Uri "$base/$asset.sha256" -OutFile $sum

    $expected = ((Get-Content -Raw $sum).Trim() -split '\s+')[0]
    $actual = (Get-FileHash -Algorithm SHA256 $exe).Hash
    # -ne compares strings without case: Get-FileHash answers in upper case.
    if ($expected -ne $actual) { throw "Checksum mismatch. Expected $expected, got $actual." }

    Unblock-File $exe
    # Verify the new binary runs before replacing any existing installation.
    # --version prints "fairpage version v0.1.0".
    $new = & $exe --version
    if ($LASTEXITCODE -ne 0) { throw 'The downloaded fairpage.exe did not run.' }
    $new = ($new -split ' ')[-1]

    # Windows refuses to overwrite a running .exe but lets it be renamed: the
    # old one moves aside, and is deleted now or by the next install.
    $target = Join-Path $prefix 'fairpage.exe'
    $previous = ''
    if (Test-Path $target) {
      try { $previous = ((& $target --version) -split ' ')[-1] } catch { }
    }
    $old = "$target.old"
    Remove-Item -Force -ErrorAction SilentlyContinue $old
    if (Test-Path $target) { Move-Item -Force $target $old }
    try {
      Move-Item $exe $target
    } catch {
      if (Test-Path $old) { Move-Item $old $target }
      throw
    }
    Remove-Item -Force -ErrorAction SilentlyContinue $old
  } finally {
    Remove-Item -Recurse -Force -ErrorAction SilentlyContinue $tmp
  }
  if ($previous -and $previous -ne $new) {
    Write-Host "Updated fairpage from $previous to $new in $target"
  } elseif ($previous) {
    Write-Host "Reinstalled fairpage $new in $target"
  } else {
    Write-Host "Installed fairpage $new to $target"
  }

  # The user's PATH is read from the registry unexpanded and written back as
  # an expandable string: through [Environment] the entries written as
  # %USERPROFILE%\... would come back expanded and be frozen that way.
  $key = Get-Item 'HKCU:\Environment'
  $entries = @($key.GetValue('Path', '', 'DoNotExpandEnvironmentNames') -split ';' | Where-Object { $_ })
  if ($entries -notcontains $prefix) {
    Set-ItemProperty -Path 'HKCU:\Environment' -Name Path -Type ExpandString -Value ((@($entries) + $prefix) -join ';')
    # A registry write announces nothing; setting a variable through .NET
    # sends the WM_SETTINGCHANGE that makes new terminals read the new PATH.
    [Environment]::SetEnvironmentVariable('FAIRPAGE_INSTALL', '1', 'User')
    [Environment]::SetEnvironmentVariable('FAIRPAGE_INSTALL', $null, 'User')
    Write-Host "Added $prefix to your PATH. Open a new terminal to run fairpage."
  }
  if (@($env:Path -split ';') -notcontains $prefix) { $env:Path = "$env:Path;$prefix" }

  # A first install says what to run next; an update says only what changed.
  if (-not $previous) {
    Write-Host ''
    Write-Host 'Get started:'
    Write-Host '  fairpage login   log in to your Fairpage account'
    Write-Host '  fairpage clone   download one of your sites into a folder'
    Write-Host '  fairpage dev     preview it as you edit, then fairpage push'
    Write-Host ''
    Write-Host 'Every command: fairpage --help. Guide: https://fairpage.co/developers'
  }
}
