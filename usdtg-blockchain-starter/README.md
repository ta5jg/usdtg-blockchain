# USdTG Blockchain — Cosmos SDK Starter (Mac)

Bu paket, **Cosmos SDK + CometBFT** tabanlı _USdTG_ yerel geliştirme ağı için hızlı başlangıç sağlar.
Yaklaşım **Ignite CLI** ile otomatik iskelet + 
**uusdtg** taban birimi (6 ondalık) + faucet + dev hesapları içerir.

## İçerik
- `scripts/01_install_prereqs_mac.sh` — Mac için Go, buf, jq, Ignite kurulumu
- `scripts/02_scaffold_with_ignite.sh` — Ignite ile zinciri iskeletle (adı: `usdtg`)
- `scripts/03_configure_and_serve.sh` — denom, faucet, hesaplar; local node'u başlatır
- `config/config.yml` — Ignite zincir yapılandırması şablonu (denom, faucet, hesaplar)
- `config/usdtg-denom-metadata.json` — Bank denom metadata (display/exponentler)
- `config/dev-accounts.json` — Örnek cüzdanlar ve bakiyeler

> Not: Bu starter **kod üretir**; Cosmos SDK kaynakları Ignite tarafından indirildiği için burada minimal dosyalar var.

---

## Hızlı Başlangıç (Mac, Apple Silicon/Intel)
```bash
# 1) Bu klasörü açın
cd usdtg-blockchain-starter

# 2) Önkoşullar (Go 1.22+, buf, jq, ignite)
bash scripts/01_install_prereqs_mac.sh

# 3) Ignite ile iskelet oluşturun
bash scripts/02_scaffold_with_ignite.sh

# 4) Denom, faucet, hesapları uygula ve node'u başlat
bash scripts/03_configure_and_serve.sh
```

Başarıyla çalışırsa:
- REST/GRPC: `localhost:1317` / `localhost:9090`
- RPC: `localhost:26657`
- Faucet: `uusdtg` dağıtır
- Cüzdanlar: `alice`, `bob` (anahtarlar yerelde)

## Birim Adlandırma
- **Base denom:** `uusdtg` (mikro birim)
- **Display:** `usdtg` (6 ondalık → 1 `usdtg` = 1_000_000 `uusdtg`)

## Faydalı Komutlar
```bash
# Loglar
ignite chain serve

# Cüzdanları listele
usdtgd keys list --keyring-backend test

# Bakiye bak
usdtgd q bank balances $(usdtgd keys show alice -a --keyring-backend test)

# Transfer örneği
usdtgd tx bank send alice $(usdtgd keys show bob -a --keyring-backend test) 1000uusdtg   --chain-id usdtg-local --fees 200uusdtg --keyring-backend test -y
```

## Sonraki Adımlar (Roadmap)
- **IBC/Bridge** hazırlığı (ERC20/TRC20 köprü modülleri planı)
- **WASM (CosmWasm)** modülü (akıllı sözleşme desteği)
- **Explorer** (ping.pub, Big Dipper) entegrasyonu
- **DApp & Wallet** → `usdtg-monorepo-v5` ile entegrasyon

---

**Not:** Bu betikler yerel geliştirme içindir. Üretim için `app.toml/config.toml` sertleştirme, snapshot, sentry, minimum-fee ve `state-sync` ayarları gerekir.
