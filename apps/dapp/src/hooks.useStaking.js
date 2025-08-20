
import { useCallback, useMemo, useState } from 'react'
import { ethers } from 'ethers'; import axios from 'axios'
const erc20 = [
  {"constant":true,"inputs":[{"name":"owner","type":"address"}],"name":"balanceOf","outputs":[{"name":"","type":"uint256"}],"type":"function"},
  {"constant":true,"inputs":[{"name":"owner","type":"address"},{"name":"spender","type":"address"}],"name":"allowance","outputs":[{"name":"","type":"uint256"}],"type":"function"},
  {"constant":false,"inputs":[{"name":"spender","type":"address"},{"name":"amount","type":"uint256"}],"name":"approve","outputs":[{"name":"","type":"bool"}],"type":"function"},
  {"constant":true,"inputs":[],"name":"decimals","outputs":[{"name":"","type":"uint8"}],"type":"function"}
]
const stakingAbi = [
  {"inputs":[{"internalType":"uint256","name":"amount","type":"uint256"}],"name":"deposit","outputs":[],"stateMutability":"nonpayable","type":"function"},
  {"inputs":[{"internalType":"uint256","name":"amount","type":"uint256"}],"name":"withdraw","outputs":[],"stateMutability":"nonpayable","type":"function"},
  {"inputs":[{"internalType":"address","name":"u","type":"address"}],"name":"pending","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},
  {"inputs":[{"internalType":"address","name":"","type":"address"}],"name":"users","outputs":[{"internalType":"uint256","name":"staked","type":"uint256"},{"internalType":"uint256","name":"rewardDebt","type":"uint256"}],"stateMutability":"view","type":"function"},
  {"inputs":[],"name":"endTime","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},
  {"inputs":[],"name":"rewardRatePerSec","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"}
]
export function useStaking({ network, provider, address, stakingAddress, lpTokenAddress }){
  const [stats, setStats] = useState({ tvl: 0, apr: 0, staked: 0, pending: 0, endsIn: 0, price: 1 })
  const [decimals, setDecimals] = useState(18)
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState(null)
  const ready = useMemo(()=> !!provider && stakingAddress && lpTokenAddress, [provider, stakingAddress, lpTokenAddress])
  const refresh = useCallback(async ()=>{
    if (!ready) return
    setLoading(true); setError(null)
    try {
      let tvl=0,pending=0,staked=0,endsIn=0,apr=0; let d=18; let rewardRate=0;
      if (network === 'evm') {
        const signer = provider.getSigner()
        const staking = new ethers.Contract(stakingAddress, stakingAbi, signer)
        const lp = new ethers.Contract(lpTokenAddress, erc20, signer)
        const [lpBal, pend, user, rr, endTime, lpDecimals] = await Promise.all([
          lp.balanceOf(stakingAddress), staking.pending(address || ethers.constants.AddressZero),
          staking.users(address || ethers.constants.AddressZero), staking.rewardRatePerSec(), staking.endTime(),
          lp.decimals().catch(()=>18)
        ])
        d = Number(lpDecimals); tvl = Number(ethers.utils.formatUnits(lpBal, d))
        pending = Number(ethers.utils.formatUnits(pend, 18)); staked = Number(ethers.utils.formatUnits(user.staked || 0, d))
        const now = Math.floor(Date.now()/1000); endsIn = Math.max(0, Number(endTime) - now)
        rewardRate = Number(ethers.utils.formatUnits(rr, 18))
      } else {
        const tw = provider
        const staking = await tw.contract(stakingAbi, stakingAddress)
        const lp = await tw.contract(erc20, lpTokenAddress)
        const [lpBal, pend, user, rr, endTime] = await Promise.all([
          lp.balanceOf(stakingAddress).call(), staking.pending(address || tw.defaultAddress.base58).call(),
          staking.users(address || tw.defaultAddress.base58).call(), staking.rewardRatePerSec().call(), staking.endTime().call()
        ])
        d = 18; tvl = Number(lpBal) / (10 ** d); pending = Number(pend) / (10 ** 18); staked = Number(user.staked || 0) / (10 ** d)
        const now = Math.floor(Date.now()/1000); endsIn = Math.max(0, Number(endTime) - now); rewardRate = Number(rr) / (10 ** 18)
      }
      let price = 1
      try {
        const r = await axios.get(import.meta.env.VITE_ORACLE_URL || 'http://localhost:8090/price')
        if (r?.data?.price) price = Number(r.data.price)
      } catch {}
      const yearlyReward = rewardRate * 31536000
      apr = tvl > 0 ? ( (yearlyReward * price) / tvl ) * 100 : 0
      setDecimals(d); setStats({ tvl, apr, staked, pending, endsIn, price })
    } catch (e){ setError(e.message) } finally { setLoading(false) }
  }, [ready, network, provider, address, stakingAddress, lpTokenAddress])
  const approveAndStake = useCallback(async (amount)=>{
    if (!ready) throw new Error('Not ready')
    if (network === 'evm') {
      const signer = provider.getSigner()
      const staking = new ethers.Contract(stakingAddress, stakingAbi, signer)
      const lp = new ethers.Contract(lpTokenAddress, erc20, signer)
      const amt = ethers.utils.parseUnits(String(amount), decimals)
      const allowance = await lp.allowance(await signer.getAddress(), stakingAddress)
      if (allowance.lt(amt)) { const tx1 = await lp.approve(stakingAddress, amt); await tx1.wait() }
      const tx2 = await staking.deposit(amt); await tx2.wait()
    } else {
      const tw = provider
      const staking = await tw.contract(stakingAbi, stakingAddress)
      const lp = await tw.contract(erc20, lpTokenAddress)
      const amt = (BigInt(Math.floor(Number(amount) * (10 ** decimals)))).toString()
      await lp.approve(stakingAddress, amt).send(); await staking.deposit(amt).send()
    }
  }, [ready, network, provider, stakingAddress, lpTokenAddress, decimals])
  const withdraw = useCallback(async (amount)=>{
    if (!ready) throw new Error('Not ready')
    if (network === 'evm') {
      const signer = provider.getSigner(); const staking = new ethers.Contract(stakingAddress, stakingAbi, signer)
      const amt = ethers.utils.parseUnits(String(amount), decimals); const tx = await staking.withdraw(amt); await tx.wait()
    } else {
      const tw = provider; const staking = await tw.contract(stakingAbi, stakingAddress)
      const amt = (BigInt(Math.floor(Number(amount) * (10 ** decimals)))).toString(); await staking.withdraw(amt).send()
    }
  }, [ready, network, provider, stakingAddress, decimals])
  return { stats, loading, error, refresh, approveAndStake, withdraw }
}
