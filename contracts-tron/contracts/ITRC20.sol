
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
interface ITRC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address a) external view returns (uint256);
    function transfer(address to, uint256 v) external returns (bool);
    function transferFrom(address f, address t, uint256 v) external returns (bool);
    function approve(address s, uint256 v) external returns (bool);
    function decimals() external view returns (uint8);
}
