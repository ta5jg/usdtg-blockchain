import requests
import json
from collections import Counter

# BTCBR kontrat adresleri
BTCBR_CONTRACTS = {
    "Ethereum": "0xe57425f1598f9b0d6219706b77f4b3da573a3695",
    "BSC": "0x0cf8e180350253271f4b917ccfb0acc4862f262"
}

# Explorer API'leri
EXPLORERS = {
    "Ethereum": "https://api.etherscan.io/api",
    "BSC": "https://api.bscscan.com/api"
}

# API key'lerinizi buraya girin
API_KEYS = {
    "Ethereum": "3NTHG48P4ZRNGZGD2DPZVK8X5X7KBMB7FM",
    "BSC": "44KUISZ8PFSYJJD7IAJ5YRCGXFVHKNN65M"
}

def get_top_holders(chain, max_pages=5):
    url = EXPLORERS[chain]
    address = BTCBR_CONTRACTS[chain]
    api_key = API_KEYS[chain]

    holders = Counter()
    for page in range(1, max_pages + 1):
        params = {
            "module": "account",
            "action": "tokentx",
            "contractaddress": address,
            "page": page,
            "offset": 100,
            "sort": "asc",
            "apikey": api_key
        }
        response = requests.get(url, params=params)
        if response.status_code != 200:
            print(f"HTTP hatası ({chain}): {response.status_code}")
            continue

        data = response.json()
        if data.get("status") != "1":
            print(f"Hata ({chain}): {data.get('message')}")
            continue

        for tx in data.get("result", []):
            to_address = tx.get("to")
            value = float(tx.get("value", 0))
            holders[to_address] += value

    return holders.most_common(20)

if __name__ == "__main__":
    print("BTCBR top holder adresleri alınıyor...\n")
    result_data = {}
    for chain in BTCBR_CONTRACTS:
        print(f"{chain} ağı için ilk 20 alıcı adres:")
        top_holders = get_top_holders(chain)
        result_data[chain] = top_holders
        for address, value in top_holders:
            print(f"  {address}: {value}")
        print("\n")

    with open("btcbr_top_holders.json", "w") as f:
        json.dump(result_data, f, indent=4)
    print("\nSonuçlar 'btcbr_top_holders.json' dosyasına yazıldı.")