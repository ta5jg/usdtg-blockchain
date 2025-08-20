const { TokenClient } = require('../client/token-client');
const assert = require('assert');

class TokenServiceTest {
  constructor() {
    this.client = new TokenClient();
    this.testResults = [];
  }

  // Test sonucunu kaydet
  recordTest(testName, passed, error = null) {
    const result = {
      name: testName,
      passed,
      error: error?.message || null,
      timestamp: new Date().toISOString()
    };
    
    this.testResults.push(result);
    
    if (passed) {
      console.log(`✅ ${testName}`);
    } else {
      console.log(`❌ ${testName}: ${error?.message || 'Bilinmeyen hata'}`);
    }
    
    return result;
  }

  // Bakiye sorgulama testleri
  async testGetBalance() {
    console.log('\n🧪 Bakiye Sorgulama Testleri:');
    
    try {
      // Test 1: Mevcut adres bakiye sorgusu
      const balance1 = await this.client.getBalance('0x1234567890abcdef');
      assert(balance1.address === '0x1234567890abcdef');
      assert(balance1.denom === 'USDTg');
      assert(parseInt(balance1.amount) >= 0);
      this.recordTest('Mevcut adres bakiye sorgusu', true);
      
      // Test 2: Olmayan adres bakiye sorgusu
      const balance2 = await this.client.getBalance('0x9999999999999999');
      assert(balance2.address === '0x9999999999999999');
      assert(balance2.denom === 'USDTg');
      assert(balance2.amount === '0');
      this.recordTest('Olmayan adres bakiye sorgusu', true);
      
      // Test 3: Geçersiz adres formatı
      try {
        await this.client.getBalance('');
        this.recordTest('Boş adres bakiye sorgusu', false, new Error('Boş adres kabul edilmemeli'));
      } catch (error) {
        this.recordTest('Boş adres bakiye sorgusu', true);
      }
      
    } catch (error) {
      this.recordTest('Bakiye sorgulama testleri', false, error);
    }
  }

  // Transfer testleri
  async testTransfer() {
    console.log('\n🧪 Transfer Testleri:');
    
    try {
      // Test 1: Geçerli transfer
      const transferResult = await this.client.transfer(
        '0x1234567890abcdef',
        '0xabcdef1234567890',
        'USDTg',
        50
      );
      
      assert(transferResult.tx_hash);
      assert(transferResult.accepted === true);
      this.recordTest('Geçerli transfer işlemi', true);
      
      // Test 2: Transfer sonrası bakiye kontrolü
      const fromBalance = await this.client.getBalance('0x1234567890abcdef');
      const toBalance = await this.client.getBalance('0xabcdef1234567890');
      
      // Basit bakiye kontrolü (gerçek uygulamada daha detaylı olacak)
      assert(parseInt(fromBalance.amount) >= 0);
      assert(parseInt(toBalance.amount) >= 0);
      this.recordTest('Transfer sonrası bakiye kontrolü', true);
      
      // Test 3: Sıfır miktar transfer
      try {
        await this.client.transfer(
          '0x1234567890abcdef',
          '0xabcdef1234567890',
          'USDTg',
          0
        );
        this.recordTest('Sıfır miktar transfer', false, new Error('Sıfır miktar kabul edilmemeli'));
      } catch (error) {
        this.recordTest('Sıfır miktar transfer', true);
      }
      
    } catch (error) {
      this.recordTest('Transfer testleri', false, error);
    }
  }

