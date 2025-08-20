// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "../interfaces/IReentrancyGuard.sol";

/**
 * @title ReentrancyGuardCore
 * @dev Minimal reentrancy protection implementation for the project
 * This is a simplified version of OpenZeppelin's ReentrancyGuard
 * designed specifically for this project's needs
 */
abstract contract ReentrancyGuardCore is IReentrancyGuard {
    // Reentrancy guard state
    uint256 private _reentrancyStatus;
    
    // Constants for reentrancy status
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    
    // Events
    event ReentrancyGuardEntered(address indexed caller, uint256 timestamp);
    event ReentrancyGuardExited(address indexed caller, uint256 timestamp);
    event ReentrancyGuardViolation(address indexed caller, uint256 timestamp);
    
    constructor() {
        _reentrancyStatus = _NOT_ENTERED;
    }
    
    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_reentrancyStatus != _ENTERED, "ReentrancyGuard: reentrant call");
        
        // Any calls to nonReentrant after this point will fail
        _reentrancyStatus = _ENTERED;
        
        emit ReentrancyGuardEntered(msg.sender, block.timestamp);
        
        _;
        
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _reentrancyStatus = _NOT_ENTERED;
        
        emit ReentrancyGuardExited(msg.sender, block.timestamp);
    }
    
    /**
     * @dev Returns true if the contract is currently in a reentrant call
     */
    function _isReentrant() internal view returns (bool) {
        return _reentrancyStatus == _ENTERED;
    }
    
    /**
     * @dev Returns true if the contract is not currently executing a function
     * Implements IReentrancyGuard interface
     */
    function _notEntered() external view returns (bool) {
        return _reentrancyStatus == _NOT_ENTERED;
    }
    
    /**
     * @dev Returns the current reentrancy status
     */
    function _getReentrancyStatus() internal view returns (uint256) {
        return _reentrancyStatus;
    }
    
    /**
     * @dev Emergency function to reset reentrancy status (only in extreme cases)
     * This should only be used by admin roles in emergency situations
     */
    function _emergencyResetReentrancy() internal {
        _reentrancyStatus = _NOT_ENTERED;
    }
    
    /**
     * @dev Function to check if a call would be reentrant
     * This can be used for additional validation
     */
    function _checkReentrancy() internal {
        if (_reentrancyStatus == _ENTERED) {
            emit ReentrancyGuardViolation(msg.sender, block.timestamp);
            revert("ReentrancyGuard: potential reentrant call detected");
        }
    }
} 