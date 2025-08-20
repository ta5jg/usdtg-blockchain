import raw from '../networks.config.json'

function injectEnv(str, fallback = '') {
  if (typeof str !== 'string') return fallback
  return str.replace(/\$\{(VITE_[A-Z0-9_]+)\}/g, (_, key) => import.meta.env[key] ?? fallback)
}

function numEnv(str, fallback = 18) {
  const v = injectEnv(String(str))
  const n = Number(v)
  return Number.isFinite(n) ? n : fallback
}

export function getNetworks() {
  const n = JSON.parse(JSON.stringify(raw)) // clone
  // TRON
  n.tron.token.address   = injectEnv(n.tron.token.address)
  n.tron.token.decimals  = numEnv(n.tron.token.decimals, 6)
  n.tron.lp.address      = injectEnv(n.tron.lp.address)
  n.tron.staking.address = injectEnv(n.tron.staking.address)
  // EVM
  n.evm.token.address    = injectEnv(n.evm.token.address)
  n.evm.token.decimals   = numEnv(n.evm.token.decimals, 18)
  n.evm.lp.address       = injectEnv(n.evm.lp.address)
  n.evm.staking.address  = injectEnv(n.evm.staking.address)
  return n
}

export function getDefaultNetwork() {
  const v = (import.meta.env.VITE_DEFAULT_NETWORK || 'tron').toLowerCase()
  return (v === 'tron' || v === 'evm') ? v : 'tron'
}