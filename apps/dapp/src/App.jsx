import { useState, useMemo } from 'react'
import { useWallet } from './hooks.useWallet'
import Stake from './Stake'
import Purchase from './Purchase'

export default function App(){
  const { network, setNetwork, address, provider, status, error, connect, disconnect, current } = useWallet()
  const [tab, setTab] = useState('purchase')

  const stakingAddress = useMemo(()=> current?.staking?.address || '', [current])
  const lpTokenAddress = useMemo(()=> current?.lp?.address || '', [current])

  return (
    <main className="max-w-4xl mx-auto p-6">
      <div className="card mb-4 flex flex-col sm:flex-row items-center justify-between gap-3">
        <div className="flex items-center gap-3">
          <label className="text-sm">Ağ</label>
          <select className="border rounded-2xl px-3 py-2" value={network} onChange={(e)=>setNetwork(e.target.value)}>
            <option value="tron">TRON</option>
            <option value="evm">BSC (EVM)</option>
          </select>
        </div>
        <div className="flex items-center gap-3">
          {status === 'connected'
            ? <button className="btn" onClick={disconnect}>Bağlantıyı Kes</button>
            : <button className="btn" onClick={()=>connect(network)}>{network==='tron' ? 'TronLink Bağla' : 'MetaMask Bağla'}</button>}
        </div>
      </div>

      <div className="text-sm mb-2">
        {address ? <>Bağlı: <b>{address}</b></> : 'Bağlı değil'} · Aktif ağ: <b>{network.toUpperCase()}</b>
      </div>
      {error && <div className="text-red-600 text-sm">{error}</div>}

      <div className="mt-4 flex gap-2 mb-4">
        <button className={`btn ${tab==='purchase' ? '' : 'opacity-70'}`} onClick={()=>setTab('purchase')}>Purchase</button>
        <button className={`btn ${tab==='stake' ? '' : 'opacity-70'}`} onClick={()=>setTab('stake')}>Stake</button>
      </div>

      {tab==='purchase' && <Purchase />}

      {tab==='stake' && (
        <Stake
          network={network}
          provider={provider}
          address={address}
          stakingAddress={stakingAddress}
          lpTokenAddress={lpTokenAddress}
        />
      )}
    </main>
  )
}