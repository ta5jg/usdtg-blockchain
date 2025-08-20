import React, { useState } from 'react'
import { Send, ArrowRight, CheckCircle, AlertCircle, Loader } from 'lucide-react'

const TokenTransfer = () => {
  const [formData, setFormData] = useState({
    from: '',
    to: '',
    amount: '',
    token: 'USDTg'
  })
  const [loading, setLoading] = useState(false)
  const [result, setResult] = useState(null)
  const [error, setError] = useState(null)

  const handleSubmit = async (e) => {
    e.preventDefault()
    setLoading(true)
    setError(null)
    setResult(null)

    try {
      		const response = await fetch('http://localhost:8080/api/blockchain/transaction', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(formData),
      })

      const data = await response.json()

      if (response.ok) {
        setResult(data)
      } else {
        setError(data.message || 'Transaction failed')
      }
    } catch (err) {
      setError('Network error. Please try again.')
    } finally {
      setLoading(false)
    }
  }

  const handleInputChange = (e) => {
    const { name, value } = e.target
    setFormData(prev => ({
      ...prev,
      [name]: value
    }))
  }

  const generateAddress = () => {
    const chars = '0123456789abcdef'
    let result = '0x'
    for (let i = 0; i < 40; i++) {
      result += chars.charAt(Math.floor(Math.random() * chars.length))
    }
    return result
  }

  const fillRandomAddresses = () => {
    setFormData(prev => ({
      ...prev,
      from: generateAddress(),
      to: generateAddress()
    }))
  }

  return (
    <div className="max-w-2xl mx-auto space-y-8">
      {/* Header */}
      <div className="text-center">
        <h1 className="text-3xl font-bold text-gray-900 mb-2">Token Transfer</h1>
        <p className="text-gray-600">Send USDTg tokens between addresses on the blockchain</p>
      </div>

      {/* Transfer Form */}
      <div className="card">
        <form onSubmit={handleSubmit} className="space-y-6">
          <div>
            <label htmlFor="from" className="block text-sm font-medium text-gray-700 mb-2">
              From Address
            </label>
            <div className="flex space-x-2">
              <input
                type="text"
                id="from"
                name="from"
                value={formData.from}
                onChange={handleInputChange}
                placeholder="0x..."
                className="input-field flex-1"
                required
              />
              <button
                type="button"
                onClick={fillRandomAddresses}
                className="btn-secondary whitespace-nowrap"
              >
                Generate
              </button>
            </div>
          </div>

          <div className="flex justify-center">
            <ArrowRight className="w-6 h-6 text-gray-400" />
          </div>

          <div>
            <label htmlFor="to" className="block text-sm font-medium text-gray-700 mb-2">
              To Address
            </label>
            <input
              type="text"
              id="to"
              name="to"
              value={formData.to}
              onChange={handleInputChange}
              placeholder="0x..."
              className="input-field"
              required
            />
          </div>

          <div>
            <label htmlFor="amount" className="block text-sm font-medium text-gray-700 mb-2">
              Amount
            </label>
            <div className="flex space-x-2">
              <input
                type="number"
                id="amount"
                name="amount"
                value={formData.amount}
                onChange={handleInputChange}
                placeholder="0.00"
                step="0.01"
                min="0"
                className="input-field flex-1"
                required
              />
              <span className="inline-flex items-center px-3 py-2 border border-l-0 border-gray-300 rounded-r-lg bg-gray-50 text-gray-500 text-sm">
                {formData.token}
              </span>
            </div>
          </div>

          <div>
            <label htmlFor="token" className="block text-sm font-medium text-gray-700 mb-2">
              Token
            </label>
            <select
              id="token"
              name="token"
              value={formData.token}
              onChange={handleInputChange}
              className="input-field"
            >
              <option value="USDTg">USDTg</option>
              <option value="ETH">ETH</option>
              <option value="BTC">BTC</option>
            </select>
          </div>

          <button
            type="submit"
            disabled={loading}
            className="w-full btn-primary disabled:opacity-50 disabled:cursor-not-allowed"
          >
            {loading ? (
              <>
                <Loader className="w-4 h-4 mr-2 animate-spin" />
                Processing...
              </>
            ) : (
              <>
                <Send className="w-4 h-4 mr-2" />
                Send Transaction
              </>
            )}
          </button>
        </form>
      </div>

      {/* Result */}
      {result && (
        <div className="card border-green-200 bg-green-50">
          <div className="flex items-center space-x-3">
            <CheckCircle className="w-6 h-6 text-green-600" />
            <h3 className="text-lg font-medium text-green-800">Transaction Successful!</h3>
          </div>
          <div className="mt-4 space-y-2 text-sm text-green-700">
            <p><strong>Message:</strong> {result.message}</p>
            <p><strong>Pending Transactions:</strong> {result.pending_transactions}</p>
            <p><strong>Timestamp:</strong> {result.timestamp}</p>
          </div>
        </div>
      )}

      {/* Error */}
      {error && (
        <div className="card border-red-200 bg-red-50">
          <div className="flex items-center space-x-3">
            <AlertCircle className="w-6 h-6 text-red-600" />
            <h3 className="text-lg font-medium text-red-800">Transaction Failed</h3>
          </div>
          <p className="mt-2 text-sm text-red-700">{error}</p>
        </div>
      )}

      {/* Info */}
      <div className="card bg-blue-50 border-blue-200">
        <h3 className="text-lg font-medium text-blue-800 mb-2">How it works</h3>
        <ul className="text-sm text-blue-700 space-y-1">
          <li>• Enter the sender and recipient addresses</li>
          <li>• Specify the amount and token type</li>
          <li>• Transaction is added to the pending pool</li>
          <li>• Miners will include it in the next block</li>
          <li>• Use the Mining tab to create new blocks</li>
        </ul>
      </div>
    </div>
  )
}

export default TokenTransfer
