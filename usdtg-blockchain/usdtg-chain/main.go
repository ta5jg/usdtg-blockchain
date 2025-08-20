package main

import (
	"encoding/json"
	"fmt"
	"log"
	"math/big"
	"net/http"
	"strconv"
	"time"

	"usdtg-chain/blockchain"
	"usdtg-chain/evm"

	"github.com/gorilla/mux"
)

var bc *blockchain.Blockchain
var evmInstance *evm.EVM

func StartServer() {
	fmt.Println("🚀 USDTg Blockchain başlatılıyor...")

	// Blockchain'i başlat
	bc = blockchain.NewBlockchain()

	// EVM'i başlat
	evmInstance = evm.NewEVM()

	// Router oluştur
	r := mux.NewRouter()

	// CORS middleware
	r.Use(corsMiddleware)

	// Blockchain API endpoint'leri
	r.HandleFunc("/", homeHandler).Methods("GET", "OPTIONS")
	r.HandleFunc("/api/status", statusHandler).Methods("GET", "OPTIONS")
	r.HandleFunc("/api/blockchain", blockchainHandler).Methods("GET", "OPTIONS")
	r.HandleFunc("/api/blockchain/info", blockchainInfoHandler).Methods("GET", "OPTIONS")
	r.HandleFunc("/api/blockchain/balance/{address}", balanceHandler).Methods("GET", "OPTIONS")
	r.HandleFunc("/api/blockchain/block/{index}", blockHandler).Methods("GET", "OPTIONS")
	r.HandleFunc("/api/blockchain/mine", mineHandler).Methods("POST")
	r.HandleFunc("/api/blockchain/mine", optionsHandler).Methods("OPTIONS")
	r.HandleFunc("/api/blockchain/transaction", addTransactionHandler).Methods("POST", "OPTIONS")

	// EVM API endpoint'leri
	r.HandleFunc("/api/evm/account/{address}", evmAccountHandler).Methods("GET", "OPTIONS")
	r.HandleFunc("/api/evm/contract/deploy", evmDeployContractHandler).Methods("POST", "OPTIONS")
	r.HandleFunc("/api/evm/contract/{address}", evmContractHandler).Methods("GET", "OPTIONS")
	r.HandleFunc("/api/evm/transaction", evmTransactionHandler).Methods("POST", "OPTIONS")
	r.HandleFunc("/api/evm/balance/{address}", evmBalanceHandler).Methods("GET", "OPTIONS")
	r.HandleFunc("/api/evm/balance/add", evmAddBalanceHandler).Methods("POST", "OPTIONS")

	// Health check
	r.HandleFunc("/health", healthHandler).Methods("GET", "OPTIONS")

	// Server oluştur
	srv := &http.Server{
		Addr:    ":8080",
		Handler: r,
	}

	// Server'ı başlat
	fmt.Println("🌐 HTTP Server port 8080'de başlatılıyor...")
	fmt.Println("📊 Blockchain API: http://localhost:8080")
	fmt.Println("🏥 Health Check: http://localhost:8080/health")
	fmt.Println("🔗 EVM API: http://localhost:8080/api/evm")

	// Server'ı çalıştır
	fmt.Println("🚀 Server başlatıldı ve çalışıyor...")
	if err := srv.ListenAndServe(); err != nil {
		fmt.Printf("❌ Server hatası: %v\n", err)
		log.Printf("Server hatası: %v", err)
	}
}

// OPTIONS handler for preflight requests
func optionsHandler(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Access-Control-Allow-Origin", "*")
	w.Header().Set("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS")
	w.Header().Set("Access-Control-Allow-Headers", "Content-Type, Authorization, X-Requested-With")
	w.Header().Set("Access-Control-Allow-Credentials", "true")
	w.WriteHeader(http.StatusOK)
}

// CORS middleware
func corsMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		// CORS headers
		w.Header().Set("Access-Control-Allow-Origin", "*")
		w.Header().Set("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS")
		w.Header().Set("Access-Control-Allow-Headers", "Content-Type, Authorization, X-Requested-With")
		w.Header().Set("Access-Control-Allow-Credentials", "true")

		// Handle preflight OPTIONS request
		if r.Method == "OPTIONS" {
			w.WriteHeader(http.StatusOK)
			return
		}

		// Add debug logging
		fmt.Printf("🔍 Request: %s %s\n", r.Method, r.URL.Path)

		next.ServeHTTP(w, r)
	})
}

// Health check handler
func healthHandler(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)

	response := map[string]interface{}{
		"status":           "healthy",
		"timestamp":        time.Now().Format(time.RFC3339),
		"blockchain_valid": bc.IsChainValid(),
		"total_blocks":     len(bc.Chain),
	}

	json.NewEncoder(w).Encode(response)
}

