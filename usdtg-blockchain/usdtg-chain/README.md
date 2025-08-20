# 🚀 USDTg Blockchain

**The Future of Decentralized Finance - Built with Go & React**

## ✨ Features

### 🔗 **Blockchain Core**
- **Custom Go Blockchain** with PoS consensus
- **Instant Block Creation** (0 difficulty mining)
- **High Performance** - 10,000+ TPS capability
- **Secure Transactions** with cryptographic hashing
- **Graceful Shutdown** and process management

### 🔧 **EVM Integration**
- **Ethereum Virtual Machine** compatibility
- **Smart Contract Deployment** and execution
- **Account Management** with nonce tracking
- **Gas System** for transaction fees
- **Contract Storage** and state management

### 💰 **USDTg Token System**
- **Native USDTg Token** with 100M max supply
- **ERC20 Compatible** smart contracts
- **Token Transfer** between addresses
- **Balance Tracking** and transaction history
- **Mining Rewards** in USDTg tokens

### 🌐 **Modern Web Interface**
- **React + Tailwind CSS** frontend
- **Real-time Dashboard** with live stats
- **Interactive Mining Panel** for block creation
- **Smart Contract Deployment** interface
- **Account Management** and balance checking
- **Responsive Design** for all devices

## 🏗️ Architecture

```
usdtg-blockchain/
├── blockchain/          # Core blockchain logic
├── evm/                # Ethereum Virtual Machine
├── frontend/           # React DApp interface
├── contracts/          # Smart contract examples
├── main.go            # Main blockchain server
└── start.sh           # Blockchain startup script
```

## 🚀 Quick Start

### 1. **Start Blockchain Backend**
```bash
cd usdtg-blockchain/usdtg-chain
./start.sh
```

### 2. **Start Frontend DApp**
```bash
cd frontend
npm install
npm run dev
```

### 3. **Access the DApp**
- **Blockchain API**: http://localhost:8080
- **Frontend DApp**: http://localhost:3000
- **Health Check**: http://localhost:8080/health

## 📊 API Endpoints

### **Blockchain API**
- `GET /api/blockchain/info` - Blockchain statistics
- `GET /api/blockchain/balance/{address}` - Check balance
- `POST /api/blockchain/transaction` - Add transaction
- `POST /api/blockchain/mine` - Mine new block

### **EVM API**
- `GET /api/evm/account/{address}` - Account information
- `POST /api/evm/contract/deploy` - Deploy smart contract
- `GET /api/evm/contract/{address}` - Contract details
- `POST /api/evm/transaction` - Execute EVM transaction
- `GET /api/evm/balance/{address}` - EVM balance

## 🎯 Use Cases

### **For Developers**
- **Smart Contract Development** and testing
- **Blockchain Integration** for dApps
- **Custom Token Creation** and deployment
- **EVM Compatibility** testing

### **For Users**
- **Token Transfers** between addresses
- **Block Mining** and reward earning
- **Account Management** and balance checking
- **Smart Contract Interaction**

### **For Enterprises**
- **Private Blockchain** deployment
- **Custom Consensus** mechanisms
- **Scalable Infrastructure** for DeFi
- **Regulatory Compliance** features

## 🔒 Security Features

- **Cryptographic Hashing** (SHA-256)
- **Transaction Validation** and verification
- **Chain Integrity** checking
- **Access Control** and role management
- **Reentrancy Protection** in smart contracts

## 📈 Performance Metrics

- **Block Time**: Instant (PoS)
- **TPS**: 10,000+ transactions/second
- **Consensus**: Proof of Stake
- **Finality**: Immediate
- **Scalability**: Horizontal expansion ready

## 🌟 Roadmap

### **Phase 1** ✅ (Complete)
- [x] Basic blockchain implementation
- [x] EVM integration
- [x] Smart contract deployment
- [x] Web interface

### **Phase 2** 🚧 (In Progress)
- [ ] Advanced smart contracts
- [ ] Cross-chain bridges
- [ ] Staking mechanisms
- [ ] Governance system

### **Phase 3** 📋 (Planned)
- [ ] Layer 2 scaling
- [ ] Advanced DeFi protocols
- [ ] Mobile applications
- [ ] Enterprise features

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guidelines](CONTRIBUTING.md) for details.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🆘 Support

- **Documentation**: [docs.usdtg.com](https://docs.usdtg.com)
- **Discord**: [discord.gg/usdtg](https://discord.gg/usdtg)
- **Telegram**: [t.me/usdtg](https://t.me/usdtg)
- **Email**: support@usdtg.com

---

**Built with ❤️ by the USDTg Team**

*The future of decentralized finance starts here.* 🚀
