import requests

def get_transfer_events(contract_address, fingerprint=None):
    url = f"https://api.trongrid.io/v1/contracts/{contract_address}/events?event_name=Transfer"
    if fingerprint:
        url += f"&fingerprint={fingerprint}"
    response = requests.get(url)
    data = response.json()
    return data

def get_unique_holders(transfer_events):
    holders = set()

    # 'data' anahtarına bakıyoruz, ardından her bir 'result' verisini kontrol ediyoruz
    if "data" in transfer_events:
        for event in transfer_events["data"]:
            result = event.get("result", {})
            from_address = result.get("from")
            to_address = result.get("to")
            
            if from_address and to_address:  # Eğer her iki adres de varsa, bunları ekle
                holders.add(from_address)
                holders.add(to_address)

    return holders

def check_token_holders(contract_address):
    transfer_events = get_transfer_events(contract_address)
    holders = get_unique_holders(transfer_events)
    return len(holders)

# Örnek bir token adresi: USDT'nin kontrat adresi
contract_address = "TR7NHqjeKQxGTCi8q8ZY4pL8otSzgjLj6t"

# İlk sayfadan veriyi al
holder_count = check_token_holders(contract_address)

print(f"Token {contract_address} has {holder_count} unique holders.")