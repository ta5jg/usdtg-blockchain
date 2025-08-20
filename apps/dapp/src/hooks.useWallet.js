import { useEffect, useState } from 'react'
import TronWeb from 'tronweb'
import { ethers } from 'ethers'
import { getNetworks, getDefaultNetwork } from './lib/config'

export function useWallet(){
  const [network, setNetwork] = useState(getDefaultNetwork()) // 'tron' | 'evm'
  const [address, setAddress] = useState(null)
  const [provider, setProvider] = useState(null)
  const [status, setStatus] = useState('idle')
  const [error, setError] = useState(null)

  const nets = getNetworks()
  const current = nets[network]

  const connect = async (desired = network) => {
    try {
      setStatus('connecting'); setError(null)
      if (desired === 'tron') {
        if (!window.tronWeb || !window.tronLink) throw new Error('TronLink not found')
        await window.tronLink.request({ method:'tron_requestAccounts' })
        setProvider(window.tronWeb)
        setAddress(window.tronWeb.defaultAddress.base58)
      } else {
        if (!window.ethereum) throw new Error('MetaMask not found')
        const ethProvider = new ethers.providers.Web3Provider(window.ethereum, 'any')
        await ethProvider.send('eth_requestAccounts', [])
        const signer = ethProvider.getSigner()
        setProvider(ethProvider)
        setAddress(await signer.getAddress())
      }
      setNetwork(desired)
      setStatus('connected')
    } catch (e) { setError(e.message); setStatus('error') }
  }

  const disconnect = () => { setAddress(null); setProvider(null); setStatus('idle') }

  // TRON otomatik hazır ise bağla
  useEffect(()=>{
    const t = setTimeout(()=>{
      if (network==='tron' && window.tronWeb && window.tronWeb.ready && !address){
        setProvider(window.tronWeb)
        setAddress(window.tronWeb.defaultAddress.base58)
        setStatus('connected')
      }
    }, 700)
    return ()=>clearTimeout(t)
  }, [network, address])

  // Dışarıya: ağ konfigürasyonu da ver
  return { network, setNetwork, address, provider, status, error, connect, disconnect, nets, current }
}