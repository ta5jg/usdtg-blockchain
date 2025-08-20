// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

interface IVestingManager {
    function createVestingWallet(address beneficiary, uint256 unlockTime) external;
    function getVestingWallet(address user) external view returns (uint256, uint256, uint256, uint256);
    function transferToVesting(address beneficiary, uint256 amount) external;
} 