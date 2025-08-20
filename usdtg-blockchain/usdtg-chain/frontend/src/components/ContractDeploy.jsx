import React, { useState } from 'react'
import { FileText, Code, CheckCircle, AlertCircle, Loader, Copy, ExternalLink } from 'lucide-react'

const ContractDeploy = () => {
  const [formData, setFormData] = useState({
    from: '',
    code: '',
    value: '0'
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
      		const response = await fetch('http://localhost:8080/api/evm/contract/deploy', {
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
        setError(data.message || 'Contract deployment failed')
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

  const fillRandomAddress = () => {
    setFormData(prev => ({
      ...prev,
      from: generateAddress()
    }))
  }

  const copyToClipboard = (text) => {
    navigator.clipboard.writeText(text)
  }

  const sampleContracts = [
    {
      name: 'Simple Token',
      description: 'Basic ERC20 token contract',
      code: `// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

contract SimpleToken {
    string public name = "Simple Token";
    string public symbol = "ST";
    uint8 public decimals = 18;
    uint256 public totalSupply = 1000000 * 10**18;
    mapping(address => uint256) public balanceOf;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    
    constructor() {
        balanceOf[msg.sender] = totalSupply;
    }
    
    function transfer(address to, uint256 amount) public returns (bool) {
        require(balanceOf[msg.sender] >= amount, "Insufficient balance");
        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;
        emit Transfer(msg.sender, to, amount);
        return true;
    }
}`
    },
    {
      name: 'Counter',
      description: 'Simple counter contract',
      code: `// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

contract Counter {
    uint256 public count;
    
    event CountIncremented(uint256 newCount);
    
    function increment() public {
        count++;
        emit CountIncremented(count);
    }
    
    function decrement() public {
        require(count > 0, "Count cannot be negative");
        count--;
        emit CountIncremented(count);
    }
    
    function getCount() public view returns (uint256) {
        return count;
    }
}`
    },
    {
      name: 'Greeter',
      description: 'Simple greeting contract',
      code: `// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

contract Greeter {
    string public greeting;
    
    event GreetingChanged(string newGreeting);
    
    constructor() {
        greeting = "Hello, World!";
    }
    
    function setGreeting(string memory _greeting) public {
        greeting = _greeting;
        emit GreetingChanged(_greeting);
    }
    
    function getGreeting() public view returns (string memory) {
        return greeting;
    }
}`
    }
  ]

  const loadSampleContract = (contract) => {
    setFormData(prev => ({
      ...prev,
      code: contract.code
    }))
  }

  return (
    <div className="max-w-4xl mx-auto space-y-8">
      {/* Header */}
      <div className="text-center">
        <h1 className="text-3xl font-bold text-gray-900 mb-2">Smart Contract Deployment</h1>
        <p className="text-gray-600">Deploy smart contracts to the USDTg Blockchain</p>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">
        {/* Deployment Form */}
        <div className="space-y-6">
          <div className="card">
            <h3 className="text-lg font-medium text-gray-900 mb-4">Deploy Contract</h3>
            <form onSubmit={handleSubmit} className="space-y-4">
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
                    onClick={fillRandomAddress}
                    className="btn-secondary whitespace-nowrap"
                  >
                    Generate
                  </button>
                </div>
              </div>

              <div>
                <label htmlFor="value" className="block text-sm font-medium text-gray-700 mb-2">
                  Value (ETH)
                </label>
                <input
                  type="text"
                  id="value"
                  name="value"
                  value={formData.value}
                  onChange={handleInputChange}
                  placeholder="0"
                  className="input-field"
                />
              </div>

              <div>
                <label htmlFor="code" className="block text-sm font-medium text-gray-700 mb-2">
                  Contract Code (Solidity)
                </label>
                <textarea
                  id="code"
                  name="code"
                  value={formData.code}
                  onChange={handleInputChange}
                  placeholder="// Enter your Solidity contract code here..."
                  rows="12"
                  className="input-field font-mono text-sm"
                  required
                />
              </div>

              <button
                type="submit"
                disabled={loading}
                className="w-full btn-primary disabled:opacity-50 disabled:cursor-not-allowed"
              >
                {loading ? (
                  <>
                    <Loader className="w-4 h-4 mr-2 animate-spin" />
                    Deploying...
                  </>
                ) : (
                  <>
                    <FileText className="w-4 h-4 mr-2" />
                    Deploy Contract
                  </>
                )}
              </button>
            </form>
          </div>
        </div>

        {/* Sample Contracts & Results */}
        <div className="space-y-6">
          {/* Sample Contracts */}
          <div className="card">
            <h3 className="text-lg font-medium text-gray-900 mb-4">Sample Contracts</h3>
            <div className="space-y-3">
              {sampleContracts.map((contract, index) => (
                <button
                  key={index}
                  onClick={() => loadSampleContract(contract)}
                  className="w-full text-left p-3 border border-gray-200 rounded-lg hover:border-usdtg-300 hover:bg-usdtg-50 transition-colors duration-200"
                >
                  <h4 className="font-medium text-gray-900">{contract.name}</h4>
                  <p className="text-sm text-gray-600">{contract.description}</p>
                </button>
              ))}
            </div>
          </div>

          {/* Result */}
          {result && (
            <div className="card border-green-200 bg-green-50">
              <div className="flex items-center space-x-3">
                <CheckCircle className="w-6 h-6 text-green-600" />
                <h3 className="text-lg font-medium text-green-800">Contract Deployed!</h3>
              </div>
              <div className="mt-4 space-y-3 text-sm text-green-700">
                <div>
                  <p className="font-medium">Contract Address:</p>
                  <div className="flex items-center space-x-2 mt-1">
                    <code className="bg-green-100 px-2 py-1 rounded text-xs break-all">
                      {result.contract?.address || 'N/A'}
                    </code>
                    <button
                      onClick={() => copyToClipboard(result.contract?.address || '')}
                      className="text-green-600 hover:text-green-800"
                    >
                      <Copy className="w-4 h-4" />
                    </button>
                  </div>
                </div>
                <p><strong>Balance:</strong> {result.contract?.balance || 0} ETH</p>
                <p><strong>Code Size:</strong> {result.contract?.code_size || 0} bytes</p>
                <p><strong>Timestamp:</strong> {result.timestamp}</p>
              </div>
            </div>
          )}

          {/* Error */}
          {error && (
            <div className="card border-red-200 bg-red-50">
              <div className="flex items-center space-x-3">
                <AlertCircle className="w-6 h-6 text-red-600" />
                <h3 className="text-lg font-medium text-red-800">Deployment Failed</h3>
              </div>
              <p className="mt-2 text-sm text-red-700">{error}</p>
            </div>
          )}

          {/* Info */}
          <div className="card bg-blue-50 border-blue-200">
            <h3 className="text-lg font-medium text-blue-800 mb-2">How to deploy</h3>
            <ul className="text-sm text-blue-700 space-y-1">
              <li>• Write your Solidity contract code</li>
              <li>• Set the sender address</li>
              <li>• Optionally add ETH value</li>
              <li>• Click deploy to create the contract</li>
              <li>• Use the generated address to interact</li>
            </ul>
          </div>
        </div>
      </div>
    </div>
  )
}

export default ContractDeploy
