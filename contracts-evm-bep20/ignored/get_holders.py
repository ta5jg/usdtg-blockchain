import os, random, requests
from tronpy import Tron
from tronpy.keys import PrivateKey
from dotenv import load_dotenv

load_dotenv()

# Ayarlar
PRIVATE_KEY = os.getenv("PRIVATE_KEY")
USDTG_CONTRACT = os.getenv("USDTG_CONTRACT")
TRONS_API = 'https://apilist.tronscanapi.com'

client = Tron()

# 2 holder adresini TronScan'den çek
def get_sample_holders():
    url = f"{TRONS_API}/api/token_trc20/holders"
    params = {
        'contract_address': 'TR7NHqjeKQxGTCi8q8ZY4pL8otSzgjLj6t',
        'limit': 2,
        'start': 0
    }
    res = requests.get(url, params=params).json()
    return [h['holder_address'] for h in res.get('trc20_tokens', [])]

# Token gönderme
def send_usdtg(to_addr, amount):
    amount_scaled = int(amount * 10**6)  # USDTg decimals=6
    raw_key = PRIVATE_KEY[2:] if PRIVATE_KEY.startswith("0x") else PRIVATE_KEY
    sender = PrivateKey(bytes.fromhex(raw_key))

    # Kontratı bağla
    contract = client.get_contract(USDTG_CONTRACT)

    txn = (
        contract.functions.transfer(to_addr, amount_scaled)
        .with_owner(sender.public_key.to_base58check_address())
        .fee_limit(5_000_000)
        .build()
        .sign(sender)
    )
    result = txn.broadcast().wait()
    print(f"✅ Sent {amount} USDTg to {to_addr} → TX: {txn.txid}")

def main():
    holders = get_sample_holders()
    for address in holders:
        amt = random.randint(5, 25)
        send_usdtg(address, amt)

if __name__ == "__main__":
    main()