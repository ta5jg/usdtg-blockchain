package evm

import (
	"crypto/sha256"
	"encoding/hex"
	"fmt"
	"math/big"
	"sync"
)

// EVM represents a simplified Ethereum Virtual Machine
type EVM struct {
	StateDB    *StateDB
	ChainID    *big.Int
	mu         sync.RWMutex
}

// StateDB represents the blockchain state database
type StateDB struct {
	Accounts map[string]*Account
	Storage  map[string]map[string]string
	mu       sync.RWMutex
}

// Account represents an Ethereum account
type Account struct {
	Address   string   `json:"address"`
	Nonce     uint64   `json:"nonce"`
	Balance   *big.Int `json:"balance"`
	Code      []byte   `json:"code"`
	CodeHash  string   `json:"code_hash"`
	Storage   map[string]string `json:"storage"`
}

// Transaction represents an EVM transaction
type EVMTransaction struct {
	From     string   `json:"from"`
	To       string   `json:"to"`
	Value    *big.Int `json:"value"`
	Data     []byte   `json:"data"`
	Gas      uint64   `json:"gas"`
	GasPrice *big.Int `json:"gas_price"`
	Nonce    uint64   `json:"nonce"`
	Hash     string   `json:"hash"`
}

// Contract represents a smart contract
type Contract struct {
	Address   string   `json:"address"`
	Code      []byte   `json:"code"`
	ABI       string   `json:"abi"`
	Balance   *big.Int `json:"balance"`
	CodeHash  string   `json:"code_hash"`
}

// TransactionResult represents the result of a transaction
type TransactionResult struct {
	Success  bool   `json:"success"`
	GasUsed  uint64 `json:"gas_used"`
	Error    string `json:"error,omitempty"`
	Return   []byte `json:"return,omitempty"`
}

// NewEVM creates a new simplified EVM instance
func NewEVM() *EVM {
	return &EVM{
		StateDB: &StateDB{
			Accounts: make(map[string]*Account),
			Storage:  make(map[string]map[string]string),
		},
		ChainID: big.NewInt(1337), // USDTg Chain ID
	}
}

// CreateAccount creates a new account
func (e *EVM) CreateAccount(address string) {
	e.StateDB.mu.Lock()
	defer e.StateDB.mu.Unlock()

	if _, exists := e.StateDB.Accounts[address]; !exists {
		e.StateDB.Accounts[address] = &Account{
			Address:  address,
			Nonce:    0,
			Balance:  big.NewInt(0),
			Code:     []byte{},
			CodeHash: "",
			Storage:  make(map[string]string),
		}
	}
}

// DeployContract deploys a smart contract
func (e *EVM) DeployContract(from, code string, value *big.Int) (*Contract, error) {
	e.StateDB.mu.Lock()
	defer e.StateDB.mu.Unlock()

	// Generate contract address
	contractAddr := e.generateContractAddress(from, e.StateDB.Accounts[from].Nonce)
	
	// Create contract account
	e.StateDB.Accounts[contractAddr] = &Account{
		Address:  contractAddr,
		Nonce:    0,
		Balance:  value,
		Code:     []byte(code),
		CodeHash: e.calculateHash([]byte(code)),
		Storage:  make(map[string]string),
	}

	// Update sender account
	e.StateDB.Accounts[from].Nonce++
	if e.StateDB.Accounts[from].Balance.Cmp(value) < 0 {
		return nil, fmt.Errorf("insufficient balance")
	}
	e.StateDB.Accounts[from].Balance.Sub(e.StateDB.Accounts[from].Balance, value)

	contract := &Contract{
		Address:   contractAddr,
		Code:      []byte(code),
		ABI:       "", // ABI will be set separately
		Balance:   value,
		CodeHash:  e.calculateHash([]byte(code)),
	}

	return contract, nil
}

// ExecuteTransaction executes an EVM transaction
func (e *EVM) ExecuteTransaction(tx *EVMTransaction) (*TransactionResult, error) {
	e.StateDB.mu.Lock()
	defer e.StateDB.mu.Unlock()

	// Validate transaction
	if err := e.validateTransaction(tx); err != nil {
		return nil, err
	}

	// Simple transaction execution
	result := &TransactionResult{
		Success:  true,
		GasUsed:  tx.Gas,
		Return:   []byte{},
	}

	// Update accounts
	if e.StateDB.Accounts[tx.From] != nil {
		e.StateDB.Accounts[tx.From].Nonce++
		e.StateDB.Accounts[tx.From].Balance.Sub(e.StateDB.Accounts[tx.From].Balance, tx.Value)
	}

	if e.StateDB.Accounts[tx.To] != nil {
		e.StateDB.Accounts[tx.To].Balance.Add(e.StateDB.Accounts[tx.To].Balance, tx.Value)
	}

	return result, nil
}

// validateTransaction validates a transaction
func (e *EVM) validateTransaction(tx *EVMTransaction) error {
	// Check if sender account exists
	if _, exists := e.StateDB.Accounts[tx.From]; !exists {
		return fmt.Errorf("sender account does not exist")
	}

	// Check nonce
	if e.StateDB.Accounts[tx.From].Nonce != tx.Nonce {
		return fmt.Errorf("invalid nonce")
	}

	// Check balance
	totalCost := new(big.Int).Mul(tx.GasPrice, big.NewInt(int64(tx.Gas)))
	totalCost.Add(totalCost, tx.Value)
	if e.StateDB.Accounts[tx.From].Balance.Cmp(totalCost) < 0 {
		return fmt.Errorf("insufficient balance")
	}

	return nil
}

// generateContractAddress generates a contract address
func (e *EVM) generateContractAddress(from string, nonce uint64) string {
	data := fmt.Sprintf("%s%d", from, nonce)
	hash := sha256.Sum256([]byte(data))
	return "0x" + hex.EncodeToString(hash[:20])
}

// calculateHash calculates hash of data
func (e *EVM) calculateHash(data []byte) string {
	hash := sha256.Sum256(data)
	return hex.EncodeToString(hash[:])
}

// GetAccount returns an account by address
func (e *EVM) GetAccount(address string) *Account {
	e.StateDB.mu.RLock()
	defer e.StateDB.mu.RUnlock()
	return e.StateDB.Accounts[address]
}

// GetBalance returns the balance of an account
func (e *EVM) GetBalance(address string) *big.Int {
	account := e.GetAccount(address)
	if account == nil {
		return big.NewInt(0)
	}
	return account.Balance
}

// AddBalance adds balance to an account
func (e *EVM) AddBalance(address string, amount *big.Int) {
	e.StateDB.mu.Lock()
	defer e.StateDB.mu.Unlock()

	if _, exists := e.StateDB.Accounts[address]; !exists {
		e.CreateAccount(address)
	}
	
	e.StateDB.Accounts[address].Balance.Add(e.StateDB.Accounts[address].Balance, amount)
}

// GetContract returns a contract by address
func (e *EVM) GetContract(address string) *Contract {
	account := e.GetAccount(address)
	if account == nil || len(account.Code) == 0 {
		return nil
	}

	return &Contract{
		Address: address,
		Code:    account.Code,
		ABI:     "", // ABI will be set separately
		Balance: account.Balance,
	}
}
