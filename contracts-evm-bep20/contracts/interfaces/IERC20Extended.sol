// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

/**
 * @title IERC20Extended
 * @dev Interface for ERC20Extended functionality
 * This interface defines the extended ERC20 methods
 */
interface IERC20Extended {
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
    function extendedLastTransferTime(address account) external view returns (uint256);
    function extendedTransferCount(address account) external view returns (uint256);
    function extendedTotalTransferred(address account) external view returns (uint256);
    
    // Configuration constants
    function EXTENDED_MIN_DELAY() external view returns (uint256);
    function EXTENDED_MAX_BATCH_SIZE() external view returns (uint256);
    
    /**
     * @dev Extended transfer with metadata
     */
    function transferWithMetadata(
        address to,
        uint256 amount,
        string calldata metadata
    ) external returns (bool);
    
    /**
     * @dev Batch transfer to multiple recipients
     */
    function batchTransfer(
        address[] calldata recipients,
        uint256[] calldata amounts
    ) external returns (bool);
    
    /**
     * @dev Check if transfer is allowed with extended rules
     */
    function isExtendedTransferAllowed(
        address from,
        address to,
        uint256 amount
    ) external view returns (bool allowed, string memory reason);
    
    /**
     * @dev Get extended transfer statistics
     */
    function getExtendedStats(address account) external view returns (
        uint256 lastTransfer,
        uint256 transferCount,
        uint256 totalTransferred
    );
} 