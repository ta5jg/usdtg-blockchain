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

class TokenClient {
  constructor(serverAddress = 'localhost:50051') {
    this.client = new tokenProto.TokenService(
      serverAddress,
      grpc.credentials.createInsecure()
    );
    this.serverAddress = serverAddress;
  }

  // Bakiye sorgulama
  async getBalance(address) {
    return new Promise((resolve, reject) => {
      this.client.getBalance({ address }, (error, response) => {
        if (error) {
          reject(error);
        } else {
          resolve(response);
        }
      });
    });
  }

  // Transfer işlemi
  async transfer(fromAddress, toAddress, denom, amount) {
    return new Promise((resolve, reject) => {
      this.client.transfer({
        from_address: fromAddress,
        to_address: toAddress,
        denom,
        amount
      }, (error, response) => {
        if (error) {
          reject(error);
        } else {
          resolve(response);
        }
      });
    });
  }

  // Token mint işlemi
  async mint(toAddress, denom, amount) {
    return new Promise((resolve, reject) => {
      this.client.mint({
        to_address: toAddress,
        denom,
        amount
      }, (error, response) => {
        if (error) {
          reject(error);
        } else {
          resolve(response);
        }
      });
    });
  }

  // Bağlantıyı kapat
  close() {
    this.client.close();
  }
}

// Demo fonksiyonları
async function demoGetBalance(client) {
  try {
    console.log('\n💰 Bakiye Sorgulama Demo:');
    
    const addresses = [
      '0x1234567890abcdef',
      '0xabcdef1234567890',
      '0x9999999999999999' // Olmayan adres
    ];
    
    for (const address of addresses) {
      const balance = await client.getBalance(address);
      console.log(`📍 ${address}: ${balance.amount} ${balance.denom}`);
    }
  } catch (error) {
    console.error('❌ Bakiye sorgulama hatası:', error.message);
  }
}

async function demoTransfer(client) {
  try {
    console.log('\n🔄 Transfer Demo:');
    
    const fromAddress = '0x1234567890abcdef';
    const toAddress = '0xabcdef1234567890';
    const amount = 100;
    const denom = 'USDTg';
    
    console.log(`📤 Transfer: ${fromAddress} -> ${toAddress} ${amount} ${denom}`);
    
    const result = await client.transfer(fromAddress, toAddress, denom, amount);
    console.log(`✅ Transfer başarılı! TX Hash: ${result.tx_hash}`);
    
    // Transfer sonrası bakiyeleri kontrol et
    console.log('\n📊 Transfer sonrası bakiyeler:');
    const fromBalance = await client.getBalance(fromAddress);
    const toBalance = await client.getBalance(toAddress);
    
    console.log(`📍 ${fromAddress}: ${fromBalance.amount} ${fromBalance.denom}`);
    console.log(`📍 ${toAddress}: ${toBalance.amount} ${toBalance.denom}`);
    
  } catch (error) {
    console.error('❌ Transfer hatası:', error.message);
  }
}

async function demoMint(client) {
  try {
    console.log('\n🪙 Mint Demo:');
    
    const toAddress = '0x9999999999999999';
    const amount = 500;
    const denom = 'USDTg';
    
    console.log(`🪙 Mint: ${toAddress} ${amount} ${denom}`);
    
    const result = await client.mint(toAddress, denom, amount);
    console.log(`✅ Mint başarılı! TX Hash: ${result.tx_hash}`);
    
    // Mint sonrası bakiyeyi kontrol et
    const balance = await client.getBalance(toAddress);
    console.log(`📍 Yeni bakiye: ${balance.amount} ${balance.denom}`);
    
  } catch (error) {
    console.error('❌ Mint hatası:', error.message);
  }
}

// Ana demo fonksiyonu
async function runDemo() {
  const client = new TokenClient();
  
  try {
    console.log('🚀 gRPC Token Client Demo Başlatılıyor...');
    console.log(`📍 Sunucu: ${client.serverAddress}`);
    
    await demoGetBalance(client);
    await demoTransfer(client);
    await demoMint(client);
    
    console.log('\n🎉 Demo tamamlandı!');
    
  } catch (error) {
    console.error('❌ Demo hatası:', error);
  } finally {
    client.close();
  }
}

// Test fonksiyonu
async function testConnection() {
  const client = new TokenClient();
  
  try {
    console.log('🔍 Sunucu bağlantısı test ediliyor...');
    
    // Basit bir bakiye sorgusu ile bağlantıyı test et
    await client.getBalance('0x1234567890abcdef');
    console.log('✅ Sunucu bağlantısı başarılı!');
    
  } catch (error) {
    console.error('❌ Sunucu bağlantısı başarısız:', error.message);
    console.log('💡 Sunucunun çalıştığından emin olun: node src/server/token-server.js');
  } finally {
    client.close();
  }
}

if (require.main === module) {
  const command = process.argv[2];
  
  switch (command) {
    case 'demo':
      runDemo();
      break;
    case 'test':
      testConnection();
      break;
    default:
      console.log('Kullanım:');
      console.log('  node src/client/token-client.js demo  - Demo çalıştır');
      console.log('  node src/client/token-client.js test  - Bağlantı test et');
      break;
  }
}

module.exports = { TokenClient, runDemo, testConnection };