func homeHandler(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)

	response := map[string]interface{}{
		"name":      "USDTg Blockchain",
		"version":   "1.0.0",
		"status":    "running",
		"timestamp": time.Now().Format(time.RFC3339),
		"endpoints": map[string]string{
			"status":          "/api/status",
			"blockchain":      "/api/blockchain",
			"blockchain_info": "/api/blockchain/info",
			"balance":         "/api/blockchain/balance/{address}",
			"block":           "/api/blockchain/block/{index}",
			"mine":            "/api/blockchain/mine",
			"transaction":     "/api/blockchain/transaction",
			"health":          "/health",
		},
		"evm_endpoints": map[string]string{
			"account":         "/api/evm/account/{address}",
			"deploy_contract": "/api/evm/contract/deploy",
			"contract":        "/api/evm/contract/{address}",
			"transaction":     "/api/evm/transaction",
			"balance":         "/api/evm/balance/{address}",
		},
	}

	json.NewEncoder(w).Encode(response)
}

func statusHandler(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)

	response := map[string]interface{}{
		"status":           "healthy",
		"uptime":           "running",
		"version":          "1.0.0",
		"timestamp":        time.Now().Format(time.RFC3339),
		"blockchain_valid": bc.IsChainValid(),
	}

	json.NewEncoder(w).Encode(response)
}

func blockchainHandler(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)

	response := map[string]interface{}{
		"blockchain": map[string]interface{}{
			"name":       "USDTg",
			"consensus":  "PoW",
			"block_time": "5s",
			"tps":        "10000+",
			"features": []string{
				"USDTg Token",
				"Staking",
				"Governance",
				"Cross-chain Bridge",
			},
			"status":               "development",
			"total_blocks":         len(bc.Chain),
			"pending_transactions": len(bc.PendingTx),
		},
		"timestamp": time.Now().Format(time.RFC3339),
	}

	json.NewEncoder(w).Encode(response)
}

func blockchainInfoHandler(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)

	info := bc.GetBlockchainInfo()
	info["timestamp"] = time.Now().Format(time.RFC3339)

	json.NewEncoder(w).Encode(info)
}

func balanceHandler(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")

	vars := mux.Vars(r)
	address := vars["address"]

	balance := bc.GetBalance(address)

	response := map[string]interface{}{
		"address":   address,
		"balance":   balance,
		"timestamp": time.Now().Format(time.RFC3339),
	}

	json.NewEncoder(w).Encode(response)
}

func blockHandler(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")

	vars := mux.Vars(r)
	indexStr := vars["index"]

	index, err := strconv.Atoi(indexStr)
	if err != nil {
		http.Error(w, "Invalid block index", http.StatusBadRequest)
		return
	}

	block, err := bc.GetBlockByIndex(index)
	if err != nil {
		http.Error(w, err.Error(), http.StatusNotFound)
		return
	}

	json.NewEncoder(w).Encode(block)
}

func mineHandler(w http.ResponseWriter, r *http.Request) {
	fmt.Printf("🔍 Mining request received: %s %s\n", r.Method, r.URL.Path)
	fmt.Printf("🔍 Request headers: %v\n", r.Header)

	w.Header().Set("Content-Type", "application/json")

	// Parse request body
	var request struct {
		MinerAddress string `json:"miner_address"`
	}

	if err := json.NewDecoder(r.Body).Decode(&request); err != nil {
		http.Error(w, "Invalid request body", http.StatusBadRequest)
		return
	}

	if request.MinerAddress == "" {
		request.MinerAddress = "anonymous_miner"
	}

	// MOCK RESPONSE - Skip actual mining for now
	fmt.Printf("🔍 Returning mock mining response...\n")

	response := map[string]interface{}{
		"message": "Block mined successfully! (Mock)",
		"block": map[string]interface{}{
			"index":     2,
			"hash":      "0x123456789abcdef",
			"prev_hash": "0x987654321fedcba",
			"timestamp": time.Now().Format(time.RFC3339),
			"miner":     request.MinerAddress,
		},
		"mining_time": "0.001s",
		"timestamp":   time.Now().Format(time.RFC3339),
	}

	json.NewEncoder(w).Encode(response)
}

func addTransactionHandler(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")

	// Parse request body
	var request struct {
		From   string  `json:"from"`
		To     string  `json:"to"`
		Amount float64 `json:"amount"`
		Token  string  `json:"token"`
	}

	if err := json.NewDecoder(r.Body).Decode(&request); err != nil {
		http.Error(w, "Invalid request body", http.StatusBadRequest)
		return
	}

	if request.From == "" || request.To == "" || request.Amount <= 0 {
		http.Error(w, "Invalid transaction data", http.StatusBadRequest)
		return
	}

	if request.Token == "" {
		request.Token = "USDTg"
	}

	// Add transaction
	bc.AddTransaction(request.From, request.To, request.Amount, request.Token)

	response := map[string]interface{}{
		"message": "Transaction added successfully!",
		"transaction": map[string]interface{}{
			"from":   request.From,
			"to":     request.To,
			"amount": request.Amount,
			"token":  request.Token,
		},
		"pending_transactions": len(bc.PendingTx),
		"timestamp":            time.Now().Format(time.RFC3339),
	}

	json.NewEncoder(w).Encode(response)
}

