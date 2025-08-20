// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

/**
 * @title IReentrancyGuardCore
 * @dev Interface for ReentrancyGuardCore functionality
 * This interface defines the reentrancy protection methods
 */
interface IReentrancyGuardCore {
    // Events
    event ReentrancyGuardEntered(address indexed caller, uint256 timestamp);
    event ReentrancyGuardExited(address indexed caller, uint256 timestamp);
    event ReentrancyGuardViolation(address indexed caller, uint256 timestamp);
    
    /**
     * @dev Returns true if the contract is currently in a reentrant call
     */
    function _isReentrant() external view returns (bool);
    
    /**
     * @dev Returns the current reentrancy status
     */
    function _getReentrancyStatus() external view returns (uint256);
    
    /**
     * @dev Emergency function to reset reentrancy status
     */
    function _emergencyResetReentrancy() external;
    
    /**
     * @dev Function to check if a call would be reentrant
     */
    function _checkReentrancy() external view;
} 