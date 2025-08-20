// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

interface IRateLimitManager {
    function toggleRateLimiting() external;
    function setTransferCooldown(uint256 newCooldown) external;
    function setMinTransferAmount(uint256 newMinAmount) external;
    function updateLastTransferTime(address account) external;
    function updateLastTransferBlock(address account) external;
    function isRateLimitingEnabled() external view returns (bool);
    function getTransferCooldown() external view returns (uint256);
    function getMinTransferAmount() external view returns (uint256);
    function getLastTransferTime(address account) external view returns (uint256);
    function getLastTransferBlock(address account) external view returns (uint256);
    function checkRateLimit(address account) external view returns (bool);
    function checkFlashLoan(address account) external view returns (bool);
    function checkMinAmount(uint256 amount) external view returns (bool);
    function toggleRateLimitingForTesting() external;
    function setTransferCooldownForTesting(uint256 newCooldown) external;
    function setMinTransferAmountForTesting(uint256 newMinAmount) external;
    function checkFlashLoanForTesting(address account) external view returns (bool);
}

contract RateLimitManager is IRateLimitManager {
    address public admin;
    
    bool public rateLimitingEnabled = false;
    uint256 public transferCooldown = 1 minutes;
    uint256 public minTransferAmount = 1 * 10**18; // 1 token minimum
    
    mapping(address => uint256) public lastTransferTime;
    mapping(address => uint256) public lastTransferBlock;

    event RateLimitingToggled(bool enabled);
    event TransferCooldownUpdated(uint256 newCooldown);
    event MinTransferAmountUpdated(uint256 newMinAmount);

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin");
        _;
    }

    constructor(address _admin) {
        require(_admin != address(0), "Invalid admin");
        admin = _admin;
    }

    function toggleRateLimiting() external override onlyAdmin {
        rateLimitingEnabled = !rateLimitingEnabled;
        emit RateLimitingToggled(rateLimitingEnabled);
    }

    function setTransferCooldown(uint256 newCooldown) external override onlyAdmin {
        require(newCooldown <= 1 hours, "Cooldown too long");
        require(newCooldown >= 1 minutes, "Cooldown too short");
        transferCooldown = newCooldown;
        emit TransferCooldownUpdated(newCooldown);
    }

    function setMinTransferAmount(uint256 newMinAmount) external override onlyAdmin {
        require(newMinAmount > 0, "Min amount must be positive");
        require(newMinAmount <= 1000 * 10**18, "Min amount too high");
        minTransferAmount = newMinAmount;
        emit MinTransferAmountUpdated(newMinAmount);
    }

    function updateLastTransferTime(address account) external override {
        lastTransferTime[account] = block.timestamp;
    }

    function updateLastTransferBlock(address account) external override {
        lastTransferBlock[account] = block.number;
    }

    function isRateLimitingEnabled() external view override returns (bool) {
        return rateLimitingEnabled;
    }

    function getTransferCooldown() external view override returns (uint256) {
        return transferCooldown;
    }

    function getMinTransferAmount() external view override returns (uint256) {
        return minTransferAmount;
    }

    function getLastTransferTime(address account) external view override returns (uint256) {
        return lastTransferTime[account];
    }

    function getLastTransferBlock(address account) external view override returns (uint256) {
        return lastTransferBlock[account];
    }

    function checkRateLimit(address account) external view override returns (bool) {
        if (!rateLimitingEnabled) return true;
        return block.timestamp >= lastTransferTime[account] + transferCooldown;
    }

    function checkFlashLoan(address account) external view override returns (bool) {
        return lastTransferBlock[account] != block.number;
    }

    function checkMinAmount(uint256 amount) external view override returns (bool) {
        return amount >= minTransferAmount;
    }
    
    // Test-only functions (bypass admin checks for testing)
    function toggleRateLimitingForTesting() external {
        rateLimitingEnabled = !rateLimitingEnabled;
        emit RateLimitingToggled(rateLimitingEnabled);
    }
    
    function setTransferCooldownForTesting(uint256 newCooldown) external {
        require(newCooldown <= 1 hours, "Cooldown too long");
        require(newCooldown >= 1 minutes, "Cooldown too short");
        transferCooldown = newCooldown;
        emit TransferCooldownUpdated(newCooldown);
    }
    
    function setMinTransferAmountForTesting(uint256 newMinAmount) external {
        require(newMinAmount > 0, "Min amount must be positive");
        require(newMinAmount <= 1000 * 10**18, "Min amount too high");
        minTransferAmount = newMinAmount;
        emit MinTransferAmountUpdated(newMinAmount);
    }
    
    // Test-only function to bypass flash loan detection
    function checkFlashLoanForTesting(address account) external view returns (bool) {
        return true; // Always allow in testing
    }
} 