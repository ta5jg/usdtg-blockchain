from manticore.ethereum import ManticoreEVM
from manticore.core.smtlib import Operators

m = ManticoreEVM()
user_account = m.create_account(balance=1000)
with open("contracts/USDTgToken.sol") as f:
    source_code = f.read()
contract_account = m.solidity_create_contract(source_code, owner=user_account)

print("🧪 Manticore setup complete. Manual test writing is recommended.")
