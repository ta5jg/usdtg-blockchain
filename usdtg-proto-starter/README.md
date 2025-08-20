# USDTg Protocol Buffer Starter

Bu proje, USDTg blockchain projesi için Protocol Buffer ve gRPC altyapısını içerir.

## 🚀 Özellikler

- **Protocol Buffer**: Token servisi için proto dosyaları
- **gRPC Server**: Node.js tabanlı gRPC sunucu
- **gRPC Client**: Test ve demo için client kodu
- **Kapsamlı Testler**: Otomatik test suite
- **Mock Veritabanı**: Geliştirme için test verileri

## 📁 Proje Yapısı

```
usdtg-proto-starter/
├── usdtg/                    # Proto dosyaları
│   ├── token/v1/
│   │   └── token.proto      # Token servisi tanımları
│   └── oracle/v1/
│       └── oracle.proto     # Oracle servisi tanımları
├── src/
│   ├── server/              # gRPC sunucu kodu
│   ├── client/              # gRPC client kodu
│   └── test/                # Test kodları
├── gen/                     # Generate edilen kodlar
├── buf.yaml                 # Buf konfigürasyonu
└── package.json             # Node.js bağımlılıkları
```

## 🛠️ Kurulum

### Gereksinimler

- Node.js 16+
- pnpm (önerilen)
- buf CLI

### Kurulum Adımları

1. **Bağımlılıkları yükle:**
```bash
pnpm install
```

2. **Proto dosyalarını generate et:**
```bash
pnpm run proto:generate
```

3. **Proto dosyalarını lint et:**
```bash
pnpm run proto:lint
```

## 🚀 Kullanım

### 1. Sunucuyu Başlat

```bash
# Geliştirme modu (nodemon ile)
pnpm run dev

# Üretim modu
pnpm run server
# veya
pnpm start
```

Sunucu varsayılan olarak `localhost:50051` portunda çalışır.

### 2. Client Demo Çalıştır

```bash
# Demo çalıştır
pnpm run client:demo

# Bağlantı test et
pnpm run client:test
```

### 3. Testleri Çalıştır

```bash
# Tüm testleri çalıştır
pnpm test
```

## 📋 API Endpoints

### TokenService

#### getBalance
- **Request**: `{ address: string }`
- **Response**: `{ address: string, denom: string, amount: string, as_of: string }`

#### transfer
- **Request**: `{ from_address: string, to_address: string, denom: string, amount: number }`
- **Response**: `{ tx_hash: string, accepted: boolean }`

#### mint
- **Request**: `{ to_address: string, denom: string, amount: number }`
- **Response**: `{ tx_hash: string, accepted: boolean }`

## 🧪 Test Verileri

Sunucu başlatıldığında otomatik olarak test verileri eklenir:

- `0x1234567890abcdef`: 1000 USDTg
- `0xabcdef1234567890`: 500 USDTg

## 🔧 Geliştirme

### Proto Dosyalarını Güncelle

```bash
# Proto dosyalarını düzenle
# Sonra generate et:
pnpm run proto:generate
```

### Yeni Servis Ekle

1. `usdtg/` altında yeni proto dosyası oluştur
2. `buf.yaml`'a ekle
3. `pnpm run proto:generate` çalıştır
4. Server ve client kodlarını güncelle

### Test Ekle

1. `src/test/` altında yeni test dosyası oluştur
2. Test class'ını `TokenServiceTest`'e ekle
3. `runAllTests()` metodunda çağır

## 📊 Performans

- **Bakiye sorgusu**: ~5-10ms
- **Transfer işlemi**: ~10-20ms
- **Mint işlemi**: ~15-25ms

## 🚨 Hata Ayıklama

### Yaygın Hatalar

1. **Port zaten kullanımda**: Farklı port kullan veya mevcut process'i sonlandır
2. **Proto dosyası bulunamadı**: `pnpm run proto:generate` çalıştır
3. **Bağlantı hatası**: Sunucunun çalıştığından emin ol

### Log Seviyeleri

Sunucu detaylı loglar verir:
- Bakiye sorguları
- Transfer işlemleri
- Mint işlemleri
- Hata durumları

## 🔮 Gelecek Özellikler

- [ ] PostgreSQL entegrasyonu
- [ ] Authentication & Authorization
- [ ] Rate limiting
- [ ] Metrics & Monitoring
- [ ] Docker containerization
- [ ] Kubernetes deployment

## 📝 Lisans

MIT License

## 🤝 Katkıda Bulunma

1. Fork yap
2. Feature branch oluştur (`git checkout -b feature/amazing-feature`)
3. Commit yap (`git commit -m 'Add amazing feature'`)
4. Push yap (`git push origin feature/amazing-feature`)
5. Pull Request oluştur

## 📞 İletişim

- **Proje**: USDTg Blockchain
- **GitHub**: [USDTg Repository](https://github.com/usdtg)
- **Email**: team@usdtg.com

---

**Not**: Bu proje geliştirme amaçlıdır. Üretim ortamında kullanmadan önce güvenlik testlerinden geçirin.
