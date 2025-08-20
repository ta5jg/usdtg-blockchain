#!/usr/bin/env bash
set -euo pipefail

if [ ! -f buf.yaml ]; then
  echo ">>> buf mod init"
  buf mod init
fi

echo ">>> buf lint"
buf lint

echo ">>> buf generate"
buf generate

echo "OK"
