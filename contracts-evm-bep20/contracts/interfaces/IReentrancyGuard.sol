// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

/**
 * @title IReentrancyGuard
 * @dev Interface for reentrancy protection functionality
 */
interface IReentrancyGuard {
    /**
     * @dev Returns true if the contract is currently executing a function
     */
    function _notEntered() external view returns (bool);
    
    /**
     * @dev Emitted when a reentrant call is detected
     */
    event ReentrancyGuardReentrantCall();
} 