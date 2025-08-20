import React, { useState, useEffect } from 'react'
import { 
  Activity, 
  Coins, 
  Wallet, 
  FileText, 
  Zap, 
  Shield,
  BarChart3,
  Settings
} from 'lucide-react'
import BlockchainStatus from './components/BlockchainStatus'
import TokenTransfer from './components/TokenTransfer'
import ContractDeploy from './components/ContractDeploy'
import AccountInfo from './components/AccountInfo'
import MiningPanel from './components/MiningPanel'

function App() {
  const [activeTab, setActiveTab] = useState('dashboard')
  const [blockchainInfo, setBlockchainInfo] = useState(null)
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    fetchBlockchainInfo()
  }, [])

  const fetchBlockchainInfo = async () => {
    try {
      const response = await fetch('http://localhost:8080/api/blockchain/info')
      const data = await response.json()
      setBlockchainInfo(data)
    } catch (error) {
      console.error('Error fetching blockchain info:', error)
    } finally {
      setLoading(false)
    }
  }

  const tabs = [
    { id: 'dashboard', name: 'Dashboard', icon: BarChart3 },
    { id: 'transfer', name: 'Token Transfer', icon: Coins },
    { id: 'contracts', name: 'Smart Contracts', icon: FileText },
    { id: 'accounts', name: 'Accounts', icon: Wallet },
    { id: 'mining', name: 'Mining', icon: Zap },
    { id: 'settings', name: 'Settings', icon: Settings }
  ]

  const renderContent = () => {
    switch (activeTab) {
      case 'dashboard':
        return <BlockchainStatus blockchainInfo={blockchainInfo} loading={loading} />
      case 'transfer':
        return <TokenTransfer />
      case 'contracts':
        return <ContractDeploy />
      case 'accounts':
        return <AccountInfo />
      case 'mining':
        return <MiningPanel />
      case 'settings':
        return <div className="text-center py-12">Settings panel coming soon...</div>
      default:
        return <BlockchainStatus blockchainInfo={blockchainInfo} loading={loading} />
    }
  }

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Header */}
      <header className="bg-white shadow-sm border-b border-gray-200">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex justify-between items-center h-16">
            <div className="flex items-center space-x-3">
              <div className="w-8 h-8 bg-usdtg-600 rounded-lg flex items-center justify-center">
                <Coins className="w-5 h-5 text-white" />
              </div>
              <h1 className="text-xl font-bold text-gray-900">USDTg Blockchain</h1>
            </div>
            <div className="flex items-center space-x-4">
              <div className="flex items-center space-x-2 text-sm text-gray-600">
                <Activity className="w-4 h-4" />
                <span>Chain ID: 1337</span>
              </div>
              <div className="w-2 h-2 bg-green-500 rounded-full animate-pulse"></div>
            </div>
          </div>
        </div>
      </header>

      {/* Navigation */}
      <nav className="bg-white border-b border-gray-200">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex space-x-8">
            {tabs.map((tab) => {
              const Icon = tab.icon
              return (
                <button
                  key={tab.id}
                  onClick={() => setActiveTab(tab.id)}
                  className={`flex items-center space-x-2 py-4 px-1 border-b-2 font-medium text-sm transition-colors duration-200 ${
                    activeTab === tab.id
                      ? 'border-usdtg-500 text-usdtg-600'
                      : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300'
                  }`}
                >
                  <Icon className="w-4 h-4" />
                  <span>{tab.name}</span>
                </button>
              )
            })}
          </div>
        </div>
      </nav>

      {/* Main Content */}
      <main className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        {renderContent()}
      </main>

      {/* Footer */}
      <footer className="bg-white border-t border-gray-200 mt-16">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
          <div className="text-center text-gray-500 text-sm">
            <p>© 2024 USDTg Blockchain. Built with React & Tailwind CSS.</p>
            <p className="mt-2">The future of decentralized finance starts here.</p>
          </div>
        </div>
      </footer>
    </div>
  )
}

export default App
