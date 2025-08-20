import { useEffect, useState } from 'react'
import { useStaking } from './hooks.useStaking'

export default function Stake({ network, provider, address, stakingAddress, lpTokenAddress }){
  const [amount, setAmount] = useState('0')
  const { stats, loading, error, refresh, approveAndStake, withdraw } =
    useStaking({ network, provider, address, stakingAddress, lpTokenAddress })

  useEffect(()=>{ refresh() }, [refresh])

  const fmtTime = (s)=>{ const d=Math.floor(s/86400),h=Math.floor((s%86400)/3600),m=Math.floor((s%3600)/60); return `${d}g ${h}s ${m}d`; }

  return (
    <div className="card">
      <div className="text-xl font-semibold mb-2">Stake USDTg LP</div>

      {/* Özet kartlar */}
      <div className="grid md:grid-cols-3 gap-4 mb-4">
        <div className="card bg-slate-50">TVL: <b>{stats.tvl.toLocaleString()}</b></div>
        <div className="card bg-slate-50">APR (est.): <b>{stats.apr.toFixed(2)}%</b></div>
        <div className="card bg-slate-50">USDTg Price: <b>${stats.price.toFixed(4)}</b></div>
      </div>

      {/* Kullanıcı bilgileri */}
      <div className="grid md:grid-cols-2 gap-4 mb-4">
        <div className="card bg-slate-50">
          <div className="text-sm">Staking: <b>{stakingAddress || '—'}</b></div>
          <div className="text-sm">LP Token: <b>{lpTokenAddress || '—'}</b></div>
        </div>
        <div className="card bg-slate-50">
          <div className="text-sm">Your Staked: <b>{stats.staked.toLocaleString()}</b></div>
          <div className="text-sm">Pending Reward: <b>{stats.pending.toLocaleString()}</b></div>
          <div className="text-sm">Ends in: <b>{fmtTime(stats.endsIn)}</b></div>
          {error && <div className="text-red-600 text-sm mt-2">{error}</div>}
        </div>
      </div>

      {/* İşlemler */}
      <div className="grid md:grid-cols-2 gap-4">
        <div className="card">
          <div className="text-sm mb-2">Amount</div>
          <input type="number" min="0" step="0.0001" className="w-full border rounded-2xl px-3 py-2 mb-3" value={amount} onChange={e=>setAmount(e.target.value)} />
          <button className="btn w-full mb-2" disabled={loading || !address || !stakingAddress || !lpTokenAddress} onClick={()=>approveAndStake(Number(amount))}>
            {loading ? 'Processing…' : 'Approve & Stake'}
          </button>
        </div>
        <div className="card">
          <div className="text-sm mb-2">Withdraw</div>
          <input type="number" min="0" step="0.0001" className="w-full border rounded-2xl px-3 py-2 mb-3" value={amount} onChange={e=>setAmount(e.target.value)} />
          <button className="btn w-full" disabled={loading || !address || !stakingAddress} onClick={()=>withdraw(Number(amount))}>
            {loading ? 'Processing…' : 'Withdraw'}
          </button>
        </div>
      </div>
    </div>
  )
}