// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

interface ISecurityManager {
    function setSecurityBlacklistStatus(address account, bool value) external;
    function setBotStatus(address account, bool status) external;
    function setTransferLimit(address account, uint256 limit) external;
    function setDailyTransferLimit(address account, uint256 limit) external;
    function setExemptFromLimits(address account, bool exempt) external;
    function lockTokens(address account, uint256 amount, uint256 unlockTimestamp) external;
    function unlockTokens(address account) external;
    function lockWallet(address wallet, bool lock_) external;
    function checkTransferRestrictions(address from, address to, uint256 amount, uint256 balance) external view returns (bool);
    function updateTransferStats(address from, uint256 amount) external;
    function resetDailyUsage(address account) external;
    function getTransferStats(address account) external view returns (uint256, uint256, uint256, uint256, uint256, bool);
    function getSecurityInfo(address account) external view returns (bool, bool, bool, uint256, uint256);
    function isSecurityBlacklisted(address account) external view returns (bool);
} 