// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./ReentrancyGuardCore.sol";

/**
 * @title ERC20Extended
 * @dev Extended ERC20 implementation with project-specific features
 * This extends OpenZeppelin's ERC20 rather than replacing it
 */
abstract contract ERC20Extended is ERC20, ReentrancyGuardCore {
    // Extended events
    event TransferWithMetadata(
        address indexed from,
        address indexed to,
        uint256 amount,
        string metadata
    );
    
    event BatchTransfer(
        address indexed from,
        address[] recipients,
        uint256[] amounts
    );
    
    event TransferRestricted(
        address indexed from,
        address indexed to,
        uint256 amount,
        string reason
    );
    
    // Extended state variables
    mapping(address => uint256) public extendedLastTransferTime;
    mapping(address => uint256) public extendedTransferCount;
    mapping(address => uint256) public extendedTotalTransferred;
    
    // Configuration
    uint256 public constant EXTENDED_MIN_DELAY = 30; // 30 seconds
    uint256 public constant EXTENDED_MAX_BATCH_SIZE = 100;
    
    /**
     * @dev Extended transfer with metadata
     */
    function transferWithMetadata(
        address to,
        uint256 amount,
        string calldata metadata
    ) external nonReentrant returns (bool) {
        bool success = transfer(to, amount);
        if (success) {
            emit TransferWithMetadata(msg.sender, to, amount, metadata);
            _updateExtendedStats(msg.sender, amount);
        }
        return success;
    }
    
    /**
     * @dev Batch transfer to multiple recipients
     */
    function batchTransfer(
        address[] calldata recipients,
        uint256[] calldata amounts
    ) external nonReentrant returns (bool) {
        require(recipients.length == amounts.length, "Arrays length mismatch");
        require(recipients.length <= EXTENDED_MAX_BATCH_SIZE, "Batch too large");
        
        uint256 totalAmount = 0;
        for (uint256 i = 0; i < amounts.length; i++) {
            totalAmount += amounts[i];
        }
        
        require(balanceOf(msg.sender) >= totalAmount, "Insufficient balance");
        
        for (uint256 i = 0; i < recipients.length; i++) {
            require(recipients[i] != address(0), "Invalid recipient");
            _transfer(msg.sender, recipients[i], amounts[i]);
            _updateExtendedStats(msg.sender, amounts[i]);
        }
        
        emit BatchTransfer(msg.sender, recipients, amounts);
        return true;
    }
    
    /**
     * @dev Check if transfer is allowed with extended rules
     */
    function isExtendedTransferAllowed(
        address from,
        address to,
        uint256 amount
    ) external view returns (bool allowed, string memory reason) {
        // Basic checks
        if (from == address(0) || to == address(0)) {
            return (false, "Invalid addresses");
        }
        
        if (amount == 0) {
            return (false, "Zero amount");
        }
        
        if (balanceOf(from) < amount) {
            return (false, "Insufficient balance");
        }
        
        // Extended cooldown check
        if (block.timestamp < extendedLastTransferTime[from] + EXTENDED_MIN_DELAY) {
            return (false, "Cooldown active");
        }
        
        return (true, "");
    }
    
    /**
     * @dev Get extended transfer statistics
     */
    function getExtendedStats(address account) external view returns (
        uint256 lastTransfer,
        uint256 transferCount,
        uint256 totalTransferred
    ) {
        return (
            extendedLastTransferTime[account],
            extendedTransferCount[account],
            extendedTotalTransferred[account]
        );
    }
    
    /**
     * @dev Override _beforeTokenTransfer to add extended functionality
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);
        
        // Extended validation
        if (from != address(0)) { // Not minting
            require(
                block.timestamp >= extendedLastTransferTime[from] + EXTENDED_MIN_DELAY,
                "Extended cooldown active"
            );
        }
    }
    
    /**
     * @dev Override _afterTokenTransfer to update extended stats
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        super._afterTokenTransfer(from, to, amount);
        
        // Update extended statistics
        if (from != address(0)) { // Not minting
            _updateExtendedStats(from, amount);
        }
    }
    
    /**
     * @dev Update extended transfer statistics
     */
    function _updateExtendedStats(address from, uint256 amount) internal {
        extendedLastTransferTime[from] = block.timestamp;
        extendedTransferCount[from]++;
        extendedTotalTransferred[from] += amount;
    }
    
    /**
     * @dev Emergency function to reset extended stats (admin only)
     */
    function _emergencyResetExtendedStats(address account) internal {
        extendedLastTransferTime[account] = 0;
        extendedTransferCount[account] = 0;
        extendedTotalTransferred[account] = 0;
    }
} 