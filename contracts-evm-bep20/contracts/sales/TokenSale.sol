// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

/**
 * @title TokenSale
 * @dev USDTg token satışı için smart contract
 * Whitelist, vesting ve kademeli satış sistemi
 */
contract TokenSale is AccessControl, ReentrancyGuard, Pausable {
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant WHITELIST_MANAGER_ROLE = keccak256("WHITELIST_MANAGER_ROLE");
    
    IERC20 public token;
    
    // Sale parameters
    uint256 public constant SALE_AMOUNT = 20_000_000 * 10**18; // 20M tokens
    uint256 public constant TOKEN_PRICE = 0.01 * 10**18; // 0.01 USD per token
    uint256 public constant MIN_PURCHASE = 100 * 10**18; // 100 USD minimum
    uint256 public constant MAX_PURCHASE = 10_000 * 10**18; // 10,000 USD maximum
    
    uint256 public saleStartTime;
    uint256 public saleEndTime;
    uint256 public constant SALE_DURATION = 30 days;
    
    // Vesting parameters
    uint256 public constant VESTING_CLIFF = 6 * 30 days; // 6 months cliff
    uint256 public constant VESTING_DURATION = 12 * 30 days; // 12 months linear
    
    // Sale state
    uint256 public totalSold;
    uint256 public totalRaised;
    mapping(address => uint256) public userPurchases;
    mapping(address => bool) public whitelist;
    mapping(address => VestingInfo) public vestingInfo;
    
    // Whitelist
    uint256 public whitelistCount;
    uint256 public constant MAX_WHITELIST = 10_000;
    
    struct VestingInfo {
        uint256 totalAmount;
        uint256 claimedAmount;
        uint256 startTime;
        bool isActive;
    }
    
    // Events
    event TokensPurchased(address indexed buyer, uint256 amount, uint256 cost);
    event TokensClaimed(address indexed buyer, uint256 amount);
    event WhitelistAdded(address indexed user);
    event WhitelistRemoved(address indexed user);
    event SaleStarted(uint256 startTime, uint256 endTime);
    event SaleEnded(uint256 totalSold, uint256 totalRaised);
    
    modifier onlyAdmin() {
        require(hasRole(ADMIN_ROLE, msg.sender), "Only admin");
        _;
    }
    
    modifier onlyWhitelistManager() {
        require(hasRole(WHITELIST_MANAGER_ROLE, msg.sender), "Only whitelist manager");
        _;
    }
    
    modifier saleActive() {
        require(block.timestamp >= saleStartTime, "Sale not started");
        require(block.timestamp <= saleEndTime, "Sale ended");
        require(!paused(), "Sale is paused");
        _;
    }
    
    modifier whitelisted() {
        require(whitelist[msg.sender], "Not whitelisted");
        _;
    }
    
    constructor(address _token) {
        require(_token != address(0), "Invalid token address");
        
        token = IERC20(_token);
        
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);
        _grantRole(WHITELIST_MANAGER_ROLE, msg.sender);
    }
    
    /**
     * @dev Satışı başlat
     */
    function startSale() external onlyAdmin {
        require(saleStartTime == 0, "Sale already started");
        
        saleStartTime = block.timestamp;
        saleEndTime = block.timestamp + SALE_DURATION;
        
        emit SaleStarted(saleStartTime, saleEndTime);
    }
    
    /**
     * @dev Token satın al
     */
    function purchaseTokens() external payable saleActive whitelisted nonReentrant {
        require(msg.value >= MIN_PURCHASE, "Below minimum purchase");
        require(msg.value <= MAX_PURCHASE, "Above maximum purchase");
        require(userPurchases[msg.sender] + msg.value <= MAX_PURCHASE, "Exceeds personal limit");
        
        uint256 tokenAmount = (msg.value * 10**18) / TOKEN_PRICE;
        require(totalSold + tokenAmount <= SALE_AMOUNT, "Exceeds sale amount");
        
        // Update state
        totalSold += tokenAmount;
        totalRaised += msg.value;
        userPurchases[msg.sender] += msg.value;
        
        // Setup vesting
        vestingInfo[msg.sender] = VestingInfo({
            totalAmount: tokenAmount,
            claimedAmount: 0,
            startTime: saleEndTime + VESTING_CLIFF,
            isActive: true
        });
        
        emit TokensPurchased(msg.sender, tokenAmount, msg.value);
    }
    
    /**
     * @dev Vesting token'ları claim et
     */
    function claimTokens() external nonReentrant {
        VestingInfo storage info = vestingInfo[msg.sender];
        require(info.isActive, "No vesting info");
        require(block.timestamp >= info.startTime, "Vesting not started");
        
        uint256 claimableAmount = getClaimableAmount(msg.sender);
        require(claimableAmount > 0, "No tokens to claim");
        
        info.claimedAmount += claimableAmount;
        
        require(token.transfer(msg.sender, claimableAmount), "Transfer failed");
        
        emit TokensClaimed(msg.sender, claimableAmount);
    }
    
    /**
     * @dev Claim edilebilir miktarı hesapla
     */
    function getClaimableAmount(address user) public view returns (uint256) {
        VestingInfo storage info = vestingInfo[user];
        
        if (!info.isActive || block.timestamp < info.startTime) {
            return 0;
        }
        
        uint256 timePassed = block.timestamp - info.startTime;
        
        if (timePassed >= VESTING_DURATION) {
            return info.totalAmount - info.claimedAmount;
        }
        
        uint256 vestedAmount = (info.totalAmount * timePassed) / VESTING_DURATION;
        return vestedAmount - info.claimedAmount;
    }
    
    /**
     * @dev Whitelist'e kullanıcı ekle
     */
    function addToWhitelist(address user) external onlyWhitelistManager {
        require(user != address(0), "Invalid address");
        require(!whitelist[user], "Already whitelisted");
        require(whitelistCount < MAX_WHITELIST, "Whitelist full");
        
        whitelist[user] = true;
        whitelistCount++;
        
        emit WhitelistAdded(user);
    }
    
    /**
     * @dev Whitelist'ten kullanıcı çıkar
     */
    function removeFromWhitelist(address user) external onlyWhitelistManager {
        require(whitelist[user], "Not whitelisted");
        
        whitelist[user] = false;
        whitelistCount--;
        
        emit WhitelistRemoved(user);
    }
    
    /**
     * @dev Toplu whitelist ekleme
     */
    function addBatchToWhitelist(address[] calldata users) external onlyWhitelistManager {
        require(whitelistCount + users.length <= MAX_WHITELIST, "Whitelist would be full");
        
        for (uint256 i = 0; i < users.length; i++) {
            if (!whitelist[users[i]] && users[i] != address(0)) {
                whitelist[users[i]] = true;
                whitelistCount++;
                emit WhitelistAdded(users[i]);
            }
        }
    }
    
    /**
     * @dev Satış bilgilerini getir
     */
    function getSaleInfo() external view returns (
        uint256 totalSold_,
        uint256 totalRaised_,
        uint256 remainingTokens_,
        uint256 saleProgress_,
        uint256 timeRemaining_
    ) {
        uint256 remainingTokens = SALE_AMOUNT - totalSold;
        uint256 saleProgress = (totalSold * 100) / SALE_AMOUNT;
        uint256 timeRemaining = 0;
        
        if (block.timestamp < saleEndTime) {
            timeRemaining = saleEndTime - block.timestamp;
        }
        
        return (
            totalSold,
            totalRaised,
            remainingTokens,
            saleProgress,
            timeRemaining
        );
    }
    
    /**
     * @dev Kullanıcı vesting bilgilerini getir
     */
    function getUserVestingInfo(address user) external view returns (
        uint256 totalAmount,
        uint256 claimedAmount,
        uint256 claimableAmount,
        uint256 startTime,
        bool isActive
    ) {
        VestingInfo storage info = vestingInfo[user];
        uint256 claimable = getClaimableAmount(user);
        
        return (
            info.totalAmount,
            info.claimedAmount,
            claimable,
            info.startTime,
            info.isActive
        );
    }
    
    /**
     * @dev Satışı sonlandır
     */
    function endSale() external onlyAdmin {
        require(block.timestamp > saleEndTime, "Sale not ended yet");
        
        emit SaleEnded(totalSold, totalRaised);
    }
    
    /**
     * @dev ETH çekme (sadece admin)
     */
    function withdrawETH() external onlyAdmin {
        uint256 balance = address(this).balance;
        require(balance > 0, "No ETH to withdraw");
        
        payable(msg.sender).transfer(balance);
    }
    
    /**
     * @dev Token çekme (sadece admin)
     */
    function withdrawTokens() external onlyAdmin {
        uint256 balance = token.balanceOf(address(this));
        require(balance > 0, "No tokens to withdraw");
        
        token.transfer(msg.sender, balance);
    }
    
    /**
     * @dev Sale'ı pause/unpause
     */
    function setPaused(bool _paused) external onlyAdmin {
        if (_paused) {
            _pause();
        } else {
            _unpause();
        }
    }
    
    /**
     * @dev Sale parametrelerini güncelle
     */
    function updateSaleParameters(
        uint256 _minPurchase,
        uint256 _maxPurchase
    ) external onlyAdmin {
        require(_minPurchase > 0, "Invalid min purchase");
        require(_maxPurchase > _minPurchase, "Invalid max purchase");
        
        // Update parameters (would need to add state variables)
    }
    
    // Receive function
    receive() external payable {}
} 