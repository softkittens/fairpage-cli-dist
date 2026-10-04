#!/bin/sh
# fairpage-cli installer.
#   curl -fsSL https://raw.githubusercontent.com/softkittens/fairpage-cli-dist/main/install.sh | sh
#   FAIRPAGE_VERSION=v0.1.0 sh install.sh            # pin (this is the rollback path)
#   FAIRPAGE_PREFIX="$HOME/.local/bin" sh install.sh
set -eu

REPO="softkittens/fairpage-cli-dist"

os=$(uname -s); arch=$(uname -m)
case "$os/$arch" in
  Linux/x86_64)                asset="fairpage-linux-x86_64";  platform="Linux (x86_64)" ;;
  Linux/aarch64 | Linux/arm64) asset="fairpage-linux-arm64";   platform="Linux (arm64)" ;;
  Darwin/arm64)                asset="fairpage-darwin-arm64";  platform="macOS (Apple Silicon)" ;;
  Darwin/x86_64)               asset="fairpage-darwin-x86_64"; platform="macOS (Intel)" ;;
  *)
    echo "No prebuilt fairpage binary for $os/$arch." >&2
    echo "Supported: Linux/x86_64, Linux/arm64, Darwin/arm64, Darwin/x86_64." >&2
    echo "Windows: run install.ps1 in PowerShell, as https://github.com/$REPO says." >&2
    exit 1 ;;
esac

if [ -n "${FAIRPAGE_VERSION:-}" ]; then
  case "$FAIRPAGE_VERSION" in
    v*) ;;
    *) FAIRPAGE_VERSION="v$FAIRPAGE_VERSION" ;;
  esac
  base="https://github.com/$REPO/releases/download/$FAIRPAGE_VERSION"
else
  base="https://github.com/$REPO/releases/latest/download"
fi

prefix="${FAIRPAGE_PREFIX:-}"
if [ -z "$prefix" ]; then
  if [ -w /usr/local/bin ]; then prefix=/usr/local/bin; else prefix="$HOME/.local/bin"; fi
fi
mkdir -p "$prefix"

tmp=$(mktemp -d "$prefix/.fairpage-install.XXXXXX")
trap 'rm -rf "$tmp"' EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

if [ -t 1 ] && [ -z "${NO_COLOR:-}" ]; then
  bold=$(printf '\033[1m'); reset=$(printf '\033[0m')
else
  bold=""; reset=""
fi

echo "Downloading the fairpage CLI${FAIRPAGE_VERSION:+ $FAIRPAGE_VERSION} for $platform..."
curl -fsSL -S "$base/$asset"        -o "$tmp/fairpage"
curl -fsSL -S "$base/$asset.sha256" -o "$tmp/sum"

expected=$(awk '{print $1}' "$tmp/sum")
if command -v sha256sum >/dev/null 2>&1; then
  actual=$(sha256sum "$tmp/fairpage" | awk '{print $1}')
elif command -v shasum >/dev/null 2>&1; then
  actual=$(shasum -a 256 "$tmp/fairpage" | awk '{print $1}')
else
  echo "Error: neither sha256sum nor shasum is available to verify the download." >&2
  exit 1
fi

if [ "$expected" != "$actual" ]; then
  echo "Checksum mismatch. Expected $expected, got $actual." >&2
  exit 1
fi

chmod 755 "$tmp/fairpage"
if [ "$os" = "Darwin" ]; then
  # curl does not set the quarantine attribute; a browser download would.
  xattr -d com.apple.quarantine "$tmp/fairpage" 2>/dev/null || true
fi

# Verify the new binary runs before replacing any existing installation.
# --version prints "fairpage version v0.1.0".
new=$("$tmp/fairpage" --version); new=${new##* }
old=""
if [ -x "$prefix/fairpage" ]; then
  old=$("$prefix/fairpage" --version 2>/dev/null || true); old=${old##* }
fi
mv "$tmp/fairpage" "$prefix/fairpage"

if [ -n "$old" ] && [ "$old" != "$new" ]; then
  echo "Updated fairpage from $old to $new in $prefix/fairpage"
elif [ -n "$old" ]; then
  echo "Reinstalled fairpage $new in $prefix/fairpage"
else
  echo "Installed fairpage $new to $prefix/fairpage"
fi

case ":$PATH:" in
  *":$prefix:"*) ;;
  *)
    line="export PATH=\"$prefix:\$PATH\""
    case "${SHELL##*/}" in
      fish) add="fish_add_path $prefix" ;;
      zsh)  add="echo '$line' >> ~/.zshrc" ;;
      bash) if [ "$os" = Darwin ]; then add="echo '$line' >> ~/.bash_profile"; else add="echo '$line' >> ~/.bashrc"; fi ;;
      *)    add="echo '$line' >> ~/.profile" ;;
    esac
    printf '\n%s is not on your PATH. Add it, then open a new terminal:\n  %s\n' "$prefix" "$add" ;;
esac

# A first install says what to run next; an update says only what changed.
if [ -z "$old" ]; then
  printf '\nGet started:\n'
  printf '  %sfairpage login%s   log in to your Fairpage account\n' "$bold" "$reset"
  printf '  %sfairpage clone%s   download one of your sites into a folder\n' "$bold" "$reset"
  printf '  %sfairpage dev%s     preview it as you edit, then %sfairpage push%s\n' "$bold" "$reset" "$bold" "$reset"
  printf '\nEvery command: fairpage --help. Guide: https://fairpage.co/developers\n'
fi
