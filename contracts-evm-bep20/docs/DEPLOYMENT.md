# 🚀 Deployment Rehberi

Bu rehber, USDTg UltraSecureToken kontratını farklı ağlara deploy etme sürecini açıklar.

## 📋 İçindekiler

- [Ön Gereksinimler](#ön-gereksinimler)
- [Environment Setup](#environment-setup)
- [Deployment Scripts](#deployment-scripts)
- [Test Ağı Deployment](#test-ağı-deployment)
- [Ana Ağ Deployment](#ana-ağ-deployment)
- [Post-Deployment](#post-deployment)
- [Verification](#verification)
- [Troubleshooting](#troubleshooting)

## 🔧 Ön Gereksinimler

### Gerekli Araçlar
- **Foundry**: `curl -L https://foundry.paradigm.xyz | bash`
- **Node.js**: 16+ versiyonu
- **Git**: En son versiyon

### Gerekli Bilgiler
- **Private Key**: Deployment için kullanılacak private key
- **RPC URL**: Hedef ağın RPC endpoint'i
- **Explorer API Key**: Kontrat verification için

## 🌍 Environment Setup

### 1. Environment Variables
`.env` dosyası oluşturun:

```bash
# Private Keys
PRIVATE_KEY=your_private_key_here
MULTISIG_PRIVATE_KEY_1=multisig_key_1
MULTISIG_PRIVATE_KEY_2=multisig_key_2
MULTISIG_PRIVATE_KEY_3=multisig_key_3

# RPC URLs
MAINNET_RPC_URL=https://eth-mainnet.alchemyapi.io/v2/your_key
SEPOLIA_RPC_URL=https://eth-sepolia.alchemyapi.io/v2/your_key
BSC_RPC_URL=https://bsc-dataseed.binance.org/
BSC_TESTNET_RPC_URL=https://data-seed-prebsc-1-s1.binance.org:8545/

# Explorer API Keys
ETHERSCAN_API_KEY=your_etherscan_api_key
BSCSCAN_API_KEY=your_bscscan_api_key

# Gas Settings
GAS_LIMIT=5000000
GAS_PRICE=20000000000  # 20 gwei
```

### 2. Foundry Configuration
`foundry.toml` dosyasını güncelleyin:

```toml
[profile.default]
src = "contracts"
out = "out"
libs = ["lib"]
solc_version = "0.8.28"
optimizer = true
optimizer_runs = 200

[rpc_endpoints]
mainnet = "${MAINNET_RPC_URL}"
sepolia = "${SEPOLIA_RPC_URL}"
bsc = "${BSC_RPC_URL}"
bsc_testnet = "${BSC_TESTNET_RPC_URL}"

[etherscan]
mainnet = { key = "${ETHERSCAN_API_KEY}" }
sepolia = { key = "${ETHERSCAN_API_KEY}" }
bsc = { key = "${BSCSCAN_API_KEY}" }
bsc_testnet = { key = "${BSCSCAN_API_KEY}" }
```

## 📜 Deployment Scripts

### Ana Deployment Script
`scripts/deploy_production.js`:

```javascript
const { ethers } = require("hardhat");

async function main() {
  const [deployer] = await ethers.getSigners();
  console.log("Deploying contracts with account:", deployer.address);

  // 1. Deploy RoleManager
  const RoleManager = await ethers.getContractFactory("RoleManager");
  const roleManager = await RoleManager.deploy(deployer.address);
  await roleManager.deployed();
  console.log("RoleManager deployed to:", roleManager.address);

  // 2. Deploy Multisig Wallet
  const MultisigWallet = await ethers.getContractFactory("MultisigWallet");
  const signers = [
    process.env.MULTISIG_SIGNER_1,
    process.env.MULTISIG_SIGNER_2,
    process.env.MULTISIG_SIGNER_3
  ];
  const multisigWallet = await MultisigWallet.deploy(
    ethers.constants.AddressZero,
    signers,
    3 // required signatures
  );
  await multisigWallet.deployed();
  console.log("MultisigWallet deployed to:", multisigWallet.address);

  // 3. Deploy Timelock
  const TimelockController = await ethers.getContractFactory("TimelockController");
  const proposers = [multisigWallet.address];
  const executors = [multisigWallet.address];
  const timelock = await TimelockController.deploy(
    86400, // 1 day delay
    proposers,
    executors,
    multisigWallet.address
  );
  await timelock.deployed();
  console.log("TimelockController deployed to:", timelock.address);

  // 4. Deploy Manager Contracts
  const FeeManager = await ethers.getContractFactory("FeeManager");
  const feeManager = await FeeManager.deploy(ethers.constants.AddressZero);
  await feeManager.deployed();

  const SecurityManager = await ethers.getContractFactory("SecurityManager");
  const securityManager = await SecurityManager.deploy(
    ethers.constants.AddressZero,
    roleManager.address
  );
  await securityManager.deployed();

  // ... diğer manager kontratları

  // 5. Deploy Main Token
  const TetherGroundUSDToken = await ethers.getContractFactory("TetherGroundUSDToken");
  const token = await TetherGroundUSDToken.deploy(
    roleManager.address,
    feeManager.address,
    multisigWallet.address,
    metadataManager.address,
    securityManager.address,
    timelock.address,
    ethers.constants.AddressZero, // price oracle
    stakingManager.address,
    batchManager.address,
    advancedFeeManager.address,
    rateLimitManager.address
  );
  await token.deployed();
  console.log("TetherGroundUSDToken deployed to:", token.address);

  // 6. Update Manager Contracts with Token Address
  const newFeeManager = await FeeManager.deploy(token.address);
  const newSecurityManager = await SecurityManager.deploy(token.address, roleManager.address);
  // ... diğer manager'ları güncelle

  // 7. Set Manager Addresses in Token
  await token.setFeeManagerForTesting(newFeeManager.address);
  await token.setSecurityManagerForTesting(newSecurityManager.address);
  // ... diğer manager'ları set et

  console.log("Deployment completed successfully!");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
```

## 🧪 Test Ağı Deployment

### Sepolia Testnet
```bash
# Environment'ı yükle
source .env

# Sepolia'ya deploy et
forge script scripts/deploy_production.js \
  --rpc-url $SEPOLIA_RPC_URL \
  --private-key $PRIVATE_KEY \
  --broadcast \
  --verify \
  --etherscan-api-key $ETHERSCAN_API_KEY
```

### BSC Testnet
```bash
# BSC testnet'e deploy et
forge script scripts/deploy_production.js \
  --rpc-url $BSC_TESTNET_RPC_URL \
  --private-key $PRIVATE_KEY \
  --broadcast \
  --verify \
  --etherscan-api-key $BSCSCAN_API_KEY
```

## 🌐 Ana Ağ Deployment

### Ethereum Mainnet
```bash
# Ana ağa deploy et (DİKKAT: Gerçek ETH gerektirir)
forge script scripts/deploy_production.js \
  --rpc-url $MAINNET_RPC_URL \
  --private-key $PRIVATE_KEY \
  --broadcast \
  --verify \
  --etherscan-api-key $ETHERSCAN_API_KEY
```

### BSC Mainnet
```bash
# BSC ana ağına deploy et
forge script scripts/deploy_production.js \
  --rpc-url $BSC_RPC_URL \
  --private-key $PRIVATE_KEY \
  --broadcast \
  --verify \
  --etherscan-api-key $BSCSCAN_API_KEY
```

## 🔍 Post-Deployment

### 1. Kontrat Adreslerini Kaydet
Deployment sonrası tüm kontrat adreslerini kaydedin:

```bash
# Deployment loglarını kaydet
forge script scripts/deploy_production.js \
  --rpc-url $RPC_URL \
  --private-key $PRIVATE_KEY \
  --broadcast \
  --verify \
  --etherscan-api-key $API_KEY \
  --gas-report > deployment_log.txt
```

### 2. Kontratları Doğrula
```bash
# Etherscan'de verification
forge verify-contract \
  --chain-id 1 \
  --compiler-version 0.8.28 \
  --constructor-args $(cast abi-encode "constructor(address,address,address,address,address,address,address,address,address,address,address)" \
    $ROLE_MANAGER $FEE_MANAGER $MULTISIG $METADATA $SECURITY $TIMELOCK $ORACLE $STAKING $BATCH $ADVANCED_FEE $RATE_LIMIT) \
  $TOKEN_ADDRESS \
  src/TetherGroundUSDToken.sol:TetherGroundUSDToken \
  $ETHERSCAN_API_KEY
```

### 3. İlk Ayarları Yap
```bash
# Fee ayarları
cast send $TOKEN_ADDRESS "setFee(uint256)" 50 --private-key $PRIVATE_KEY

# Fee recipient ayarla
cast send $TOKEN_ADDRESS "setFeeRecipient(address)" $DEPLOYER_ADDRESS --private-key $PRIVATE_KEY

# Multisig'e roller ver
cast send $ROLE_MANAGER "grantRole(bytes32,address)" \
  $(cast sig "MINTER_ROLE()") $MULTISIG_ADDRESS --private-key $PRIVATE_KEY
```

## ✅ Verification

### Etherscan Verification
1. Kontrat adresini Etherscan'de açın
2. "Contract" sekmesine gidin
3. "Verify and Publish" butonuna tıklayın
4. Kontrat bilgilerini girin:
   - Compiler Version: 0.8.28
   - Optimization: Enabled
   - Optimization runs: 200
   - Constructor Arguments: ABI-encoded parameters

### BSCScan Verification
BSCScan için aynı adımları takip edin.

## 🚨 Troubleshooting

### Yaygın Hatalar

#### 1. "Insufficient funds"
```bash
# Gas fiyatını düşür
forge script ... --gas-price 15000000000  # 15 gwei
```

#### 2. "Nonce too high"
```bash
# Nonce'u sıfırla
cast nonce $ADDRESS --rpc-url $RPC_URL
```

#### 3. "Contract verification failed"
```bash
# Constructor arguments'ı kontrol et
cast abi-decode "constructor(address,address,address,address,address,address,address,address,address,address,address)" $CONSTRUCTOR_ARGS
```

### Gas Optimizasyonu
```bash
# Gas raporu al
forge test --gas-report

# Gas limit'i ayarla
forge script ... --gas-limit 8000000
```

## 📊 Deployment Checklist

- [ ] Environment variables ayarlandı
- [ ] Test ağında başarılı deployment
- [ ] Kontratlar verify edildi
- [ ] İlk ayarlar yapıldı
- [ ] Multisig roller atandı
- [ ] Fee ayarları yapıldı
- [ ] Security testleri geçti
- [ ] Ana ağa deployment hazır

## 🔗 Faydalı Linkler

- [Foundry Book](https://book.getfoundry.sh/)
- [Etherscan API](https://docs.etherscan.io/)
- [BSCScan API](https://docs.bscscan.com/)
- [OpenZeppelin Contracts](https://docs.openzeppelin.com/contracts/)

---

**⚠️ Önemli Not:** Ana ağa deployment yapmadan önce mutlaka test ağında kapsamlı testler yapın! 