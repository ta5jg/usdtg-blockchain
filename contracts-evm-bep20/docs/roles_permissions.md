# Roles & Permissions Matrix

## Overview
This document details all roles in the USDExchangeToken system, their permissions, and how multisig/timelock governance is enforced. All role checks are centralized in the RoleManager contract.

## Core Roles

| Role Name                | Description                                 | Can Call Functions (examples)                |
|-------------------------|---------------------------------------------|----------------------------------------------|
| DEFAULT_ADMIN_ROLE       | System super-admin (multisig/timelock)      | All admin-level functions, manager setters   |
| OWNER_ROLE               | Project owner, can manage all sub-roles     | Grant/revoke any role, emergency actions     |
| MINTER_ROLE              | Can mint new tokens                         | mint, mintForStablecoin                      |
| BURNER_ROLE              | Can burn tokens                             | burn, burnFrom                               |
| PAUSER_ROLE              | Can pause/unpause transfers                 | pause, unpause                               |
| BLACKLIST_MANAGER_ROLE   | Can manage blacklist/anti-fraud             | setSecurityBlacklistStatus                   |
| FEE_MANAGER_ROLE         | Can set fees, exemptions, recipients        | setFee, setFeeRecipient, setFeeExemption     |
| SECURITY_MANAGER_ROLE    | Can set transfer/lock/anti-bot params       | setTransferLimit, lockTokens, etc.           |
| METADATA_MANAGER_ROLE    | Can update project metadata                 | updateMetadata, updateLogoURI, etc.          |
| GOVERNANCE_MANAGER_ROLE  | Can manage proposals/voting                 | createProposal, vote, executeProposal        |
| VESTING_MANAGER_ROLE     | Can manage vesting wallets/schedules        | createVestingWallet, transferToVesting       |
| STABLECOIN_MANAGER_ROLE  | Can manage stablecoin purchases/whitelist   | setStableTokenWhitelist, setUSDPrice         |
| EMERGENCY_ROLE           | Can pause, blacklist, emergency actions     | pause, setSecurityBlacklistStatus            |

## Permission Enforcement
- **All admin-level functions** (manager setters, role ops, critical param changes) are restricted to `onlyMultisigOrTimelock`.
- **Role checks** for operational functions (mint, burn, blacklist, etc.) are delegated to RoleManager via `hasRole` interface calls.
- **RoleManager** is the only contract with direct AccessControl logic; all others use interface-based checks.

## Multisig & Timelock Governance
- **MultisigWallet**: All admin-level actions must be submitted and confirmed by multiple signers.
- **Timelock**: (Optional) All admin-level actions can be delayed and queued for execution after a minimum delay.
- **Changing multisig/timelock addresses** is itself restricted to the current multisig/timelock.

## Example Access Matrix

| Function                        | Who Can Call?                | How Enforced?                |
|----------------------------------|------------------------------|------------------------------|
| setRoleManager                   | Multisig/Timelock            | onlyMultisigOrTimelock       |
| grantRole, revokeRole            | Multisig/Timelock            | onlyMultisigOrTimelock       |
| setFee, setFeeRecipient          | Multisig/Timelock            | onlyMultisigOrTimelock       |
| mint, burn                       | MINTER_ROLE, BURNER_ROLE     | RoleManager.hasRole          |
| setSecurityBlacklistStatus       | BLACKLIST_MANAGER_ROLE       | RoleManager.hasRole          |
| pause, unpause                   | PAUSER_ROLE                  | RoleManager.hasRole          |
| createVestingWallet              | Multisig/Timelock            | onlyMultisigOrTimelock       |
| transferToVesting                | Multisig/Timelock            | onlyMultisigOrTimelock       |
| setStableTokenWhitelist          | Multisig/Timelock            | onlyMultisigOrTimelock       |
| submitMultisigTransaction        | Any signer                   | MultisigWallet logic         |
| executeProposal                  | GOVERNANCE_MANAGER_ROLE      | RoleManager.hasRole          |

## Notes
- All permission changes and admin actions are logged with detailed events for auditability.
- The system is designed for maximum separation of concerns and upgradability. 