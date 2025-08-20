// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/**
 * @title LiquidityLocker
 * @dev Kademeli likidite kilitleme sistemi
 * 24 ay kilit + kademeli serbest bırakma
 */
contract LiquidityLocker is AccessControl, ReentrancyGuard {
    bytes32 public constant GOVERNANCE_ROLE = keccak256("GOVERNANCE_ROLE");
    bytes32 public constant EMERGENCY_ROLE = keccak256("EMERGENCY_ROLE");
    
    IERC20 public token;
    address public lpToken; // LP token address
    
    uint256 public totalLocked;
    uint256 public unlockStartTime;
    uint256 public constant LOCK_DURATION = 24 * 30 days; // 24 ay
    
    // Kademeli serbest bırakma planı
    mapping(uint256 => uint256) public unlockSchedule;
    
    // Emergency unlock limit
    uint256 public constant EMERGENCY_UNLOCK_LIMIT = 5; // %5
    
    // Events
    event LiquidityLocked(address indexed lpToken, uint256 amount, uint256 lockTime);
    event LiquidityUnlocked(address indexed lpToken, uint256 amount, uint256 unlockTime);
    event EmergencyUnlock(address indexed lpToken, uint256 amount, uint256 unlockTime);
    event UnlockScheduleUpdated(uint256 period, uint256 percentage);
    
    modifier onlyGovernance() {
        require(hasRole(GOVERNANCE_ROLE, msg.sender), "Only governance");
        _;
    }
    
    modifier onlyEmergency() {
        require(hasRole(EMERGENCY_ROLE, msg.sender), "Only emergency role");
        _;
    }
    
    constructor(address _token, address _lpToken) {
        require(_token != address(0), "Invalid token address");
        require(_lpToken != address(0), "Invalid LP token address");
        
        token = IERC20(_token);
        lpToken = _lpToken;
        unlockStartTime = block.timestamp;
        
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(GOVERNANCE_ROLE, msg.sender);
        _grantRole(EMERGENCY_ROLE, msg.sender);
        
        // Kademeli serbest bırakma planı
        unlockSchedule[6 * 30 days] = 20;   // 6 ay: %20 serbest
        unlockSchedule[12 * 30 days] = 40;  // 12 ay: %40 serbest
        unlockSchedule[18 * 30 days] = 60;  // 18 ay: %60 serbest
        unlockSchedule[24 * 30 days] = 80;  // 24 ay: %80 serbest
        
        emit UnlockScheduleUpdated(6 * 30 days, 20);
        emit UnlockScheduleUpdated(12 * 30 days, 40);
        emit UnlockScheduleUpdated(18 * 30 days, 60);
        emit UnlockScheduleUpdated(24 * 30 days, 80);
    }
    
    /**
     * @dev Likidite kilitleme
     */
    function lockLiquidity(uint256 amount) external onlyGovernance {
        require(amount > 0, "Amount must be positive");
        require(token.transferFrom(msg.sender, address(this), amount), "Transfer failed");
        
        totalLocked += amount;
        
        emit LiquidityLocked(lpToken, amount, block.timestamp);
    }
    
    /**
     * @dev Kademeli likidite serbest bırakma
     */
    function unlockLiquidity() external onlyGovernance nonReentrant {
        uint256 timePassed = block.timestamp - unlockStartTime;
        uint256 unlockPercentage = getUnlockPercentage(timePassed);
        
        require(unlockPercentage > 0, "No unlock available yet");
        
        uint256 unlockAmount = (totalLocked * unlockPercentage) / 100;
        uint256 alreadyUnlocked = totalLocked - getCurrentLockedAmount();
        
        uint256 actualUnlockAmount = unlockAmount - alreadyUnlocked;
        
        require(actualUnlockAmount > 0, "No new unlock available");
        
        require(token.transfer(msg.sender, actualUnlockAmount), "Transfer failed");
        
        emit LiquidityUnlocked(lpToken, actualUnlockAmount, block.timestamp);
    }
    
    /**
     * @dev Acil durum serbest bırakma (sadece %5)
     */
    function emergencyUnlock(uint256 amount) external onlyEmergency nonReentrant {
        require(amount > 0, "Amount must be positive");
        require(amount <= (totalLocked * EMERGENCY_UNLOCK_LIMIT) / 100, "Exceeds emergency limit");
        
        uint256 currentLocked = getCurrentLockedAmount();
        require(amount <= currentLocked, "Insufficient locked amount");
        
        require(token.transfer(msg.sender, amount), "Transfer failed");
        
        emit EmergencyUnlock(lpToken, amount, block.timestamp);
    }
    
    /**
     * @dev Mevcut kilit yüzdesini hesapla
     */
    function getUnlockPercentage(uint256 timePassed) public view returns (uint256) {
        if (timePassed < 6 * 30 days) {
            return 0; // İlk 6 ay kilitli
        } else if (timePassed < 12 * 30 days) {
            return 20; // 6-12 ay: %20 serbest
        } else if (timePassed < 18 * 30 days) {
            return 40; // 12-18 ay: %40 serbest
        } else if (timePassed < 24 * 30 days) {
            return 60; // 18-24 ay: %60 serbest
        } else {
            return 80; // 24+ ay: %80 serbest
        }
    }
    
    /**
     * @dev Şu anda kilitli olan miktarı hesapla
     */
    function getCurrentLockedAmount() public view returns (uint256) {
        uint256 timePassed = block.timestamp - unlockStartTime;
        uint256 unlockPercentage = getUnlockPercentage(timePassed);
        
        if (unlockPercentage >= 100) {
            return 0;
        }
        
        return (totalLocked * (100 - unlockPercentage)) / 100;
    }
    
    /**
     * @dev Kilit bilgilerini getir
     */
    function getLockInfo() external view returns (
        uint256 totalLocked_,
        uint256 currentLocked_,
        uint256 unlocked_,
        uint256 unlockPercentage_,
        uint256 timeRemaining_,
        uint256 nextUnlockTime_
    ) {
        uint256 timePassed = block.timestamp - unlockStartTime;
        uint256 unlockPercentage = getUnlockPercentage(timePassed);
        uint256 currentLocked = getCurrentLockedAmount();
        
        uint256 timeRemaining = 0;
        uint256 nextUnlockTime = 0;
        
        if (timePassed < 6 * 30 days) {
            timeRemaining = (6 * 30 days) - timePassed;
            nextUnlockTime = unlockStartTime + (6 * 30 days);
        } else if (timePassed < 12 * 30 days) {
            timeRemaining = (12 * 30 days) - timePassed;
            nextUnlockTime = unlockStartTime + (12 * 30 days);
        } else if (timePassed < 18 * 30 days) {
            timeRemaining = (18 * 30 days) - timePassed;
            nextUnlockTime = unlockStartTime + (18 * 30 days);
        } else if (timePassed < 24 * 30 days) {
            timeRemaining = (24 * 30 days) - timePassed;
            nextUnlockTime = unlockStartTime + (24 * 30 days);
        }
        
        return (
            totalLocked,
            currentLocked,
            totalLocked - currentLocked,
            unlockPercentage,
            timeRemaining,
            nextUnlockTime
        );
    }
    
    /**
     * @dev Kilit programını güncelle (sadece governance)
     */
    function updateUnlockSchedule(uint256 period, uint256 percentage) external onlyGovernance {
        require(period > 0, "Invalid period");
        require(percentage <= 100, "Invalid percentage");
        
        unlockSchedule[period] = percentage;
        emit UnlockScheduleUpdated(period, percentage);
    }
    
    /**
     * @dev Contract'tan token çekme (sadece admin)
     */
    function withdrawTokens(address tokenAddress, uint256 amount) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(tokenAddress != address(token), "Cannot withdraw locked token");
        IERC20(tokenAddress).transfer(msg.sender, amount);
    }
    
    /**
     * @dev Contract'tan ETH çekme (sadece admin)
     */
    function withdrawETH() external onlyRole(DEFAULT_ADMIN_ROLE) {
        payable(msg.sender).transfer(address(this).balance);
    }
    
    // Emergency pause
    bool public paused;
    
    modifier whenNotPaused() {
        require(!paused, "Contract is paused");
        _;
    }
    
    function setPaused(bool _paused) external onlyRole(DEFAULT_ADMIN_ROLE) {
        paused = _paused;
    }
    
    // Receive function
    receive() external payable {}
} 