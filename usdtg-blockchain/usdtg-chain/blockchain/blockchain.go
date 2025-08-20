package blockchain

import (
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"strconv"
	"sync"
	"time"
)

// Block represents a single block in the blockchain
type Block struct {
	Index        int           `json:"index"`
	Timestamp    time.Time     `json:"timestamp"`
	Transactions []Transaction `json:"transactions"`
	PrevHash     string        `json:"prev_hash"`
	Hash         string        `json:"hash"`
	Nonce        int           `json:"nonce"`
	Difficulty   int           `json:"difficulty"`
}

// Transaction represents a single transaction
type Transaction struct {
	From      string    `json:"from"`
	To        string    `json:"to"`
	Amount    float64   `json:"amount"`
	Token     string    `json:"token"`
	Timestamp time.Time `json:"timestamp"`
	Hash      string    `json:"hash"`
}

// Blockchain represents the main blockchain structure
type Blockchain struct {
	Chain        []Block       `json:"chain"`
	PendingTx    []Transaction `json:"pending_tx"`
	Difficulty   int           `json:"difficulty"`
	MiningReward float64       `json:"mining_reward"`
	mu           sync.RWMutex
}

// NewBlockchain creates a new blockchain
func NewBlockchain() *Blockchain {
	bc := &Blockchain{
		Difficulty:   0, // INSTANT mining - difficulty 0
		MiningReward: 100.0,
	}

	// Create genesis block
	bc.CreateGenesisBlock()
	return bc
}

// CreateGenesisBlock creates the first block
func (bc *Blockchain) CreateGenesisBlock() {
	genesisBlock := Block{
		Index:        0,
		Timestamp:    time.Now(),
		Transactions: []Transaction{},
		PrevHash:     "0",
		Difficulty:   bc.Difficulty,
	}

	genesisBlock.Hash = bc.CalculateHash(genesisBlock)
	bc.Chain = append(bc.Chain, genesisBlock)
}

// GetLatestBlock returns the most recent block
func (bc *Blockchain) GetLatestBlock() Block {
	bc.mu.RLock()
	defer bc.mu.RUnlock()

	if len(bc.Chain) == 0 {
		return Block{}
	}
	return bc.Chain[len(bc.Chain)-1]
}

// AddTransaction adds a new transaction to pending transactions
func (bc *Blockchain) AddTransaction(from, to string, amount float64, token string) {
	tx := Transaction{
		From:      from,
		To:        to,
		Amount:    amount,
		Token:     token,
		Timestamp: time.Now(),
	}

	tx.Hash = bc.CalculateTransactionHash(tx)

	bc.mu.Lock()
	bc.PendingTx = append(bc.PendingTx, tx)
	bc.mu.Unlock()
}

// MinePendingTransactions mines a new block with pending transactions
func (bc *Blockchain) MinePendingTransactions(minerAddress string) Block {
	// Get latest block (no mutex for simplicity)
	latestBlock := bc.GetLatestBlock()
	
	// Simple lock for pending transactions
	bc.mu.Lock()
	pendingTx := make([]Transaction, len(bc.PendingTx))
	copy(pendingTx, bc.PendingTx)
	bc.PendingTx = []Transaction{} // Clear immediately
	bc.mu.Unlock()

	// Create mining reward transaction
	rewardTx := Transaction{
		From:      "system",
		To:        minerAddress,
		Amount:    bc.MiningReward,
		Token:     "USDTg",
		Timestamp: time.Now(),
	}
	rewardTx.Hash = bc.CalculateTransactionHash(rewardTx)

	// Create new block - INSTANT, NO MINING
	newBlock := Block{
		Index:        latestBlock.Index + 1,
		Timestamp:    time.Now(),
		Transactions: append(pendingTx, rewardTx),
		PrevHash:     latestBlock.Hash,
		Difficulty:   0, // PoS - mining yok
		Nonce:        0, // PoS - nonce yok
	}

	// INSTANT block creation - NO MINING
	newBlock.Hash = bc.CalculateHash(newBlock)

	// Add to chain (with mutex)
	bc.mu.Lock()
	bc.Chain = append(bc.Chain, newBlock)
	bc.mu.Unlock()

	return newBlock
}

