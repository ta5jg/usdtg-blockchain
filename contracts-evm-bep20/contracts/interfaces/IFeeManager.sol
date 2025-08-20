// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

interface IFeeManager {
    function setFee(uint256 _feePercent) external;
    function setFeeRecipient(address _feeRecipient) external;
    function setFeeExemption(address account, bool exempt) external;
    function calculateFee(address from, address to, uint256 amount) external view returns (uint256 fee, uint256 net);
    function collectFee(address from, address to, uint256 amount) external returns (uint256 fee, uint256 net);
    function getFeeInfo() external view returns (uint256 currentFee, address recipient, bool hasFee);
    function isExempt(address account) external view returns (bool);
    function feeRecipient() external view returns (address);
} 