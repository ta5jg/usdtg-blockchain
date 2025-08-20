// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/finance/VestingWallet.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract VestingManager is AccessControl {
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    
    mapping(address => address) public vestingContracts;
    address public tokenContract;

    event VestingCreated(address indexed beneficiary, address vestingContract);

    constructor(address _tokenContract) {
        tokenContract = _tokenContract;
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);
    }

    modifier onlyTokenContract() {
        require(msg.sender == tokenContract, "Only token contract");
        _;
    }

    function createVestingWallet(address beneficiary, uint256 unlockTime) external onlyRole(ADMIN_ROLE) {
        require(beneficiary != address(0), "Invalid address");
        VestingWallet wallet = new VestingWallet(beneficiary, uint64(block.timestamp), uint64(unlockTime));
        vestingContracts[beneficiary] = address(wallet);
        emit VestingCreated(beneficiary, address(wallet));
    }

    function getVestingWallet(address user) external view returns (uint256, uint256, uint256, uint256) {
        address walletAddr = vestingContracts[user];
        require(walletAddr != address(0), "No vesting contract");
        VestingWallet wallet = VestingWallet(payable(walletAddr));
        return (wallet.released(address(this)), address(wallet).balance, wallet.start(), wallet.duration());
    }

    function transferToVesting(address beneficiary, uint256 amount) external onlyTokenContract {
        address walletAddr = vestingContracts[beneficiary];
        require(walletAddr != address(0), "No vesting contract");
        require(IERC20(tokenContract).transfer(walletAddr, amount), "Transfer to vesting failed");
    }
}