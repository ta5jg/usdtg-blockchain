#!/usr/bin/env bash
set -euo pipefail

echo ">>> [1/3] Xcode Command Line Tools (gerekirse)"
if ! xcode-select -p >/dev/null 2>&1; then
  xcode-select --install || true
fi

echo ">>> Homebrew (varsa atlar)"
if ! command -v brew >/dev/null 2>&1; then
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

echo ">>> Go, buf, jq, make, git kurulumu"
brew install go@1.22 jq buf make git || true

# Go PATH
if ! grep -q 'export GOPATH' ~/.zprofile 2>/dev/null; then
  cat >> ~/.zprofile <<'EOF'
export GOPATH="$HOME/go"
export GOROOT="$(brew --prefix go@1.22)/libexec"
export PATH="$PATH:$GOPATH/bin:$GOROOT/bin"
EOF
fi
source ~/.zprofile || true

echo ">>> Ignite CLI kurulumu"
if ! command -v ignite >/dev/null 2>&1; then
  curl -L https://get.ignite.com/cli! | bash
  sudo mv ignite /usr/local/bin/
fi

echo ">>> Sürümler"
go version
ignite version || true
buf --version || true
jq --version || true

echo "OK: Önkoşullar hazır."
