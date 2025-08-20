package main

import (
	"encoding/json"
	"fmt"
	"net/http"
	"time"
)

func main() {
	fmt.Println("🚀 Simple USDTg Blockchain Server")

	// CORS handler
	corsHandler := func(next http.HandlerFunc) http.HandlerFunc {
		return func(w http.ResponseWriter, r *http.Request) {
			w.Header().Set("Access-Control-Allow-Origin", "*")
			w.Header().Set("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
			w.Header().Set("Access-Control-Allow-Headers", "Content-Type, Authorization, X-Requested-With")
			w.Header().Set("Access-Control-Allow-Credentials", "true")

			if r.Method == "OPTIONS" {
				w.WriteHeader(http.StatusOK)
				return
			}

			next(w, r)
		}
	}

	// Home endpoint
	http.HandleFunc("/", corsHandler(func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		response := map[string]interface{}{
			"name":      "USDTg Blockchain",
			"version":   "1.0.0",
			"status":    "running",
			"timestamp": time.Now().Format(time.RFC3339),
		}
		json.NewEncoder(w).Encode(response)
	}))

	// Health endpoint
	http.HandleFunc("/health", corsHandler(func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		response := map[string]interface{}{
			"status":    "healthy",
			"timestamp": time.Now().Format(time.RFC3339),
		}
		json.NewEncoder(w).Encode(response)
	}))

	// Blockchain info endpoint
	http.HandleFunc("/api/blockchain/info", corsHandler(func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		response := map[string]interface{}{
			"total_blocks":         2,
			"latest_block":         1,
			"pending_transactions": 0,
			"mining_difficulty":    0,
			"mining_reward":        100,
			"chain_valid":          true,
			"timestamp":            time.Now().Format(time.RFC3339),
		}
		json.NewEncoder(w).Encode(response)
	}))

	// Balance endpoint
	http.HandleFunc("/api/blockchain/balance/", corsHandler(func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		response := map[string]interface{}{
			"address":   "0x123...",
			"balance":   1000,
			"timestamp": time.Now().Format(time.RFC3339),
		}
		json.NewEncoder(w).Encode(response)
	}))

	// EVM contract deploy endpoint
	http.HandleFunc("/api/evm/contract/deploy", corsHandler(func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		response := map[string]interface{}{
			"message": "Contract deployed successfully!",
			"contract": map[string]interface{}{
				"address": "0xabc123456789def...",
				"hash":    "0xdef456789abc123...",
				"gas":     21000,
			},
			"timestamp": time.Now().Format(time.RFC3339),
		}
		json.NewEncoder(w).Encode(response)
	}))

	// Mining endpoint
	http.HandleFunc("/api/blockchain/mine", corsHandler(func(w http.ResponseWriter, r *http.Request) {
		fmt.Printf("🔍 Mining request: %s\n", r.Method)

		if r.Method != "POST" {
			http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
			return
		}

		w.Header().Set("Content-Type", "application/json")

		response := map[string]interface{}{
			"message": "Block mined successfully!",
			"block": map[string]interface{}{
				"index": 2,
				"hash":  "0x123456789abcdef",
				"miner": "test_miner",
				"transactions": []map[string]interface{}{
					{
						"from":   "system",
						"to":     "test_miner",
						"amount": 100,
						"hash":   "0xabc123...",
					},
				},
			},
			"timestamp": time.Now().Format(time.RFC3339),
		}

		json.NewEncoder(w).Encode(response)
		fmt.Printf("✅ Mining response sent\n")
	}))

	// Transfer endpoint
	http.HandleFunc("/api/blockchain/transaction", corsHandler(func(w http.ResponseWriter, r *http.Request) {
		fmt.Printf("🔍 Transfer request: %s\n", r.Method)

		if r.Method != "POST" {
			http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
			return
		}

		w.Header().Set("Content-Type", "application/json")

		response := map[string]interface{}{
			"message":   "Transaction added successfully!",
			"timestamp": time.Now().Format(time.RFC3339),
		}

		json.NewEncoder(w).Encode(response)
		fmt.Printf("✅ Transfer response sent\n")
	}))

	fmt.Println("🌐 Server starting on :8080")
	if err := http.ListenAndServe(":8080", nil); err != nil {
		fmt.Printf("❌ Server error: %v\n", err)
	}
}
