#!/usr/bin/env bash
set -euo pipefail

APP=usdtg
DIR="$APP"
if [ -d "$DIR" ]; then
  echo "Zincir klasörü zaten var: $DIR"
else
  echo ">>> Ignite ile zincir iskeleti oluşturuluyor..."
  ignite scaffold chain $APP --address-prefix usdtg --no-module || ignite scaffold chain $APP --address-prefix usdtg
fi

echo ">>> config.yml yerleştiriliyor"
cp -f ../config/config.yml "$DIR/config.yml"

echo ">>> Modüller güncellenebilir. Şimdilik bank, staking, gov default."
echo "OK: İskelet hazır → cd $DIR"