// MineBlock - PoS için kullanılmıyor
func (bc *Blockchain) MineBlock(block Block) Block {
	// PoS - mining yok, sadece hash hesapla
	block.Hash = bc.CalculateHash(block)
	return block
}

// CalculateHash calculates the hash of a block
func (bc *Blockchain) CalculateHash(block Block) string {
	record := strconv.Itoa(block.Index) + block.Timestamp.String() +
		bc.TransactionsToString(block.Transactions) + block.PrevHash +
		strconv.Itoa(block.Nonce) + strconv.Itoa(block.Difficulty)

	h := sha256.New()
	h.Write([]byte(record))
	hashed := h.Sum(nil)
	return hex.EncodeToString(hashed)
}

// CalculateTransactionHash calculates the hash of a transaction
func (bc *Blockchain) CalculateTransactionHash(tx Transaction) string {
	record := tx.From + tx.To + fmt.Sprintf("%f", tx.Amount) +
		tx.Token + tx.Timestamp.String()

	h := sha256.New()
	h.Write([]byte(record))
	hashed := h.Sum(nil)
	return hex.EncodeToString(hashed)
}

// TransactionsToString converts transactions to string for hashing
func (bc *Blockchain) TransactionsToString(transactions []Transaction) string {
	var result string
	for _, tx := range transactions {
		result += tx.From + tx.To + fmt.Sprintf("%f", tx.Amount) + tx.Token
	}
	return result
}

// IsChainValid validates the entire blockchain
func (bc *Blockchain) IsChainValid() bool {
	bc.mu.RLock()
	defer bc.mu.RUnlock()

	for i := 1; i < len(bc.Chain); i++ {
		currentBlock := bc.Chain[i]
		previousBlock := bc.Chain[i-1]

		// Check if current block hash is valid
		if currentBlock.Hash != bc.CalculateHash(currentBlock) {
			return false
		}

		// Check if previous block hash is correct
		if currentBlock.PrevHash != previousBlock.Hash {
			return false
		}
	}

	return true
}

// GetBalance returns the balance of an address
func (bc *Blockchain) GetBalance(address string) map[string]float64 {
	bc.mu.RLock()
	defer bc.mu.RUnlock()

	balance := make(map[string]float64)

	for _, block := range bc.Chain {
		for _, tx := range block.Transactions {
			if tx.From == address {
				balance[tx.Token] -= tx.Amount
			}
			if tx.To == address {
				balance[tx.Token] += tx.Amount
			}
		}
	}

	return balance
}

// GetBlockByIndex returns a block by its index
func (bc *Blockchain) GetBlockByIndex(index int) (Block, error) {
	bc.mu.RLock()
	defer bc.mu.RUnlock()

	if index < 0 || index >= len(bc.Chain) {
		return Block{}, fmt.Errorf("block index out of range")
	}

	return bc.Chain[index], nil
}

// GetBlockchainInfo returns information about the blockchain
func (bc *Blockchain) GetBlockchainInfo() map[string]interface{} {
	bc.mu.RLock()
	defer bc.mu.RUnlock()

	latestBlock := bc.GetLatestBlock()

	info := map[string]interface{}{
		"total_blocks":      len(bc.Chain),
		"latest_block":      latestBlock.Index,
		"pending_tx":        len(bc.PendingTx),
		"difficulty":        bc.Difficulty,
		"mining_reward":     bc.MiningReward,
		"is_valid":          bc.IsChainValid(),
		"latest_block_hash": latestBlock.Hash,
	}

	return info
}

// ToJSON converts the blockchain to JSON
func (bc *Blockchain) ToJSON() ([]byte, error) {
	bc.mu.RLock()
	defer bc.mu.RUnlock()

	return json.MarshalIndent(bc, "", "  ")
}
