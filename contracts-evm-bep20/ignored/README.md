# Ignored Files and Directories

Bu klasör, projenin ana işlevselliği için gerekli olmayan dosya ve klasörleri içerir.

## 📁 Taşınan Klasörler

### 🔧 Development Tools
- **manticore/** - Manticore güvenlik analiz aracı
- **echidna/** - Echidna fuzzing test aracı
- **_mythril/** - Mythril güvenlik analiz aracı
- **crytic-export/** - Crytic analiz sonuçları

### 🧪 Testing & Coverage
- **coverage/** - Test coverage raporları
- **node_modules/** - Node.js bağımlılıkları
- **temp_ignored_contracts/** - Geçici kontrat dosyaları

### 🚀 Deployment & Frontend
- **ignition/** - Ignition deployment araçları
- **dao/** - DAO kontratları (ayrı proje)
- **frontend/** - Frontend uygulaması (ayrı proje)

## 📄 Taşınan Dosyalar

### 🔍 Analysis Scripts
- **btcbr_checker.py** - BTCBR token analiz scripti
- **btcbr_token_info.json** - BTCBR token bilgileri
- **btcbr_top_holders.json** - BTCBR büyük holder'ları
- **top_usdt_holders.py** - USDT holder analiz scripti
- **trx_wallets.py** - TRX cüzdan analiz scripti
- **holders_fetcher.py** - Holder veri çekme scripti
- **get_holders.py** - Holder veri alma scripti
- **large_holders.py** - Büyük holder analiz scripti
- **tronscan_holder_fetcher.py** - Tronscan holder veri çekme
- **tronscan_trx_holder_fetcher.py** - TRX holder veri çekme
- **trx_holder_fetcher.py** - TRX holder veri çekme

### 📊 Data Files
- **top_25000_usdt_addresses.txt** - USDT adres listesi
- **top_25000_usdt_addresses_only.csv** - USDT adres CSV
- **top_25000_usdt_holders.csv** - USDT holder CSV
- **top_25000_usdt_holders.json** - USDT holder JSON
- **holders_USDT.json** - USDT holder verileri (7.7MB)

### ⚙️ Configuration Files
- **hardhat.config.js** - Hardhat konfigürasyonu
- **package-lock.json** - Node.js lock dosyası
- **coverage.json** - Coverage raporu
- **setup.sh** - Kurulum scripti
- **run_coverage.sh** - Coverage çalıştırma scripti
- **instrumented** - Instrumented kod dosyası
- **.DS_Store** - macOS sistem dosyası

## 🎯 Neden Taşındı?

Bu dosyalar şu nedenlerle taşındı:

1. **Proje Odaklılık** - Ana proje işlevselliği dışında
2. **Gereksiz Bağımlılıklar** - Production için gerekli değil
3. **Test Araçları** - Sadece geliştirme sırasında kullanılıyor
4. **Büyük Veri Dosyaları** - Repository boyutunu artırıyor
5. **Ayrı Projeler** - DAO ve Frontend ayrı projeler

## 🔄 Geri Yükleme

Eğer bu dosyalara ihtiyaç duyarsanız:

```bash
# Belirli bir dosyayı geri yükle
mv ignored/filename.py ./

# Belirli bir klasörü geri yükle
mv ignored/folder_name/ ./

# Tümünü geri yükle (dikkatli olun!)
mv ignored/* ./
```

## 📝 Not

Bu dosyalar projenin çalışması için gerekli değildir. Ana proje dosyaları:
- `contracts/` - Smart kontratlar
- `test/` - Test dosyaları
- `scripts/` - Deployment scriptleri
- `docs/` - Dokümantasyon
- `audit/` - Audit raporları

Bu dosyalar ana dizinde kalacaktır. 