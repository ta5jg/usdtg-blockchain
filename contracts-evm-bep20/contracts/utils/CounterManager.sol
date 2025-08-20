// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/utils/Counters.sol";
import "../interfaces/ICounter.sol";

contract CounterManager is ICounter {
    using Counters for Counters.Counter;
    
    Counters.Counter private _counter;
    
    /**
     * @dev Returns the current value of the counter.
     */
    function current() external view override returns (uint256) {
        return _counter.current();
    }
    
    /**
     * @dev Increments the counter by 1 and returns the new value.
     */
    function increment() external override returns (uint256) {
        _counter.increment();
        return _counter.current();
    }
    
    /**
     * @dev Decrements the counter by 1 and returns the new value.
     * Reverts if the counter would become negative.
     */
    function decrement() external override returns (uint256) {
        _counter.decrement();
        return _counter.current();
    }
    
    /**
     * @dev Resets the counter to 0.
     */
    function reset() external override {
        // Reset to 0 by decrementing until we reach 0
        while (_counter.current() > 0) {
            _counter.decrement();
        }
    }
    
    /**
     * @dev Sets the counter to a specific value.
     */
    function set(uint256 value) external override {
        // Reset to 0 by decrementing until we reach 0
        while (_counter.current() > 0) {
            _counter.decrement();
        }
        // Then increment to the desired value
        for (uint256 i = 0; i < value; i++) {
            _counter.increment();
        }
    }
    
    /**
     * @dev Adds a specific value to the counter.
     */
    function add(uint256 value) external override returns (uint256) {
        for (uint256 i = 0; i < value; i++) {
            _counter.increment();
        }
        return _counter.current();
    }
    
    /**
     * @dev Subtracts a specific value from the counter.
     * Reverts if the result would be negative.
     */
    function subtract(uint256 value) external override returns (uint256) {
        require(_counter.current() >= value, "Counter: subtraction would result in negative value");
        for (uint256 i = 0; i < value; i++) {
            _counter.decrement();
        }
        return _counter.current();
    }
    
    /**
     * @dev Internal function to get the counter value.
     * This can be used by contracts that inherit from this manager.
     */
    function _getCounter() internal view returns (Counters.Counter storage) {
        return _counter;
    }
    
    /**
     * @dev Internal function to increment the counter.
     * This can be used by contracts that inherit from this manager.
     */
    function _increment() internal returns (uint256) {
        _counter.increment();
        return _counter.current();
    }
    
    /**
     * @dev Internal function to decrement the counter.
     * This can be used by contracts that inherit from this manager.
     */
    function _decrement() internal returns (uint256) {
        _counter.decrement();
        return _counter.current();
    }
} 