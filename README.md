# fairpage-cli-dist

Public distribution for the [Fairpage](https://fairpage.co) CLI, `fairpage`:
clone a site's draft into a folder, preview it with local changes, push them,
publish.

The source repo stays private. This repo contains **releases only**: prebuilt
binaries with checksums and their signatures, `install.sh`,
`release-signing.pub`, `README.md`, `LICENSE`. No source.

## Install

```sh
curl -fsSL https://raw.githubusercontent.com/softkittens/fairpage-cli-dist/main/install.sh | sh
```

Supported platforms:

- `Linux/x86_64` → `fairpage-linux-x86_64`
- `Linux/aarch64` → `fairpage-linux-arm64`
- `Darwin/arm64` (Apple Silicon) → `fairpage-darwin-arm64`
- `Darwin/x86_64` (Intel) → `fairpage-darwin-x86_64`
- Windows x86_64: download `fairpage-windows-x86_64.exe` from
  [Releases](https://github.com/softkittens/fairpage-cli-dist/releases) and
  put it on your `PATH` as `fairpage.exe`.

Pin a version (also the rollback path):

```sh
FAIRPAGE_VERSION=v0.1.0 sh install.sh
```

Choose install location (default: `/usr/local/bin` if writable, else
`~/.local/bin`):

```sh
FAIRPAGE_PREFIX="$HOME/.local/bin" sh install.sh
```

Every download is verified against its `.sha256` before install.

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
