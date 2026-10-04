# fairpage-cli-dist

Public distribution for the [Fairpage](https://fairpage.co) CLI, `fairpage`:
clone a site's draft into a folder, preview it with local changes, push them,
publish.

The source repo stays private. This repo contains **releases only**: prebuilt
binaries with checksums and their signatures, `install.sh`, `install.ps1`,
`release-signing.pub`, `README.md`, `LICENSE`. No source.

## Install

macOS and Linux:

```sh
curl -fsSL https://raw.githubusercontent.com/softkittens/fairpage-cli-dist/main/install.sh | sh
```

Windows, in PowerShell or a command prompt:

```powershell
powershell -c "irm https://raw.githubusercontent.com/softkittens/fairpage-cli-dist/main/install.ps1 | iex"
```

Supported platforms:

- `Linux/x86_64` → `fairpage-linux-x86_64`
- `Linux/aarch64` → `fairpage-linux-arm64`
- `Darwin/arm64` (Apple Silicon) → `fairpage-darwin-arm64`
- `Darwin/x86_64` (Intel) → `fairpage-darwin-x86_64`
- Windows x86_64 → `fairpage-windows-x86_64.exe`, installed as `fairpage.exe`
  in `%LOCALAPPDATA%\Programs\fairpage`, which is added to your user `PATH`.
  Windows on ARM runs it under emulation.

Pin a version (also the rollback path):

```sh
FAIRPAGE_VERSION=v0.1.0 sh install.sh
```

```powershell
$env:FAIRPAGE_VERSION = "v0.1.0"; irm https://raw.githubusercontent.com/softkittens/fairpage-cli-dist/main/install.ps1 | iex
```

Choose install location (default: `/usr/local/bin` if writable, else
`~/.local/bin`; on Windows `%LOCALAPPDATA%\Programs\fairpage`):

```sh
FAIRPAGE_PREFIX="$HOME/.local/bin" sh install.sh
```

```powershell
$env:FAIRPAGE_PREFIX = "C:\tools\fairpage"; irm https://raw.githubusercontent.com/softkittens/fairpage-cli-dist/main/install.ps1 | iex
```

Every download is verified against its `.sha256` before install, and the new
binary has to run before it replaces an installed one.

## Update

```sh
fairpage update
```

installs the latest release, only when the signature on its `.sha256`
verifies with the public key compiled into `fairpage`, the download matches
the checksum, and the new binary runs. To pin or roll back, run `install.sh`
or `install.ps1` with `FAIRPAGE_VERSION`. `fairpage dev` says when a newer
release is out, checking at most once a day; `FAIRPAGE_NO_UPDATE_CHECK=1`
turns that off.

In WSL, use `install.sh` and keep the site in the Linux file system
(`~/...`, not `/mnt/c/...`): changes made by Windows programs to files under
`/mnt/c` reach Linux without file events, so `fairpage dev` would not reload.

## Verify a signature

Each `.sha256` is signed with Ed25519; the signature is base64 in
`<asset>.sha256.sig`. With OpenSSL 3 (`brew install openssl@3` on macOS,
whose own `openssl` is LibreSSL):

```sh
base64 -d fairpage-linux-x86_64.sha256.sig > sig.bin
openssl pkeyutl -verify -pubin -inkey release-signing.pub -rawin \
  -in fairpage-linux-x86_64.sha256 -sigfile sig.bin
```

## Get started

```sh
fairpage login
fairpage clone
fairpage dev
```

`fairpage --help` lists every command; `fairpage docs` prints the reference
for building sites.

## Releases

See [Releases](https://github.com/softkittens/fairpage-cli-dist/releases) for
binaries, checksums, signatures, and per-version notes. Tags are
`v<major>.<minor>.<patch>`, and `fairpage --version` prints the tag it was
built from.
