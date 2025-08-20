#!/usr/bin/env bash
set -euo pipefail

cd usdtg

echo ">>> Zinciri build et"
ignite chain build

echo ">>> Local zinciri başlat (ilk kez uzun sürebilir)"
# Aşağıdaki serve, config.yml'deki faucet ve accounts'u uygular
ignite chain serve --reset-once
