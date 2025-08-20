// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

/**
 * @title IPriceOracle
 * @dev Interface for price oracle integration
 */
interface IPriceOracle {
    /**
     * @dev Get the current price of a token in USD (8 decimals)
     * @param token The token address
     * @return price The current price in USD
     * @return timestamp The timestamp of the price
     */
    function getPrice(address token) external view returns (uint256 price, uint256 timestamp);
    
    /**
     * @dev Get the price of a token pair
     * @param base The base token address
     * @param quote The quote token address
     * @return price The current price
     * @return timestamp The timestamp of the price
     */
    function getPricePair(address base, address quote) external view returns (uint256 price, uint256 timestamp);
    
    /**
     * @dev Check if price is stale
     * @param token The token address
     * @return True if price is stale
     */
    function isPriceStale(address token) external view returns (bool);
} 