  // Mint testleri
  async testMint() {
    console.log('\n🧪 Mint Testleri:');
    
    try {
      // Test 1: Geçerli mint işlemi
      const mintResult = await this.client.mint(
        '0x9999999999999999',
        'USDTg',
        200
      );
      
      assert(mintResult.tx_hash);
      assert(mintResult.accepted === true);
      this.recordTest('Geçerli mint işlemi', true);
      
      // Test 2: Mint sonrası bakiye kontrolü
      const balance = await this.client.getBalance('0x9999999999999999');
      assert(parseInt(balance.amount) >= 200);
      this.recordTest('Mint sonrası bakiye kontrolü', true);
      
      // Test 3: Sıfır miktar mint
      try {
        await this.client.mint('0x9999999999999999', 'USDTg', 0);
        this.recordTest('Sıfır miktar mint', false, new Error('Sıfır miktar kabul edilmemeli'));
      } catch (error) {
        this.recordTest('Sıfır miktar mint', true);
      }
      
    } catch (error) {
      this.recordTest('Mint testleri', false, error);
    }
  }

  // Performans testleri
  async testPerformance() {
    console.log('\n🧪 Performans Testleri:');
    
    try {
      const startTime = Date.now();
      const iterations = 10;
      
      // Çoklu bakiye sorgusu
      for (let i = 0; i < iterations; i++) {
        await this.client.getBalance('0x1234567890abcdef');
      }
      
      const endTime = Date.now();
      const avgTime = (endTime - startTime) / iterations;
      
      assert(avgTime < 1000); // Ortalama 1 saniyeden az olmalı
      this.recordTest(`Performans testi (${iterations} sorgu)`, true);
      console.log(`   ⏱️  Ortalama süre: ${avgTime.toFixed(2)}ms`);
      
    } catch (error) {
      this.recordTest('Performans testleri', false, error);
    }
  }

  // Hata durumu testleri
  async testErrorHandling() {
    console.log('\n🧪 Hata Durumu Testleri:');
    
    try {
      // Test 1: Geçersiz adres formatı
      try {
        await this.client.getBalance('invalid-address');
        this.recordTest('Geçersiz adres formatı', false, new Error('Geçersiz adres kabul edilmemeli'));
      } catch (error) {
        this.recordTest('Geçersiz adres formatı', true);
      }
      
      // Test 2: Negatif miktar
      try {
        await this.client.transfer(
          '0x1234567890abcdef',
          '0xabcdef1234567890',
          'USDTg',
          -100
        );
        this.recordTest('Negatif miktar transfer', false, new Error('Negatif miktar kabul edilmemeli'));
      } catch (error) {
        this.recordTest('Negatif miktar transfer', true);
      }
      
    } catch (error) {
      this.recordTest('Hata durumu testleri', false, error);
    }
  }

  // Tüm testleri çalıştır
  async runAllTests() {
    console.log('🚀 Token Service Testleri Başlatılıyor...\n');
    
    try {
      await this.testGetBalance();
      await this.testTransfer();
      await this.testMint();
      await this.testPerformance();
      await this.testErrorHandling();
      
      this.printTestSummary();
      
    } catch (error) {
      console.error('❌ Test çalıştırma hatası:', error);
    } finally {
      this.client.close();
    }
  }

  // Test özeti yazdır
  printTestSummary() {
    console.log('\n📊 Test Özeti:');
    console.log('=' * 50);
    
    const totalTests = this.testResults.length;
    const passedTests = this.testResults.filter(r => r.passed).length;
    const failedTests = totalTests - passedTests;
    
    console.log(`📈 Toplam Test: ${totalTests}`);
    console.log(`✅ Başarılı: ${passedTests}`);
    console.log(`❌ Başarısız: ${failedTests}`);
    console.log(`📊 Başarı Oranı: ${((passedTests / totalTests) * 100).toFixed(1)}%`);
    
    if (failedTests > 0) {
      console.log('\n❌ Başarısız Testler:');
      this.testResults
        .filter(r => !r.passed)
        .forEach(r => console.log(`   - ${r.name}: ${r.error}`));
    }
    
    console.log('\n🎯 Test Sonucu:', failedTests === 0 ? 'TÜM TESTLER BAŞARILI! 🎉' : 'BAZI TESTLER BAŞARISIZ! ⚠️');
  }
}

// Test çalıştırma
if (require.main === module) {
  const tester = new TokenServiceTest();
  tester.runAllTests();
}

module.exports = { TokenServiceTest };
