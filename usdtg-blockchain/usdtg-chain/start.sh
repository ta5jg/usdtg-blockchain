#!/bin/bash

echo "🚀 USDTg Blockchain başlatılıyor..."
echo "📁 Çalışma dizini: $(pwd)"

# Önceki process'leri temizle
pkill -f "usdtgd" 2>/dev/null || true
pkill -f "go run main.go" 2>/dev/null || true

# Port 8080'i kontrol et
if lsof -i :8080 >/dev/null 2>&1; then
    echo "⚠️  Port 8080 zaten kullanımda, temizleniyor..."
    lsof -ti :8080 | xargs kill -9 2>/dev/null || true
fi

# Blockchain'i başlat
echo "🌐 Blockchain başlatılıyor..."
nohup go run main.go > blockchain.log 2>&1 &

# Process ID'yi al
PID=$!
echo "📊 Process ID: $PID"

# 5 saniye bekle
sleep 5

# Test et
if curl -s http://localhost:8080/health >/dev/null 2>&1; then
    echo "✅ Blockchain başarıyla çalışıyor!"
    echo "🌐 API: http://localhost:8080"
    echo "🏥 Health: http://localhost:8080/health"
    echo "📝 Log: blockchain.log"
    echo "🔄 Process ID: $PID"
else
    echo "❌ Blockchain başlatılamadı!"
    echo "📝 Log dosyasını kontrol edin: blockchain.log"
    exit 1
fi
