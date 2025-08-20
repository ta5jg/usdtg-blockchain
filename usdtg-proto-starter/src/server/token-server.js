const grpc = require('@grpc/grpc-js');
const protoLoader = require('@grpc/proto-loader');
const path = require('path');

// Proto dosyasını yükle
const PROTO_PATH = path.join(__dirname, '../../usdtg/token/v1/token.proto');

const packageDefinition = protoLoader.loadSync(PROTO_PATH, {
  keepCase: true,
  longs: String,
  enums: String,
  defaults: true,
  oneofs: true
});

const tokenProto = grpc.loadPackageDefinition(packageDefinition).usdtg.token.v1;

// Mock veritabanı (gerçek uygulamada PostgreSQL kullanılacak)
const mockBalances = new Map();
const mockTransactions = new Map();

// TokenService implementasyonu
const tokenService = {
  // Bakiye sorgulama
  getBalance: (call, callback) => {
    try {
      const { address } = call.request;
      console.log(`Bakiye sorgusu: ${address}`);
      
      const balance = mockBalances.get(address) || {
        address,
        denom: 'USDTg',
        amount: '0',
        as_of: {
          seconds: Math.floor(Date.now() / 1000),
          nanos: 0
        }
      };
      
      callback(null, balance);
    } catch (error) {
      callback({
        code: grpc.status.INTERNAL,
        message: 'Bakiye sorgulanırken hata oluştu'
      });
    }
  },

  // Transfer işlemi
  transfer: (call, callback) => {
    try {
      const { from_address, to_address, denom, amount } = call.request;
      console.log(`Transfer: ${from_address} -> ${to_address} ${amount} ${denom}`);
      
      // Basit validasyon
      if (amount <= 0) {
        return callback({
          code: grpc.status.INVALID_ARGUMENT,
          message: 'Transfer miktarı 0\'dan büyük olmalıdır'
        });
      }
      
      // Mock transfer işlemi
      const txHash = `tx_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
      mockTransactions.set(txHash, {
        from: from_address,
        to: to_address,
        amount,
        denom,
        timestamp: new Date().toISOString()
      });
      
      callback(null, {
        tx_hash: txHash,
        accepted: true
      });
    } catch (error) {
      callback({
        code: grpc.status.INTERNAL,
        message: 'Transfer işlemi sırasında hata oluştu'
      });
    }
  },

  // Token mint işlemi
  mint: (call, callback) => {
    try {
      const { to_address, denom, amount } = call.request;
      console.log(`Mint: ${to_address} ${amount} ${denom}`);
      
      // Basit validasyon
      if (amount <= 0) {
        return callback({
          code: grpc.status.INVALID_ARGUMENT,
          message: 'Mint miktarı 0\'dan büyük olmalıdır'
        });
      }
      
      // Mock mint işlemi
      const txHash = `mint_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
      mockTransactions.set(txHash, {
        type: 'mint',
        to: to_address,
        amount,
        denom,
        timestamp: new Date().toISOString()
      });
      
      // Bakiyeyi güncelle
      const currentBalance = mockBalances.get(to_address) || { amount: '0' };
      const newAmount = parseInt(currentBalance.amount) + parseInt(amount);
      mockBalances.set(to_address, {
        address: to_address,
        denom,
        amount: newAmount.toString(),
        as_of: {
          seconds: Math.floor(Date.now() / 1000),
          nanos: 0
        }
      });
      
      callback(null, {
        tx_hash: txHash,
        accepted: true
      });
    } catch (error) {
      callback({
        code: grpc.status.INTERNAL,
        message: 'Mint işlemi sırasında hata oluştu'
      });
    }
  }
};

// Sunucuyu başlat
function startServer() {
  const server = new grpc.Server();
  
  server.addService(tokenProto.TokenService.service, tokenService);
  
  const port = process.env.GRPC_PORT || 50051;
  server.bindAsync(
    `0.0.0.0:${port}`,
    grpc.ServerCredentials.createInsecure(),
    (err, port) => {
      if (err) {
        console.error('Sunucu başlatılamadı:', err);
        return;
      }
      
      console.log(`🚀 gRPC Token Sunucusu başlatıldı - Port: ${port}`);
      console.log(`📍 Sunucu adresi: 0.0.0.0:${port}`);
      console.log('📋 Kullanılabilir servisler:');
      console.log('   - getBalance(address)');
      console.log('   - transfer(from, to, denom, amount)');
      console.log('   - mint(to, denom, amount)');
      
      server.start();
    }
  );
}

// Test verisi ekle
function addTestData() {
  mockBalances.set('0x1234567890abcdef', {
    address: '0x1234567890abcdef',
    denom: 'USDTg',
    amount: '1000',
    as_of: {
      seconds: Math.floor(Date.now() / 1000),
      nanos: 0
    }
  });
  
  mockBalances.set('0xabcdef1234567890', {
    address: '0xabcdef1234567890',
    denom: 'USDTg',
    amount: '500',
    as_of: {
      seconds: Math.floor(Date.now() / 1000),
      nanos: 0
    }
  });
  
  console.log('🧪 Test verileri eklendi');
}

if (require.main === module) {
  addTestData();
  startServer();
}

module.exports = { tokenService, startServer, addTestData };
