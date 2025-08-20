# 📚 API Dokümantasyonu

USDTg UltraSecureToken kontratının tüm fonksiyonları ve kullanım örnekleri.

## 📋 İçindekiler

- [Genel Bakış](#genel-bakış)
- [ERC-20 Fonksiyonları](#erc-20-fonksiyonları)
- [Access Control](#access-control)
- [Fee Management](#fee-management)
- [Security Functions](#security-functions)
- [Multisig Functions](#multisig-functions)
- [Batch Operations](#batch-operations)
- [Staking Functions](#staking-functions)
- [Emergency Functions](#emergency-functions)
- [View Functions](#view-functions)
- [Events](#events)
- [Error Codes](#error-codes)

## 🔍 Genel Bakış

### Kontrat Bilgileri
- **Name**: TetherGround USD
- **Symbol**: USDTg
- **Decimals**: 18
- **Total Supply**: 100,000,000 USDTg
- **Initial Distribution**: 50,000,000 USDTg

### Temel Özellikler
- ERC-20 uyumlu
- Role-based access control
- Multisig governance
- Dynamic fee system
- Rate limiting
- Blacklist functionality
- Emergency pause

## 💰 ERC-20 Fonksiyonları

### `transfer(address to, uint256 amount)`
Token transfer fonksiyonu.

**Parametreler:**
- `to`: Alıcı adres
- `amount`: Transfer miktarı (wei cinsinden)

**Dönüş Değeri:**
- `bool`: Transfer başarılı ise true

**Örnek:**
```solidity
// 1000 USDTg transfer et
uint256 amount = 1000 * 10**18;
bool success = token.transfer(recipient, amount);
require(success, "Transfer failed");
```

### `transferFrom(address from, address to, uint256 amount)`
Yetkilendirilmiş transfer fonksiyonu.

**Parametreler:**
- `from`: Gönderen adres
- `to`: Alıcı adres
- `amount`: Transfer miktarı

**Dönüş Değeri:**
- `bool`: Transfer başarılı ise true

**Örnek:**
```solidity
// Önce approve et
token.approve(spender, amount);
// Sonra transferFrom çağır
bool success = token.transferFrom(from, to, amount);
```

### `approve(address spender, uint256 amount)`
Harcama yetkisi verir.

**Parametreler:**
- `spender`: Yetkili adres
- `amount`: Yetki miktarı

**Dönüş Değeri:**
- `bool`: İşlem başarılı ise true

### `allowance(address owner, address spender)`
Yetki miktarını kontrol eder.

**Parametreler:**
- `owner`: Token sahibi
- `spender`: Yetkili adres

**Dönüş Değeri:**
- `uint256`: Kalan yetki miktarı

## 🔐 Access Control

### `grantRole(bytes32 role, address account)`
Role atar.

**Parametreler:**
- `role`: Role hash'i
- `account`: Hedef adres

**Gerekli Role:**
- `DEFAULT_ADMIN_ROLE`

### `revokeRole(bytes32 role, address account)`
Role'ü kaldırır.

**Parametreler:**
- `role`: Role hash'i
- `account`: Hedef adres

**Gerekli Role:**
- `DEFAULT_ADMIN_ROLE`

### `hasRole(bytes32 role, address account)`
Role kontrolü yapar.

**Parametreler:**
- `role`: Role hash'i
- `account`: Kontrol edilecek adres

**Dönüş Değeri:**
- `bool`: Role varsa true

### Mevcut Roller
```solidity
DEFAULT_ADMIN_ROLE = 0x00
MINTER_ROLE = keccak256("MINTER_ROLE")
PAUSER_ROLE = keccak256("PAUSER_ROLE")
EMERGENCY_ROLE = keccak256("EMERGENCY_ROLE")
BLACKLIST_MANAGER_ROLE = keccak256("BLACKLIST_MANAGER_ROLE")
```

## 💸 Fee Management

### `getFeeInfo()`
Fee bilgilerini döndürür.

**Dönüş Değeri:**
- `uint256 currentFee`: Mevcut fee oranı (basis points)
- `address recipient`: Fee alıcısı
- `bool hasFee`: Fee aktif mi

**Örnek:**
```solidity
(uint256 fee, address recipient, bool hasFee) = token.getFeeInfo();
console.log("Fee:", fee, "basis points");
console.log("Recipient:", recipient);
```

### `setFee(uint256 newFee)`
Fee oranını ayarlar.

**Parametreler:**
- `newFee`: Yeni fee oranı (basis points, 100 = %1)

**Gerekli Role:**
- `DEFAULT_ADMIN_ROLE`

### `setFeeRecipient(address newRecipient)`
Fee alıcısını ayarlar.

**Parametreler:**
- `newRecipient`: Yeni fee alıcısı

**Gerekli Role:**
- `DEFAULT_ADMIN_ROLE`

### `setFeeExemption(address account, bool exempt)`
Fee muafiyeti ayarlar.

**Parametreler:**
- `account`: Muafiyet verilecek adres
- `exempt`: Muafiyet durumu

**Gerekli Role:**
- `DEFAULT_ADMIN_ROLE`

## 🛡️ Security Functions

### `setSecurityBlacklistStatus(address account, bool blacklisted)`
Kara liste durumunu ayarlar.

**Parametreler:**
- `account`: Hedef adres
- `blacklisted`: Kara liste durumu

**Gerekli Role:**
- `BLACKLIST_MANAGER_ROLE`

### `isSecurityBlacklisted(address account)`
Kara liste kontrolü yapar.

**Parametreler:**
- `account`: Kontrol edilecek adres

**Dönüş Değeri:**
- `bool`: Kara listede ise true

### `getSecurityStatus(address account)`
Güvenlik durumunu döndürür.

**Parametreler:**
- `account`: Hedef adres

**Dönüş Değeri:**
- `bool blacklisted`: Kara liste durumu
- `bool locked`: Kilit durumu
- `uint256 lastTransfer`: Son transfer zamanı

## 🔐 Multisig Functions

### `submitTransaction(address target, uint256 value, bytes calldata data, string memory description)`
Multisig işlemi önerir.

**Parametreler:**
- `target`: Hedef kontrat
- `value`: ETH miktarı
- `data`: İşlem verisi
- `description`: İşlem açıklaması

**Dönüş Değeri:**
- `uint256`: İşlem ID'si

### `confirmTransaction(uint256 transactionId)`
Multisig işlemini onaylar.

**Parametreler:**
- `transactionId`: İşlem ID'si

### `executeTransaction(uint256 transactionId)`
Multisig işlemini çalıştırır.

**Parametreler:**
- `transactionId`: İşlem ID'si

### `revokeConfirmation(uint256 transactionId)`
Multisig onayını iptal eder.

**Parametreler:**
- `transactionId`: İşlem ID'si

## 📦 Batch Operations

### `batchTransfer(address[] calldata recipients, uint256[] calldata amounts)`
Toplu transfer yapar.

**Parametreler:**
- `recipients`: Alıcı adresleri dizisi
- `amounts`: Transfer miktarları dizisi

**Örnek:**
```solidity
address[] memory recipients = new address[](3);
uint256[] memory amounts = new uint256[](3);

recipients[0] = address1;
recipients[1] = address2;
recipients[2] = address3;

amounts[0] = 100 * 10**18;
amounts[1] = 200 * 10**18;
amounts[2] = 300 * 10**18;

token.batchTransfer(recipients, amounts);
```

### `batchMint(address[] calldata recipients, uint256[] calldata amounts)`
Toplu mint yapar.

**Parametreler:**
- `recipients`: Alıcı adresleri dizisi
- `amounts`: Mint miktarları dizisi

**Gerekli Role:**
- `MINTER_ROLE`

## 🏦 Staking Functions

### `addToStakingPool(uint256 amount)`
Staking havuzuna ekleme yapar.

**Parametreler:**
- `amount`: Eklenecek miktar

**Gerekli Role:**
- `DEFAULT_ADMIN_ROLE`

### `claimStakingRewards()`
Staking ödüllerini talep eder.

**Gerekli Role:**
- `DEFAULT_ADMIN_ROLE`

### `useEcosystemFund(address recipient, uint256 amount, string calldata purpose)`
Ekosistem fonunu kullanır.

**Parametreler:**
- `recipient`: Alıcı adres
- `amount`: Kullanılacak miktar
- `purpose`: Kullanım amacı

**Gerekli Role:**
- `DEFAULT_ADMIN_ROLE`

### `getFounderInfo()`
Kurucu bilgilerini döndürür.

**Dönüş Değeri:**
- `uint256 stakingPool`: Staking havuzu
- `uint256 stakingLimit`: Staking limiti
- `uint256 ecosystemLimit`: Ekosistem limiti
- `uint256 stakingRewardRate`: Ödül oranı
- `uint256 pendingRewards`: Bekleyen ödüller

## 🚨 Emergency Functions

### `pause()`
Kontratı duraklatır.

**Gerekli Role:**
- `PAUSER_ROLE`

### `unpause()`
Kontratı devam ettirir.

**Gerekli Role:**
- `PAUSER_ROLE`

### `emergencyPause()`
Acil durum duraklatması yapar.

**Gerekli Role:**
- `EMERGENCY_ROLE`

### `emergencyUnpause()`
Acil durum duraklatmasını kaldırır.

**Gerekli Role:**
- `EMERGENCY_ROLE`

## 👁️ View Functions

### `name()`
Token adını döndürür.

**Dönüş Değeri:**
- `string`: Token adı

### `symbol()`
Token sembolünü döndürür.

**Dönüş Değeri:**
- `string`: Token sembolü

### `decimals()`
Token ondalık basamak sayısını döndürür.

**Dönüş Değeri:**
- `uint8`: Ondalık basamak sayısı (18)

### `totalSupply()`
Toplam arzı döndürür.

**Dönüş Değeri:**
- `uint256`: Toplam arz

### `balanceOf(address account)`
Adres bakiyesini döndürür.

**Parametreler:**
- `account`: Hedef adres

**Dönüş Değeri:**
- `uint256`: Bakiye

### `isPaused()`
Duraklatma durumunu kontrol eder.

**Dönüş Değeri:**
- `bool`: Duraklatılmış ise true

### `isEmergencyPaused()`
Acil durum duraklatma durumunu kontrol eder.

**Dönüş Değeri:**
- `bool`: Acil durum duraklatılmış ise true

### `getTokenEconomics()`
Token ekonomisi bilgilerini döndürür.

**Dönüş Değeri:**
- `uint256 maxSupply`: Maksimum arz
- `uint256 initialDistribution`: İlk dağıtım
- `uint256 collateralReserve`: Teminat rezervi
- `uint256 tokenSale`: Token satışı
- `uint256 liquidityMining`: Likidite madenciliği
- `uint256 ecosystemFund`: Ekosistem fonu
- `uint256 teamVesting`: Takım vesting
- `uint256 communityRewards`: Topluluk ödülleri
- `uint256 reserveFund`: Rezerv fonu
- `uint256 currentCirculating`: Mevcut dolaşımdaki miktar

## 📢 Events

### `Transfer(address indexed from, address indexed to, uint256 value)`
Transfer olayı.

### `Approval(address indexed owner, address indexed spender, uint256 value)`
Onay olayı.

### `RoleGranted(bytes32 indexed role, address indexed account, address indexed sender)`
Role verilme olayı.

### `RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender)`
Role kaldırılma olayı.

### `Paused(address account)`
Duraklatma olayı.

### `Unpaused(address account)`
Devam ettirme olayı.

### `FeeUpdated(uint256 oldFee, uint256 newFee)`
Fee güncelleme olayı.

### `FeeRecipientUpdated(address oldRecipient, address newRecipient)`
Fee alıcısı güncelleme olayı.

### `BlacklistStatusUpdated(address indexed account, bool blacklisted)`
Kara liste durumu güncelleme olayı.

## ❌ Error Codes

### Genel Hatalar
- `"Insufficient balance"`: Yetersiz bakiye
- `"Transfer amount exceeds allowance"`: Transfer miktarı yetkiyi aşıyor
- `"Transfer to zero address"`: Sıfır adrese transfer
- `"Invalid amount"`: Geçersiz miktar

### Access Control Hataları
- `"AccessControl: account is missing role"`: Gerekli role yok
- `"Only multisig or timelock can execute"`: Sadece multisig/timelock çalıştırabilir
- `"Only token contract"`: Sadece token kontratı çağırabilir

### Security Hataları
- `"Sender blacklisted"`: Gönderen kara listede
- `"Recipient blacklisted"`: Alıcı kara listede
- `"Flash loan detected"`: Flash loan tespit edildi
- `"Amount too small"`: Miktar çok küçük

### State Hataları
- `"Token is paused"`: Token duraklatılmış
- `"Token is emergency paused"`: Token acil durum duraklatılmış
- `"Rate limit exceeded"`: Hız limiti aşıldı

## 🔧 Kullanım Örnekleri

### Temel Transfer
```solidity
// Basit transfer
uint256 amount = 1000 * 10**18;
bool success = token.transfer(recipient, amount);
require(success, "Transfer failed");
```

### Multisig İşlemi
```solidity
// Mint işlemi için multisig kullan
bytes memory mintData = abi.encodeWithSelector(
    token.mint.selector,
    recipient,
    amount
);

uint256 transactionId = multisigWallet.submitTransaction(
    address(token),
    0,
    mintData,
    "Mint tokens"
);

// Onayla ve çalıştır
multisigWallet.confirmTransaction(transactionId);
multisigWallet.executeTransaction(transactionId);
```

### Fee Hesaplama
```solidity
// Fee bilgilerini al
(uint256 fee, address recipient, bool hasFee) = token.getFeeInfo();

// Transfer miktarını hesapla
uint256 transferAmount = 1000 * 10**18;
uint256 feeAmount = transferAmount * fee / 10000;
uint256 netAmount = transferAmount - feeAmount;
```

### Batch İşlemler
```solidity
// Toplu transfer
address[] memory recipients = new address[](2);
uint256[] memory amounts = new uint256[](2);

recipients[0] = address1;
recipients[1] = address2;
amounts[0] = 100 * 10**18;
amounts[1] = 200 * 10**18;

token.batchTransfer(recipients, amounts);
```

---

**📝 Not:** Tüm fonksiyonlar için gerekli rollere sahip olduğunuzdan emin olun! 