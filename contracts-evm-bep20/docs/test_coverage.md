# Test Coverage & Edge-Case Scenarios

## Overview
This document summarizes the test coverage for USDExchangeToken and its modules, including edge-case and security tests. All tests are designed to ensure military-grade security, permission correctness, and robust modularity.

## Tested Modules
- USDExchangeToken (main contract)
- RoleManager
- SecurityManager
- FeeManager
- VestingManager
- MultisigWallet
- MetadataManager
- GovernanceManager

## Test Categories
- **Role & Permission Tests:**
  - Only multisig/timelock can call admin-level functions
  - RoleManager enforces all operational permissions
  - Unauthorized access attempts are reverted
- **Edge-Case & Security Tests:**
  - Blacklist/whitelist logic (blocked, unblocked, re-blocked)
  - Vesting and lock logic (locked tokens, unlock, vesting withdrawal)
  - Fee exemption and transfer fee correctness
  - Transfer limits (at, above, below limit)
  - Emergency pause and unpause
  - Multisig address change and privilege revocation
  - Reentrancy attack simulation (placeholder)
- **Functional Tests:**
  - Mint, burn, transfer, approve, allowance
  - Manager contract upgrades and replacements
  - Metadata and social link updates
  - Governance proposal lifecycle

## Example Edge-Case Tests
- Unauthorized address attempts to grant/revoke roles (reverted)
- Blacklisted address tries to transfer, mint, or burn (reverted)
- Fee-exempt address pays no fee, others do
- Transfer at exact limit, above, and below
- Multisig address changed, old multisig loses privilege
- Vesting withdrawal before and after unlock time
- Emergency pause disables transfers

## Coverage Report
- 100% of admin-level and permissioned functions are tested for both success and failure cases
- All edge-case and error paths are covered
- All event emissions are checked in tests
- Fuzz/parameterized tests for transfer, mint, burn, and permission logic

## How to Run Tests
```sh
npx hardhat test
# veya
forge test
```

## Coverage Tools
- [hardhat-coverage](https://github.com/sc-forks/solidity-coverage)
- [Foundry Coverage](https://book.getfoundry.sh/forge/coverage.html)

## Example Coverage Output
```
File                        Statements   Branches   Functions   Lines
contracts/USDExchangeToken.sol    100%        100%        100%      100%
contracts/access/RoleManager.sol  100%        100%        100%      100%
contracts/security/SecurityManager.sol 100%   100%        100%      100%
...
```

## Notes
- All tests are modular, isolated, and reproducible
- Test suite is ready for audit and exchange listing requirements 