import React, { useState } from 'react'
import { Zap, Hash, Clock, Coins, CheckCircle, AlertCircle, Loader, Play, Pause } from 'lucide-react'

const MiningPanel = () => {
  const [minerAddress, setMinerAddress] = useState('')
  const [mining, setMining] = useState(false)
  const [miningHistory, setMiningHistory] = useState([])
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState(null)

  const generateAddress = () => {
    const chars = '0123456789abcdef'
    let result = '0x'
    for (let i = 0; i < 40; i++) {
      result += chars.charAt(Math.floor(Math.random() * chars.length))
    }
    setMinerAddress(result)
  }

  const startMining = async () => {
    if (!minerAddress.trim()) return

    setLoading(true)
    setError(null)

    try {
      console.log('Starting mining for address:', minerAddress)
      
      const response = await fetch('http://localhost:8080/api/blockchain/mine', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ miner_address: minerAddress }),
      })

      console.log('Mining response status:', response.status)
      const data = await response.json()
      console.log('Mining response data:', data)

      if (response.ok) {
        setMiningHistory(prev => [{
          ...data,
          timestamp: new Date().toLocaleString(),
          id: Date.now()
        }, ...prev])
        setMining(false)
        setError(null) // Clear any previous errors
      } else {
        setError(data.message || `Mining failed with status: ${response.status}`)
      }
    } catch (err) {
      console.error('Mining error:', err)
      setError(`Network error: ${err.message}. Please check if backend is running.`)
    } finally {
      setLoading(false)
    }
  }

  const stopMining = () => {
    setMining(false)
  }

  const clearHistory = () => {
    setMiningHistory([])
  }

  return (
    <div className="max-w-4xl mx-auto space-y-8">
      {/* Header */}
      <div className="text-center">
        <h1 className="text-3xl font-bold text-gray-900 mb-2">Mining Panel</h1>
        <p className="text-gray-600">Mine new blocks and earn USDTg rewards on the USDTg Blockchain</p>
      </div>

      {/* Mining Controls */}
      <div className="card">
        <h3 className="text-lg font-medium text-gray-900 mb-4">Mining Controls</h3>
        <div className="space-y-4">
          <div>
            <label htmlFor="minerAddress" className="block text-sm font-medium text-gray-700 mb-2">
              Miner Address
            </label>
            <div className="flex space-x-2">
              <input
                type="text"
                id="minerAddress"
                value={minerAddress}
                onChange={(e) => setMinerAddress(e.target.value)}
                placeholder="0x..."
                className="input-field flex-1"
                required
              />
              <button
                type="button"
                onClick={generateAddress}
                className="btn-secondary whitespace-nowrap"
              >
                Generate
              </button>
            </div>
          </div>

          <div className="flex space-x-4">
            <button
              onClick={startMining}
              disabled={loading || !minerAddress.trim() || mining}
              className="btn-primary disabled:opacity-50 disabled:cursor-not-allowed"
            >
              {loading ? (
                <>
                  <Loader className="w-4 h-4 mr-2 animate-spin" />
                  Mining...
                </>
              ) : (
                <>
                  <Play className="w-4 h-4 mr-2" />
                  Start Mining
                </>
              )}
            </button>

            <button
              onClick={stopMining}
              disabled={!mining}
              className="btn-secondary disabled:opacity-50 disabled:cursor-not-allowed"
            >
              <Pause className="w-4 h-4 mr-2" />
              Stop Mining
            </button>
          </div>
        </div>
      </div>

      {/* Mining Status */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
        <div className="card text-center">
          <div className="w-12 h-12 bg-usdtg-100 rounded-lg flex items-center justify-center mx-auto mb-3">
            <Zap className="w-6 h-6 text-usdtg-600" />
          </div>
          <h3 className="text-lg font-medium text-gray-900">Mining Status</h3>
          <p className={`text-2xl font-bold ${mining ? 'text-green-600' : 'text-gray-600'}`}>
            {mining ? 'Active' : 'Inactive'}
          </p>
        </div>

        <div className="card text-center">
          <div className="w-12 h-12 bg-blue-100 rounded-lg flex items-center justify-center mx-auto mb-3">
            <Hash className="w-6 h-6 text-blue-600" />
          </div>
          <h3 className="text-lg font-medium text-gray-900">Blocks Mined</h3>
          <p className="text-2xl font-bold text-blue-600">{miningHistory.length}</p>
        </div>

        <div className="card text-center">
          <div className="w-12 h-12 bg-orange-100 rounded-lg flex items-center justify-center mx-auto mb-3">
            <Coins className="w-6 h-6 text-orange-600" />
          </div>
          <h3 className="text-lg font-medium text-gray-900">Total Rewards</h3>
          <p className="text-2xl font-bold text-orange-600">
            {miningHistory.length * 100} USDTg
          </p>
        </div>
      </div>

      {/* Mining History */}
      {miningHistory.length > 0 && (
        <div className="card">
          <div className="flex items-center justify-between mb-4">
            <h3 className="text-lg font-medium text-gray-900">Mining History</h3>
            <button
              onClick={clearHistory}
              className="text-sm text-gray-500 hover:text-gray-700"
            >
              Clear History
            </button>
          </div>
          <div className="space-y-4">
            {miningHistory.map((block) => (
              <div key={block.id} className="border border-gray-200 rounded-lg p-4">
                <div className="flex items-center justify-between">
                  <div className="flex items-center space-x-3">
                    <CheckCircle className="w-5 h-5 text-green-600" />
                    <div>
                      <p className="font-medium text-gray-900">Block #{block.block.index}</p>
                      <p className="text-sm text-gray-600">
                        Hash: {block.block.hash.substring(0, 16)}...
                      </p>
                    </div>
                  </div>
                  <div className="text-right">
                    <p className="text-sm text-gray-600">{block.timestamp}</p>
                    <p className="text-sm font-medium text-green-600">
                      +100 USDTg Reward
                    </p>
                  </div>
                </div>
                <div className="mt-3 pt-3 border-t border-gray-200">
                  <div className="grid grid-cols-2 md:grid-cols-4 gap-4 text-sm">
                    <div>
                      <p className="text-gray-600">Mining Time</p>
                      <p className="font-medium">{block.mining_time}</p>
                    </div>
                    <div>
                      <p className="text-gray-600">Transactions</p>
                      <p className="font-medium">{block.block?.transactions?.length || 0}</p>
                    </div>
                    <div>
                      <p className="text-gray-600">Difficulty</p>
                      <p className="font-medium">{block.block?.difficulty || 0}</p>
                    </div>
                    <div>
                      <p className="text-gray-600">Nonce</p>
                      <p className="font-medium">{block.block?.nonce || 0}</p>
                    </div>
                  </div>
                </div>
              </div>
            ))}
          </div>
        </div>
      )}

      {/* Error */}
      {error && (
        <div className="card border-red-200 bg-red-50">
          <div className="flex items-center space-x-3">
            <AlertCircle className="w-6 h-6 text-red-600" />
            <h3 className="text-lg font-medium text-red-800">Mining Failed</h3>
          </div>
          <p className="mt-2 text-sm text-red-700">{error}</p>
        </div>
      )}

      {/* Info */}
      <div className="card bg-blue-50 border-blue-200">
        <h3 className="text-lg font-medium text-blue-800 mb-2">How Mining Works</h3>
        <ul className="text-sm text-blue-700 space-y-1">
          <li>• <strong>Proof of Stake (PoS):</strong> No complex mining required</li>
          <li>• <strong>Instant Blocks:</strong> New blocks are created immediately</li>
          <li>• <strong>Rewards:</strong> Earn 100 USDTg for each block mined</li>
          <li>• <strong>Transactions:</strong> Pending transactions are included in new blocks</li>
          <li>• <strong>Security:</strong> Each block is cryptographically linked to the previous</li>
        </ul>
      </div>
    </div>
  )
}

export default MiningPanel
