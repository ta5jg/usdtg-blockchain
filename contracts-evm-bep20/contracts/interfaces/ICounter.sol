// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

interface ICounter {
    /**
     * @dev Returns the current value of the counter.
     */
    function current() external view returns (uint256);
    
    /**
     * @dev Increments the counter by 1 and returns the new value.
     */
    function increment() external returns (uint256);
    
    /**
     * @dev Decrements the counter by 1 and returns the new value.
     * Reverts if the counter would become negative.
     */
    function decrement() external returns (uint256);
    
    /**
     * @dev Resets the counter to 0.
     */
    function reset() external;
    
    /**
     * @dev Sets the counter to a specific value.
     */
    function set(uint256 value) external;
    
    /**
     * @dev Adds a specific value to the counter.
     */
    function add(uint256 value) external returns (uint256);
    
    /**
     * @dev Subtracts a specific value from the counter.
     * Reverts if the result would be negative.
     */
    function subtract(uint256 value) external returns (uint256);
} 