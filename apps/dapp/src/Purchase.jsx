
import axios from 'axios'
import { useState } from 'react'
export default function Purchase(){
  const [amount, setAmount] = useState('100')
  const [address, setAddress] = useState('')
  const [resp, setResp] = useState(null)
  const buy = async ()=>{
    try {
      const r = await axios.post(import.meta.env.VITE_API_URL || 'http://localhost:8080/purchase', { amount: Number(amount), address, currency:'USDT' })
      setResp(r.data)
    } catch (e){ setResp({ ok:false, error: e.message }) }
  }
  return (
    <div className="card">
      <div className="text-xl font-semibold mb-2">Buy USDTg</div>
      <div className="grid md:grid-cols-2 gap-4">
        <div className="card bg-slate-50">
          <div className="text-sm mb-1">Amount (USDT)</div>
          <input className="w-full border rounded-xl px-3 py-2 mb-2" value={amount} onChange={e=>setAmount(e.target.value)} />
          <div className="text-sm mb-1">Receiving Address</div>
          <input className="w-full border rounded-xl px-3 py-2 mb-2" placeholder="Your TRON/EVM address" value={address} onChange={e=>setAddress(e.target.value)} />
          <button className="btn w-full mt-1" onClick={buy}>Buy</button>
        </div>
        <div className="card bg-slate-50 text-sm">
          <div className="font-semibold mb-1">KYC/AML</div>
          <p className="opacity-80">On-ramp may require identity checks. Integrate provider or manual OTC process.</p>
          {resp && <pre className="mt-3 text-xs whitespace-pre-wrap">{JSON.stringify(resp,null,2)}</pre>}
        </div>
      </div>
      <div className="card bg-slate-50 mt-4">
        <div className="text-sm mb-2 font-semibold">Swap & Add Liquidity</div>
        <ul className="list-disc pl-6 text-sm mt-2">
          <li><a href="#" target="_blank">Swap USDTg/USDT (SunSwap)</a></li>
          <li><a href="#" target="_blank">Add Liquidity USDTg/USDT</a></li>
          <li><a href="#" target="_blank">Swap USDTg/TRX</a></li>
        </ul>
      </div>
    </div>
  )
}
