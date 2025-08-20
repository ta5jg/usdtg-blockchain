import React from 'react'
import { 
  Activity, 
  Coins, 
  Hash, 
  Clock, 
  TrendingUp, 
  Shield,
  CheckCircle,
  AlertCircle
} from 'lucide-react'

const BlockchainStatus = ({ blockchainInfo, loading }) => {
  if (loading) {
    return (
      <div className="flex items-center justify-center py-12">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-usdtg-600"></div>
      </div>
    )
  }

  if (!blockchainInfo) {
    return (
      <div className="text-center py-12">
        <AlertCircle className="w-12 h-12 text-red-500 mx-auto mb-4" />
        <h3 className="text-lg font-medium text-gray-900 mb-2">Blockchain Unavailable</h3>
        <p className="text-gray-600">Unable to fetch blockchain information.</p>
      </div>
    )
  }

  const stats = [
    {
      name: 'Total Blocks',
      value: blockchainInfo.total_blocks,
      icon: Hash,
      color: 'bg-blue-500',
      change: '+1',
      changeType: 'positive'
    },
    {
      name: 'Latest Block',
      value: blockchainInfo.latest_block,
      icon: Activity,
      color: 'bg-green-500',
      change: 'Current',
      changeType: 'neutral'
    },
    {
      name: 'Pending Transactions',
      value: blockchainInfo.pending_tx,
      icon: Clock,
      color: 'bg-yellow-500',
      change: 'Waiting',
      changeType: 'neutral'
    },
    {
      name: 'Mining Difficulty',
      value: blockchainInfo.difficulty,
      icon: TrendingUp,
      color: 'bg-purple-500',
      change: 'PoS',
      changeType: 'positive'
    },
    {
      name: 'Mining Reward',
      value: `${blockchainInfo.mining_reward} USDTg`,
      icon: Coins,
      color: 'bg-orange-500',
      change: 'Active',
      changeType: 'positive'
    },
    {
      name: 'Chain Valid',
      value: blockchainInfo.is_valid ? 'Yes' : 'No',
      icon: blockchainInfo.is_valid ? CheckCircle : AlertCircle,
      color: blockchainInfo.is_valid ? 'bg-green-500' : 'bg-red-500',
      change: blockchainInfo.is_valid ? 'Healthy' : 'Issue',
      changeType: blockchainInfo.is_valid ? 'positive' : 'negative'
    }
  ]

  return (
    <div className="space-y-8">
      {/* Header */}
      <div className="text-center">
        <h1 className="text-3xl font-bold text-gray-900 mb-2">Blockchain Dashboard</h1>
        <p className="text-gray-600">Real-time monitoring of the USDTg Blockchain network</p>
      </div>

      {/* Stats Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        {stats.map((stat) => {
          const Icon = stat.icon
          return (
            <div key={stat.name} className="card">
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-sm font-medium text-gray-600">{stat.name}</p>
                  <p className="text-2xl font-bold text-gray-900">{stat.value}</p>
                </div>
                <div className={`w-12 h-12 ${stat.color} rounded-lg flex items-center justify-center`}>
                  <Icon className="w-6 h-6 text-white" />
                </div>
              </div>
              <div className="mt-4">
                <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${
                  stat.changeType === 'positive' 
                    ? 'bg-green-100 text-green-800'
                    : stat.changeType === 'negative'
                    ? 'bg-red-100 text-red-800'
                    : 'bg-gray-100 text-gray-800'
                }`}>
                  {stat.change}
                </span>
              </div>
            </div>
          )
        })}
      </div>

      {/* Blockchain Info */}
      <div className="card">
        <h3 className="text-lg font-medium text-gray-900 mb-4">Blockchain Information</h3>
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          <div>
            <p className="text-sm text-gray-600">Latest Block Hash</p>
            <p className="text-sm font-mono text-gray-900 break-all">
              {blockchainInfo.latest_block_hash}
            </p>
          </div>
          <div>
            <p className="text-sm text-gray-600">Timestamp</p>
            <p className="text-sm text-gray-900">
              {new Date().toLocaleString()}
            </p>
          </div>
        </div>
      </div>

      {/* Quick Actions */}
      <div className="card">
        <h3 className="text-lg font-medium text-gray-900 mb-4">Quick Actions</h3>
        <div className="flex flex-wrap gap-4">
          <button className="btn-primary">
            <Activity className="w-4 h-4 mr-2" />
            View Latest Block
          </button>
          <button className="btn-secondary">
            <Coins className="w-4 h-4 mr-2" />
            Check Balance
          </button>
          <button className="btn-secondary">
            <Hash className="w-4 h-4 mr-2" />
            Mine Block
          </button>
        </div>
      </div>
    </div>
  )
}

export default BlockchainStatus
