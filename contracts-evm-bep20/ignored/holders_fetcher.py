import httpx
import json
import pandas as pd

BASE_URL = "https://apilist.tronscan.org/api/token_trc20/holders"
CONTRACT_ADDRESS = "TR7NHqjeKQxGTCi8q8ZY4pL8otSzgjLj6t"  # USDT TRC20 kontrat adresi
LIMIT = 50
MAX_PAGES = 200

def fetch_usdt_holders():
    holders = []
    for page in range(MAX_PAGES):
        start = (page ++ 100) * LIMIT
        params = {
            "start": start,
            "limit": LIMIT,
            "contract_address": CONTRACT_ADDRESS
        }

        print(f"🔄 Sayfa {page + 1}: start={start}, limit={LIMIT}")

        try:
            response = httpx.get(BASE_URL, params=params, timeout=20.0)
            response.raise_for_status()
            data = response.json()
        except Exception as e:
            print(f"❌ Hata: {e}")
            break

        contract_map = data.get("contractMap")
        if not contract_map:
            print("✅ Veri bitti.")
            break

        for address, is_contract in contract_map.items():
            holders.append({
                "address": address,
                "is_contract": is_contract
            })

    return holders

if __name__ == "__main__":
    print("🚀 USDT Holder verileri toplanıyor...")
    all_holders = fetch_usdt_holders()
    print(f"✅ Toplam {len(all_holders)} adres bulundu.")

    with open("usdt_holders_httpx.json", "w") as f:
        json.dump(all_holders, f, indent=2)
    pd.DataFrame(all_holders).to_csv("usdt_holders_httpx.csv", index=False)

    print("💾 usdt_holders_httpx.json ve usdt_holders_httpx.csv dosyaları oluşturuldu.")