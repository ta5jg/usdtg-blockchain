# 🚀 USDTg Blockchain - Complete Blockchain Ecosystem

**TetherGround USD (USDTg)** - A revolutionary blockchain platform with custom blockchain core, smart contracts, DApp, and wallet integration.

## 🌟 Project Overview

USDTg Blockchain is a comprehensive blockchain ecosystem that includes:

- **Custom Go Blockchain Core** with HTTP API
- **React DApp** with full blockchain functionality
- **Smart Contract Support** (EVM compatible)
- **Token Management** (USDTg Token)
- **Mining/Staking System** (Proof of Stake)
- **Account Management**
- **Cross-platform Wallet** (Android & iOS)

## 🏗️ Architecture

```
usdtg-blockchain/
├── usdtg-chain/           # Go Blockchain Core
│   ├── blockchain/        # Blockchain logic
│   ├── simple_main.go     # HTTP API Server
│   └── frontend/          # React DApp
├── contracts-tron/         # TRON Network Contracts
├── contracts-evm/          # Ethereum/BSC Contracts
└── apps/                   # Additional Applications
```

## 🚀 Quick Start

### Prerequisites
- Go 1.21+
- Node.js 18+
- pnpm

### 1. Start Blockchain Backend
```bash
cd usdtg-blockchain/usdtg-chain
go run simple_main.go
# Backend runs on http://localhost:8080
```

### 2. Start Frontend DApp
```bash
cd usdtg-blockchain/usdtg-chain/frontend
npm install
npm run dev
# Frontend runs on http://localhost:3000
```

### 3. Start Monorepo (Alternative)
```bash
pnpm install
pnpm dev
# DApp: http://localhost:5174
# Site: http://localhost:5175
# API: http://localhost:8080
```

## 🔧 Features

### ✅ Working Features
- **Dashboard** - Real-time blockchain monitoring
- **Token Transfer** - USDTg token transfers
- **Smart Contracts** - Contract deployment & interaction
- **Accounts** - Address management & balance checking
- **Mining** - Block creation & rewards
- **Settings** - Configuration panel

### 🚧 In Development
- **Mobile Wallet** (React Native)
- **DEX Integration** (SunSwap, PancakeSwap, Uniswap)
- **CEX Listings** (Binance, OKX)
- **Price Feeds** (CoinGecko, CoinMarketCap)

## 🌐 API Endpoints

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/health` | GET | Health check |
| `/api/blockchain/info` | GET | Blockchain statistics |
| `/api/blockchain/balance/{address}` | GET | Account balance |
| `/api/blockchain/mine` | POST | Mine new block |
| `/api/blockchain/transaction` | POST | Create transaction |
| `/api/evm/contract/deploy` | POST | Deploy smart contract |

## 💰 USDTg Token

**TetherGround USD (USDTg)** is the native token of the USDTg Blockchain:

- **Standard**: TRC20 (TRON), ERC20 (Ethereum), BEP20 (BSC)
- **Total Supply**: 1,000,000,000 USDTg
- **Decimals**: 18
- **Mining Reward**: 100 USDTg per block
- **Consensus**: Proof of Stake (PoS)

## 🔐 Security Features

- **Multisig Wallet** for administrative operations
- **No OnlyAdmin functions** in smart contracts
- **CORS protection** on all API endpoints
- **Input validation** on all endpoints
- **Secure key management**

## 📱 Mobile Wallet (Coming Soon)

### Features
- **Cross-platform** (Android & iOS)
- **USDTg Token Support**
- **Real-time Price Feeds**
- **Secure Key Storage**
- **Transaction History**
- **QR Code Support**

### Tech Stack
- **React Native**
- **Expo SDK**
- **Web3 Libraries**
- **Secure Storage**

## 🌍 Network Support

### Primary Networks
- **USDTg Blockchain** (Custom Go Chain)
- **TRON Network** (TRC20)
- **Ethereum Network** (ERC20)
- **Binance Smart Chain** (BEP20)

### Planned Networks
- **Polygon**
- **Avalanche**
- **Solana**

## 🚀 Deployment

### Local Development
```bash
# Start all services
./start_blockchain.sh
```

### Production
```bash
# Build and deploy
go build -o usdtgd simple_main.go
./usdtgd
```

## 📊 Monitoring

### Health Checks
- **Backend**: `http://localhost:8080/health`
- **Frontend**: Dashboard status indicators
- **Blockchain**: Chain validation status

### Logs
- **Backend**: Console output with timestamps
- **Frontend**: Browser console
- **Blockchain**: Transaction & block logs

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🌟 Roadmap

### Phase 1: Core Blockchain ✅
- [x] Custom Go blockchain
- [x] HTTP API endpoints
- [x] React DApp
- [x] Basic smart contracts

### Phase 2: Token & Wallet 🚧
- [ ] USDTg token deployment
- [ ] Mobile wallet development
- [ ] Price feed integration
- [ ] Logo & metadata

### Phase 3: DEX & CEX 📋
- [ ] SunSwap integration
- [ ] PancakeSwap listing
- [ ] Uniswap listing
- [ ] CEX partnerships

### Phase 4: Ecosystem 🌍
- [ ] Cross-chain bridges
- [ ] DeFi protocols
- [ ] NFT marketplace
- [ ] DAO governance

## 📞 Support

- **Documentation**: [docs/](docs/)
- **Issues**: [GitHub Issues](https://github.com/your-username/usdtg-blockchain/issues)
- **Discord**: [Join our community](https://discord.gg/usdtg)

---

**Built with ❤️ by the USDTg Team**

*The future of decentralized finance starts here!* 🚀