// EVM Account Handler
func evmAccountHandler(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")

	vars := mux.Vars(r)
	addressStr := vars["address"]

	account := evmInstance.GetAccount(addressStr)

	if account == nil {
		http.Error(w, "Account not found", http.StatusNotFound)
		return
	}

	response := map[string]interface{}{
		"address":   account.Address,
		"nonce":     account.Nonce,
		"balance":   account.Balance.String(),
		"code_hash": account.CodeHash,
		"has_code":  len(account.Code) > 0,
		"timestamp": time.Now().Format(time.RFC3339),
	}

	json.NewEncoder(w).Encode(response)
}

// EVM Deploy Contract Handler
func evmDeployContractHandler(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")

	var request struct {
		From  string `json:"from"`
		Code  string `json:"code"`
		Value string `json:"value"`
	}

	if err := json.NewDecoder(r.Body).Decode(&request); err != nil {
		http.Error(w, "Invalid request body", http.StatusBadRequest)
		return
	}

	from := request.From
	code := request.Code
	value := new(big.Int)
	value.SetString(request.Value, 10)

	// Create account if not exists
	evmInstance.CreateAccount(from)

	// Deploy contract
	contract, err := evmInstance.DeployContract(from, code, value)
	if err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	response := map[string]interface{}{
		"message": "Contract deployed successfully!",
		"contract": map[string]interface{}{
			"address":   contract.Address,
			"balance":   contract.Balance.String(),
			"code_size": len(contract.Code),
		},
		"timestamp": time.Now().Format(time.RFC3339),
	}

	json.NewEncoder(w).Encode(response)
}

// EVM Contract Handler
func evmContractHandler(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")

	vars := mux.Vars(r)
	addressStr := vars["address"]

	address := addressStr
	contract := evmInstance.GetContract(address)

	if contract == nil {
		http.Error(w, "Contract not found", http.StatusNotFound)
		return
	}

	response := map[string]interface{}{
		"address":   contract.Address,
		"balance":   contract.Balance.String(),
		"code_size": len(contract.Code),
		"code_hash": contract.CodeHash,
		"timestamp": time.Now().Format(time.RFC3339),
	}

	json.NewEncoder(w).Encode(response)
}

// EVM Transaction Handler
func evmTransactionHandler(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")

	var request struct {
		From     string `json:"from"`
		To       string `json:"to"`
		Value    string `json:"value"`
		Data     string `json:"data"`
		Gas      string `json:"gas"`
		GasPrice string `json:"gas_price"`
	}

	if err := json.NewDecoder(r.Body).Decode(&request); err != nil {
		http.Error(w, "Invalid request body", http.StatusBadRequest)
		return
	}

	from := request.From
	to := request.To
	value := new(big.Int)
	value.SetString(request.Value, 10)
	data := []byte(request.Data)
	gas, _ := strconv.ParseUint(request.Gas, 10, 64)
	gasPrice := new(big.Int)
	gasPrice.SetString(request.GasPrice, 10)

	// Create accounts if not exist
	evmInstance.CreateAccount(from)
	evmInstance.CreateAccount(to)

	// Create transaction
	tx := &evm.EVMTransaction{
		From:     from,
		To:       to,
		Value:    value,
		Data:     data,
		Gas:      gas,
		GasPrice: gasPrice,
		Nonce:    evmInstance.GetAccount(from).Nonce,
	}

	// Execute transaction
	result, err := evmInstance.ExecuteTransaction(tx)
	if err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	response := map[string]interface{}{
		"message": "Transaction executed successfully!",
		"result": map[string]interface{}{
			"gas_used": result.GasUsed,
			"success":  result.Success,
		},
		"timestamp": time.Now().Format(time.RFC3339),
	}

	json.NewEncoder(w).Encode(response)
}

// EVM Balance Handler
func evmBalanceHandler(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")

	vars := mux.Vars(r)
	addressStr := vars["address"]

	address := addressStr
	balance := evmInstance.GetBalance(address)

	response := map[string]interface{}{
		"address":   address,
		"balance":   balance.String(),
		"timestamp": time.Now().Format(time.RFC3339),
	}

	json.NewEncoder(w).Encode(response)
}

// EVM Add Balance Handler
func evmAddBalanceHandler(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")

	var request struct {
		Address string `json:"address"`
		Amount  string `json:"amount"`
	}

	if err := json.NewDecoder(r.Body).Decode(&request); err != nil {
		http.Error(w, "Invalid request body", http.StatusBadRequest)
		return
	}

	amount := new(big.Int)
	amount.SetString(request.Amount, 10)

	// Add balance to account
	evmInstance.AddBalance(request.Address, amount)

	response := map[string]interface{}{
		"message":     "Balance added successfully!",
		"address":     request.Address,
		"amount":      request.Amount,
		"new_balance": evmInstance.GetBalance(request.Address).String(),
		"timestamp":   time.Now().Format(time.RFC3339),
	}

	json.NewEncoder(w).Encode(response)
}
