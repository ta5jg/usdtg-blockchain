// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../node_modules/@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../node_modules/@openzeppelin/contracts/token/ERC20/extensions/ERC20Capped.sol";
import "../node_modules/@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "../node_modules/@openzeppelin/contracts/security/Pausable.sol";
import "../node_modules/@openzeppelin/contracts/access/Ownable.sol";
import "../node_modules/@openzeppelin/contracts/access/AccessControl.sol";
import "../node_modules/@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";

contract USDTgToken is ERC20, ERC20Capped, ERC20Burnable, Pausable, Ownable, AccessControl, ERC20Permit {

    mapping(address => bool) public blacklisted;
    mapping(address => uint256) private lastTransferTimestamp;
    uint256 public constant minDelay = 60; // Minimum delay between transfers per address in seconds (anti-bot)

    // AccessControl roles
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    // Fee-on-Transfer
    uint256 public feePercent; // e.g., 100 = 1% (basis points: 10000 = 100%)
    address public feeRecipient;

    // Governance Events
    event ProposalCreated(address indexed proposer, uint256 proposalId, string description);
    event Blacklisted(address indexed account, bool value);
    event FeeUpdated(uint256 newFeePercent, address newFeeRecipient);

    constructor() ERC20("Tetherground USD", "USDTg") ERC20Capped(10_000_000_000 * 10 ** decimals()) ERC20Permit("USDTg") {
        _mint(msg.sender, 10_000_000_000 * 10 ** decimals());
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        feeRecipient = msg.sender;
        feePercent = 0; // Default: 0 fee. Owner can set via setFee.
    }

    function pause() public onlyOwner {
        _pause();
        emit Paused(msg.sender);
    }

    function unpause() public onlyOwner {
        _unpause();
        emit Unpaused(msg.sender);
    }

    function blacklist(address account, bool value) public onlyOwner {
        blacklisted[account] = value;
        emit Blacklisted(account, value);
    }

    function setFee(uint256 feePercent_, address feeRecipient_) external onlyOwner {
        require(feePercent_ <= 500, "Fee too high"); // Max 5%
        require(feeRecipient_ != address(0), "Invalid recipient");
        feePercent = feePercent_;
        feeRecipient = feeRecipient_;
        emit FeeUpdated(feePercent_, feeRecipient_);
    }

    // Minter role mint function
    function mint(address to, uint256 amount) external onlyRole(MINTER_ROLE) {
        _mint(to, amount);
    }

    // Rescue function for stuck tokens
    function rescueTokens(address tokenAddress, uint256 amount) external onlyOwner {
        require(tokenAddress != address(this), "Cannot rescue this token");
        require(IERC20(tokenAddress).transfer(owner(), amount), "Transfer failed");
    }

    // Placeholder for governance proposal creation
    function createProposal(string calldata description) external {
        // This is a stub for integration with governance contracts
        emit ProposalCreated(msg.sender, uint256(keccak256(abi.encodePacked(msg.sender, description, block.number))), description);
    }

    function _mint(address account, uint256 amount) internal override(ERC20, ERC20Capped) {
        super._mint(account, amount);
    }

    function _transfer(address from, address to, uint256 amount) internal override {
        require(!blacklisted[from] && !blacklisted[to], "Blacklisted address");
        require(block.timestamp - lastTransferTimestamp[from] >= minDelay, "Transfer too soon, anti-bot protection");
        lastTransferTimestamp[from] = block.timestamp;

        if (feePercent > 0 && from != address(0) && to != address(0) && from != feeRecipient && to != feeRecipient) {
            uint256 fee = (amount * feePercent) / 10000;
            uint256 sendAmount = amount - fee;
            super._transfer(from, feeRecipient, fee);
            super._transfer(from, to, sendAmount);
        } else {
            super._transfer(from, to, amount);
        }
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }
}
