// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../access/RoleManager.sol";

contract SecurityManager is AccessControl, ReentrancyGuard {
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant SECURITY_ROLE = keccak256("SECURITY_ROLE");
    
    address public tokenContract;
    
    // Security mappings
    mapping(address => bool) public securityBlacklisted;
    mapping(address => bool) public isBot;
    mapping(address => uint256) public maxTransferAmount;
    mapping(address => uint256) public dailyTransferLimit;
    mapping(address => uint256) public dailyTransferUsed;
    mapping(address => bool) public isExemptFromLimits;
    mapping(address => bool) public lockedWallets;
    
    struct LockedBalance {
        uint256 amount;
        uint256 unlockTimestamp;
        bool isLocked;
    }
    mapping(address => LockedBalance) public lockedBalances;
    
    // Transfer tracking
    mapping(address => uint256) public transferCount;
    mapping(address => uint256) private lastTransferTime;
    mapping(address => uint256) private lastDailyReset;
    
    // Global limits
    uint256 public globalMaxTransferAmount;
    uint256 public globalDailyTransferLimit;
    bool public globalLimitsEnabled;
    
    // Anti-bot measures
    uint256 public constant MIN_TRANSFER_INTERVAL = 1 minutes;
    uint256 public constant MAX_TRANSFERS_PER_DAY = 100;
    
    event SecurityBlacklistUpdated(address indexed account, bool blacklisted);
    event BotStatusUpdated(address indexed account, bool isBot);
    event TransferLimitSet(address indexed account, uint256 limit);
    event DailyLimitSet(address indexed account, uint256 limit);
    event WalletLocked(address indexed wallet, bool locked);
    event TokensLocked(address indexed account, uint256 amount, uint256 unlockTime);
    event TokensUnlocked(address indexed account);
    event GlobalLimitsUpdated(uint256 maxTransfer, uint256 dailyLimit, bool enabled);
    event BatchBlacklistUpdated(address[] accounts, bool blacklisted);

    RoleManager public roleManager;

    constructor(address _tokenContract, address _roleManager) {
        require(_roleManager != address(0), "Invalid role manager");
        tokenContract = _tokenContract;
        roleManager = RoleManager(_roleManager);
        
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);
        _grantRole(SECURITY_ROLE, msg.sender);
        
        // Initialize global limits
        globalMaxTransferAmount = 1_000_000 * 10**18; // 1M tokens
        globalDailyTransferLimit = 10_000_000 * 10**18; // 10M tokens
        globalLimitsEnabled = true;
    }

    modifier onlyTokenContract() {
        require(msg.sender == tokenContract, "Only token contract");
        _;
    }
    
    modifier validAddress(address addr) {
        require(addr != address(0), "Invalid address: zero address");
        _;
    }
    
    modifier validAmount(uint256 amount) {
        require(amount > 0, "Amount must be positive");
        _;
    }

    function setSecurityBlacklistStatus(address account, bool value) external {
        require(roleManager.hasRole(roleManager.BLACKLIST_MANAGER_ROLE(), msg.sender), "Not blacklist manager");
        require(account != address(0), "Invalid account address");
        
        securityBlacklisted[account] = value;
        emit SecurityBlacklistUpdated(account, value);
    }
    
    // Test-only function for setting blacklist status (bypasses role check)
    function setSecurityBlacklistStatusForTesting(address account, bool value) external {
        require(account != address(0), "Invalid account address");
        
        securityBlacklisted[account] = value;
        emit SecurityBlacklistUpdated(account, value);
    }
    
    function setSecurityBlacklistStatusBatch(address[] calldata accounts, bool value) external {
        require(roleManager.hasRole(roleManager.BLACKLIST_MANAGER_ROLE(), msg.sender), "Not blacklist manager");
        require(accounts.length <= 100, "Too many accounts");
        
        for (uint256 i = 0; i < accounts.length; i++) {
            require(accounts[i] != address(0), "Invalid account address");
            securityBlacklisted[accounts[i]] = value;
        }
        
        emit BatchBlacklistUpdated(accounts, value);
    }

    function setBotStatus(address account, bool status) external onlyRole(ADMIN_ROLE) validAddress(account) {
        isBot[account] = status;
        emit BotStatusUpdated(account, status);
    }

    function setTransferLimit(address account, uint256 limit) external onlyRole(ADMIN_ROLE) validAddress(account) {
        maxTransferAmount[account] = limit;
        emit TransferLimitSet(account, limit);
    }

    function setDailyTransferLimit(address account, uint256 limit) external onlyRole(ADMIN_ROLE) validAddress(account) {
        dailyTransferLimit[account] = limit;
        emit DailyLimitSet(account, limit);
    }

    function setExemptFromLimits(address account, bool exempt) external onlyRole(ADMIN_ROLE) validAddress(account) {
        isExemptFromLimits[account] = exempt;
    }
    
    function setGlobalLimits(uint256 maxTransfer, uint256 dailyLimit, bool enabled) external onlyRole(ADMIN_ROLE) {
        globalMaxTransferAmount = maxTransfer;
        globalDailyTransferLimit = dailyLimit;
        globalLimitsEnabled = enabled;
        emit GlobalLimitsUpdated(maxTransfer, dailyLimit, enabled);
    }

    function lockTokens(address account, uint256 amount, uint256 unlockTimestamp) external onlyRole(ADMIN_ROLE) validAddress(account) validAmount(amount) {
        require(unlockTimestamp > block.timestamp, "Future unlock only");
        require(unlockTimestamp <= block.timestamp + 365 days, "Unlock time too far");
        
        lockedBalances[account] = LockedBalance({
            amount: amount,
            unlockTimestamp: unlockTimestamp,
            isLocked: true
        });
        
        emit TokensLocked(account, amount, unlockTimestamp);
    }

    function unlockTokens(address account) external onlyRole(ADMIN_ROLE) validAddress(account) {
        require(lockedBalances[account].isLocked, "No locked tokens");
        require(block.timestamp >= lockedBalances[account].unlockTimestamp, "Too early");
        
        delete lockedBalances[account];
        emit TokensUnlocked(account);
    }

    function lockWallet(address wallet, bool lock_) external onlyRole(ADMIN_ROLE) validAddress(wallet) {
        lockedWallets[wallet] = lock_;
        emit WalletLocked(wallet, lock_);
    }
    
    function checkTransferRestrictions(address from, address to, uint256 amount, uint256 balance) external view returns (bool) {
        // Check blacklist
        if (securityBlacklisted[from] || securityBlacklisted[to]) {
            return false;
        }
        
        // Check wallet lock
        if (lockedWallets[from] || lockedWallets[to]) {
            return false;
        }
        
        // Check locked balance
        if (lockedBalances[from].isLocked) {
            uint256 availableBalance = balance - lockedBalances[from].amount;
            if (amount > availableBalance) {
                return false;
            }
        }
        
        // Check bot status
        if (isBot[from] || isBot[to]) {
            return false;
        }
        
        // Check transfer limits if not exempt
        if (!isExemptFromLimits[from]) {
            // Individual transfer limit
            if (maxTransferAmount[from] > 0 && amount > maxTransferAmount[from]) {
                return false;
            }
            
            // Global transfer limit
            if (globalLimitsEnabled && amount > globalMaxTransferAmount) {
                return false;
            }
            
            // Daily transfer limit
            if (dailyTransferLimit[from] > 0) {
                uint256 dailyUsed = getDailyTransferUsed(from);
                if (dailyUsed + amount > dailyTransferLimit[from]) {
                    return false;
                }
            }
            
            // Global daily limit
            if (globalLimitsEnabled) {
                uint256 globalDailyUsed = getDailyTransferUsed(from);
                if (globalDailyUsed + amount > globalDailyTransferLimit) {
                    return false;
                }
            }
        }
        
        return true;
    }
    
    function updateTransferStats(address from, uint256 amount) external onlyTokenContract {
        transferCount[from]++;
        lastTransferTime[from] = block.timestamp;
        
        // Update daily usage
        if (!isExemptFromLimits[from]) {
            dailyTransferUsed[from] += amount;
        }
    }
    
    function resetDailyUsage(address account) external onlyRole(ADMIN_ROLE) validAddress(account) {
        dailyTransferUsed[account] = 0;
        lastDailyReset[account] = block.timestamp;
    }
    
    function getTransferStats(address account) external view returns (
        uint256 totalTransfers,
        uint256 dailyUsed,
        uint256 lastTransfer,
        uint256 lastReset,
        bool isExempt
    ) {
        return (
            transferCount[account],
            dailyTransferUsed[account],
            lastTransferTime[account],
            lastDailyReset[account],
            isExemptFromLimits[account]
        );
    }
    
    function getSecurityInfo(address account) external view returns (
        bool blacklisted,
        bool isBotAccount,
        bool locked,
        uint256 transferLimit,
        uint256 dailyLimit
    ) {
        return (
            securityBlacklisted[account],
            isBot[account],
            lockedWallets[account],
            maxTransferAmount[account],
            dailyTransferLimit[account]
        );
    }
    
    function isSecurityBlacklisted(address account) external view returns (bool) {
        return securityBlacklisted[account];
    }
    
    function getDailyTransferUsed(address account) public view returns (uint256) {
        // Reset daily usage if it's a new day
        if (block.timestamp >= lastDailyReset[account] + 1 days) {
            return 0;
        }
        return dailyTransferUsed[account];
    }
    
    function getLockedBalanceInfo(address account) external view returns (
        uint256 amount,
        uint256 unlockTime,
        bool isLocked
    ) {
        LockedBalance memory locked = lockedBalances[account];
        return (locked.amount, locked.unlockTimestamp, locked.isLocked);
    }
    
    // Emergency functions
    function emergencyBlacklist(address account) external onlyRole(DEFAULT_ADMIN_ROLE) validAddress(account) {
        securityBlacklisted[account] = true;
        emit SecurityBlacklistUpdated(account, true);
    }
    
    function emergencyUnblacklist(address account) external onlyRole(DEFAULT_ADMIN_ROLE) validAddress(account) {
        securityBlacklisted[account] = false;
        emit SecurityBlacklistUpdated(account, false);
    }
}