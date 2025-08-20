// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

/**
 * @title USDTg Token
 * @dev Simplified USDTg token contract for USDTg Blockchain
 */
contract USDTgToken is ERC20, Ownable, Pausable {
    
    // Token economics
    uint256 public constant MAX_SUPPLY = 100_000_000 * 10**18; // 100 million tokens
    uint256 public constant INITIAL_SUPPLY = 50_000_000 * 10**18; // 50M initial supply
    
    // Events
    event TokensMinted(address indexed to, uint256 amount);
    event TokensBurned(address indexed from, uint256 amount);
    
    constructor() ERC20("TetherGround USD Token", "USDTg") Ownable(msg.sender) {
        _mint(msg.sender, INITIAL_SUPPLY);
    }
    
    /**
     * @dev Mint new tokens (only owner)
     */
    function mint(address to, uint256 amount) public onlyOwner {
        require(totalSupply() + amount <= MAX_SUPPLY, "Exceeds max supply");
        _mint(to, amount);
        emit TokensMinted(to, amount);
    }
    
    /**
     * @dev Burn tokens
     */
    function burn(uint256 amount) public {
        _burn(msg.sender, amount);
        emit TokensBurned(msg.sender, amount);
    }
    
    /**
     * @dev Pause token transfers (only owner)
     */
    function pause() public onlyOwner {
        _pause();
    }
    
    /**
     * @dev Unpause token transfers (only owner)
     */
    function unpause() public onlyOwner {
        _unpause();
    }
    
    /**
     * @dev Override transfer function to check pause state
     */
    function transfer(address to, uint256 amount) public override whenNotPaused returns (bool) {
        return super.transfer(to, amount);
    }
    
    /**
     * @dev Override transferFrom function to check pause state
     */
    function transferFrom(address from, address to, uint256 amount) public override whenNotPaused returns (bool) {
        return super.transferFrom(from, to, amount);
    }
    
    /**
     * @dev Get token info
     */
    function getTokenInfo() public view returns (
        string memory name,
        string memory symbol,
        uint256 totalSupply,
        uint256 maxSupply,
        uint256 decimals
    ) {
        return (
            name(),
            symbol(),
            totalSupply(),
            MAX_SUPPLY,
            decimals()
        );
    }
}
