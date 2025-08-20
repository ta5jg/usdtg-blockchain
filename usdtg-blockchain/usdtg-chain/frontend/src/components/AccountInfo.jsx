import React, { useState } from 'react'
import { Wallet, Search, Copy, ExternalLink, AlertCircle, CheckCircle } from 'lucide-react'

const AccountInfo = () => {
  const [address, setAddress] = useState('')
  const [accountInfo, setAccountInfo] = useState(null)
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState(null)

  const handleSearch = async (e) => {
    e.preventDefault()
    if (!address.trim()) return

    setLoading(true)
    setError(null)
    setAccountInfo(null)

    try {
      		const response = await fetch(`http://localhost:8080/api/blockchain/balance/${address}`)
      const data = await response.json()

      if (response.ok) {
        // Transform backend data to frontend format
        const transformedData = {
          address: data.address,
          nonce: 0, // Default nonce for new accounts
          balance: data.balance?.USDTg || '0',
          code_hash: '0x0000...', // Default for EOA
          has_code: false // Default for EOA
        }
        setAccountInfo(transformedData)
      } else {
        setError(data.message || 'Account not found')
      }
    } catch (err) {
      setError('Network error. Please try again.')
    } finally {
      setLoading(false)
    }
  }

  const generateAddress = () => {
    const chars = '0123456789abcdef'
    let result = '0x'
    for (let i = 0; i < 40; i++) {
      result += chars.charAt(Math.floor(Math.random() * chars.length))
    }
    setAddress(result)
  }

  const copyToClipboard = (text) => {
    navigator.clipboard.writeText(text)
  }

  const handleViewBalance = () => {
    // Show current balance in a more detailed way
    if (accountInfo) {
      alert(`Account Balance Details:\n\nAddress: ${accountInfo.address}\nBalance: ${accountInfo.balance} ETH\nNonce: ${accountInfo.nonce}`)
    }
  }

  const handleViewTransactions = () => {
    // Show transaction history (currently empty for new accounts)
    if (accountInfo) {
      alert(`Transaction History:\n\nAddress: ${accountInfo.address}\nTotal Transactions: 0\nStatus: New Account (No transactions yet)`)
    }
  }

  const handleViewContract = () => {
    // Show contract details if it's a contract account
    if (accountInfo && accountInfo.has_code) {
      alert(`Contract Details:\n\nAddress: ${accountInfo.address}\nCode Hash: ${accountInfo.code_hash}\nType: Smart Contract`)
    }
  }

  return (
    <div className="max-w-4xl mx-auto space-y-8">
      {/* Header */}
      <div className="text-center">
        <h1 className="text-3xl font-bold text-gray-900 mb-2">Account Information</h1>
        <p className="text-gray-600">View account details and balances on the USDTg Blockchain</p>
      </div>

      {/* Search Form */}
      <div className="card">
        <form onSubmit={handleSearch} className="space-y-4">
          <div>
            <label htmlFor="address" className="block text-sm font-medium text-gray-700 mb-2">
              Account Address
            </label>
            <div className="flex space-x-2">
              <input
                type="text"
                id="address"
                value={address}
                onChange={(e) => setAddress(e.target.value)}
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
              <button
                type="submit"
                disabled={loading || !address.trim()}
                className="btn-primary disabled:opacity-50 disabled:cursor-not-allowed"
              >
                {loading ? (
                  <div className="animate-spin rounded-full h-4 w-4 border-b-2 border-white"></div>
                ) : (
                  <>
                    <Search className="w-4 h-4 mr-2" />
                    Search
                  </>
                )}
              </button>
            </div>
          </div>
        </form>
      </div>

      {/* Account Information */}
      {accountInfo && (
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
          {/* Account Details */}
          <div className="card">
            <h3 className="text-lg font-medium text-gray-900 mb-4">Account Details</h3>
            <div className="space-y-4">
              <div>
                <p className="text-sm text-gray-600">Address</p>
                <div className="flex items-center space-x-2 mt-1">
                  <code className="bg-gray-100 px-2 py-1 rounded text-xs break-all">
                    {accountInfo.address}
                  </code>
                  <button
                    onClick={() => copyToClipboard(accountInfo.address)}
                    className="text-gray-600 hover:text-gray-800"
                  >
                    <Copy className="w-4 h-4" />
                  </button>
                </div>
              </div>
              <div>
                <p className="text-sm text-gray-600">Nonce</p>
                <p className="text-lg font-medium text-gray-900">{accountInfo.nonce}</p>
              </div>
              <div>
                <p className="text-sm text-gray-600">Balance</p>
                <p className="text-2xl font-bold text-usdtg-600">{accountInfo.balance} ETH</p>
              </div>
              <div>
                <p className="text-sm text-gray-600">Code Hash</p>
                <p className="text-sm font-mono text-gray-900 break-all">
                  {accountInfo.code_hash || '0x0000...'}
                </p>
              </div>
              <div>
                <p className="text-sm text-gray-600">Has Code</p>
                <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${
                  accountInfo.has_code 
                    ? 'bg-green-100 text-green-800'
                    : 'bg-gray-100 text-gray-800'
                }`}>
                  {accountInfo.has_code ? 'Yes (Contract)' : 'No (EOA)'}
                </span>
              </div>
            </div>
          </div>

          {/* Quick Actions */}
          <div className="card">
            <h3 className="text-lg font-medium text-gray-900 mb-4">Quick Actions</h3>
            <div className="space-y-3">
              <button 
                onClick={() => handleViewBalance()}
                className="w-full btn-secondary text-left hover:bg-gray-100 transition-colors"
              >
                <Wallet className="w-4 h-4 mr-2" />
                View Balance
              </button>
              <button 
                onClick={() => handleViewTransactions()}
                className="w-full btn-secondary text-left hover:bg-gray-100 transition-colors"
              >
                <ExternalLink className="w-4 h-4 mr-2" />
                View Transactions
              </button>
              {accountInfo.has_code && (
                <button 
                  onClick={() => handleViewContract()}
                  className="w-full btn-secondary text-left hover:bg-gray-100 transition-colors"
                >
                  <ExternalLink className="w-4 h-4 mr-2" />
                  View Contract
                </button>
              )}
            </div>
          </div>
        </div>
      )}

      {/* Error */}
      {error && (
        <div className="card border-red-200 bg-red-50">
          <div className="flex items-center space-x-3">
            <AlertCircle className="w-6 h-6 text-red-600" />
            <h3 className="text-lg font-medium text-red-800">Account Not Found</h3>
          </div>
          <p className="mt-2 text-sm text-red-700">{error}</p>
        </div>
      )}

      {/* Info */}
      <div className="card bg-blue-50 border-blue-200">
        <h3 className="text-lg font-medium text-blue-800 mb-2">About Accounts</h3>
        <ul className="text-sm text-blue-700 space-y-1">
          <li>• <strong>EOA (Externally Owned Account):</strong> Regular user accounts</li>
          <li>• <strong>Contract Account:</strong> Smart contract accounts with code</li>
          <li>• <strong>Nonce:</strong> Transaction counter for the account</li>
          <li>• <strong>Balance:</strong> ETH balance in wei (1 ETH = 10^18 wei)</li>
          <li>• <strong>Code Hash:</strong> Hash of the contract code (if any)</li>
        </ul>
      </div>
    </div>
  )
}

export default AccountInfo
