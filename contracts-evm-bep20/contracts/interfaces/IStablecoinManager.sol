// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

interface IStablecoinManager {
    function buyTokenWithStable(address stableToken, uint256 stableAmount) external;
    function setStableTokenWhitelist(address token, bool allowed) external;
    function setUSDPrice(uint256 newPrice) external;
    function getUsdPricePerToken() external view returns (uint256);
    function isStableTokenWhitelisted(address token) external view returns (bool);
} 