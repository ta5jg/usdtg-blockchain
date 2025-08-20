// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

interface IBatchManager {
    function batchMint(address[] calldata recipients, uint256[] calldata amounts) external;
    function batchTransfer(address sender, address[] calldata recipients, uint256[] calldata amounts) external;
}

contract BatchManager is IBatchManager {
    address public token;
    address public minter;
    address public admin;

    event BatchMint(address[] recipients, uint256[] amounts);
    event BatchTransfer(address indexed sender, address[] recipients, uint256[] amounts);

    modifier onlyMinter() {
        require(msg.sender == minter, "Only minter");
        _;
    }

    constructor(address _token, address _minter, address _admin) {
        require(_minter != address(0), "Invalid minter");
        require(_admin != address(0), "Invalid admin");
        token = _token;
        minter = _minter;
        admin = _admin;
    }

    function batchMint(address[] calldata recipients, uint256[] calldata amounts) external override onlyMinter {
        require(recipients.length == amounts.length, "Length mismatch");
        require(recipients.length <= 100, "Too many recipients");
        uint256 totalAmount = 0;
        for (uint256 i = 0; i < amounts.length; i++) {
            totalAmount += amounts[i];
        }
        for (uint256 i = 0; i < recipients.length; i++) {
            require(recipients[i] != address(0), "Invalid recipient");
            require(amounts[i] > 0, "Invalid amount");
            IERC20Mint(token).mint(recipients[i], amounts[i]);
        }
        emit BatchMint(recipients, amounts);
    }

    function batchTransfer(address sender, address[] calldata recipients, uint256[] calldata amounts) external override onlyMinter {
        require(recipients.length == amounts.length, "Length mismatch");
        require(recipients.length <= 50, "Too many recipients");
        uint256 totalAmount = 0;
        for (uint256 i = 0; i < amounts.length; i++) {
            totalAmount += amounts[i];
        }
        require(IERC20(token).balanceOf(sender) >= totalAmount, "Insufficient balance");
        for (uint256 i = 0; i < recipients.length; i++) {
            require(recipients[i] != address(0), "Invalid recipient");
            require(amounts[i] > 0, "Invalid amount");
            IERC20(token).transferFrom(sender, recipients[i], amounts[i]);
        }
        emit BatchTransfer(sender, recipients, amounts);
    }
}

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IERC20Mint {
    function mint(address to, uint256 amount) external;
} 