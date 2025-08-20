// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract ERC20Core is ERC20, AccessControl, Ownable {
    // Core blacklist functionality
    mapping(address => bool) public coreBlacklisted;
    mapping(address => uint256) private coreLastTransferTimestamp;

    uint256 public constant coreMinDelay = 60;

    // Define events to log when blacklist status is set
    event CoreBlacklisted(address indexed account, bool status);

    constructor(string memory name, string memory symbol, uint256 initialSupply) 
        ERC20(name, symbol) 
    {
        _mint(msg.sender, initialSupply);
    }

    // Virtual _beforeTokenTransfer function that can be overridden in derived contracts
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);
    }

    // Virtual _afterTokenTransfer function that can be overridden in derived contracts
    function _afterTokenTransfer(address from, address to, uint256 amount) internal virtual override {
        super._afterTokenTransfer(from, to, amount);
    }

    // Function to check basic restrictions on transfers
    function _checkCoreTransferRestrictions(address from, address to, uint256 amount, uint256 balance) internal view {
        require(!coreBlacklisted[from] && !coreBlacklisted[to], "Core blacklisted");
        require(balance - amount >= 0, "Insufficient balance");
        require(block.timestamp - coreLastTransferTimestamp[from] >= coreMinDelay, "Core cooldown");
    }

    // Function to update the timestamp of the last transfer
    function _updateCoreLastTransfer(address from) internal {
        coreLastTransferTimestamp[from] = block.timestamp;
    }
    
    function setCoreBlacklistStatus(address account, bool status) public onlyOwner {
        coreBlacklisted[account] = status;
        emit CoreBlacklisted(account, status);
    }
}