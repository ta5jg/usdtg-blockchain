// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

/**
 * @title LiquidityMining
 * @dev USDTg liquidity mining sistemi
 * LP token sağlayanlara ödül dağıtımı
 */
contract LiquidityMining is AccessControl, ReentrancyGuard, Pausable {
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant REWARD_MANAGER_ROLE = keccak256("REWARD_MANAGER_ROLE");
    
    IERC20 public rewardToken; // USDTg
    IERC20 public lpToken; // LP token (USDTg/ETH)
    
    // Mining parameters
    uint256 public constant TOTAL_REWARDS = 15_000_000 * 10**18; // 15M tokens
    uint256 public constant DAILY_REWARDS = 100_000 * 10**18; // 100K tokens per day
    uint256 public constant MINING_DURATION = 150 days; // 150 days
    
    uint256 public miningStartTime;
    uint256 public miningEndTime;
    uint256 public lastRewardTime;
    uint256 public totalRewardsDistributed;
    
    // Staking info
    mapping(address => uint256) public userStakes;
    mapping(address => uint256) public userRewardDebt;
    uint256 public totalStaked;
    uint256 public rewardPerToken;
    
    // Lock period
    uint256 public constant LOCK_PERIOD = 30 days; // 30 days lock
    mapping(address => uint256) public userLockTime;
    
    // Events
    event Staked(address indexed user, uint256 amount, uint256 lockTime);
    event Unstaked(address indexed user, uint256 amount);
    event RewardsClaimed(address indexed user, uint256 amount);
    event MiningStarted(uint256 startTime, uint256 endTime);
    event MiningEnded(uint256 totalRewardsDistributed);
    
    modifier onlyAdmin() {
        require(hasRole(ADMIN_ROLE, msg.sender), "Only admin");
        _;
    }
    
    modifier onlyRewardManager() {
        require(hasRole(REWARD_MANAGER_ROLE, msg.sender), "Only reward manager");
        _;
    }
    
    modifier miningActive() {
        require(block.timestamp >= miningStartTime, "Mining not started");
        require(block.timestamp <= miningEndTime, "Mining ended");
        require(!paused(), "Mining is paused");
        _;
    }
    
    modifier lockPeriodPassed() {
        require(block.timestamp >= userLockTime[msg.sender] + LOCK_PERIOD, "Lock period not passed");
        _;
    }
    
    constructor(address _rewardToken, address _lpToken) {
        require(_rewardToken != address(0), "Invalid reward token");
        require(_lpToken != address(0), "Invalid LP token");
        
        rewardToken = IERC20(_rewardToken);
        lpToken = IERC20(_lpToken);
        
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);
        _grantRole(REWARD_MANAGER_ROLE, msg.sender);
    }
    
    /**
     * @dev Mining'i başlat
     */
    function startMining() external onlyAdmin {
        require(miningStartTime == 0, "Mining already started");
        
        miningStartTime = block.timestamp;
        miningEndTime = block.timestamp + MINING_DURATION;
        lastRewardTime = block.timestamp;
        
        emit MiningStarted(miningStartTime, miningEndTime);
    }
    
    /**
     * @dev LP token stake et
     */
    function stake(uint256 amount) external miningActive nonReentrant {
        require(amount > 0, "Amount must be positive");
        require(lpToken.transferFrom(msg.sender, address(this), amount), "Transfer failed");
        
        // Update rewards
        _updateRewards();
        
        // Update user stake
        userStakes[msg.sender] += amount;
        totalStaked += amount;
        userLockTime[msg.sender] = block.timestamp;
        
        emit Staked(msg.sender, amount, block.timestamp);
    }
    
    /**
     * @dev LP token unstake et
     */
    function unstake(uint256 amount) external lockPeriodPassed nonReentrant {
        require(amount > 0, "Amount must be positive");
        require(userStakes[msg.sender] >= amount, "Insufficient stake");
        
        // Update rewards
        _updateRewards();
        
        // Update user stake
        userStakes[msg.sender] -= amount;
        totalStaked -= amount;
        
        require(lpToken.transfer(msg.sender, amount), "Transfer failed");
        
        emit Unstaked(msg.sender, amount);
    }
    
    /**
     * @dev Ödülleri claim et
     */
    function claimRewards() external nonReentrant {
        uint256 pendingRewards = getPendingRewards(msg.sender);
        require(pendingRewards > 0, "No rewards to claim");
        
        // Update rewards
        _updateRewards();
        
        // Reset user reward debt
        userRewardDebt[msg.sender] = (userStakes[msg.sender] * rewardPerToken) / 1e18;
        
        totalRewardsDistributed += pendingRewards;
        
        require(rewardToken.transfer(msg.sender, pendingRewards), "Transfer failed");
        
        emit RewardsClaimed(msg.sender, pendingRewards);
    }
    
    /**
     * @dev Stake ve claim'i birleştir
     */
    function stakeAndClaim(uint256 amount) external miningActive nonReentrant {
        require(amount > 0, "Amount must be positive");
        require(lpToken.transferFrom(msg.sender, address(this), amount), "Transfer failed");
        
        // Update rewards
        _updateRewards();
        
        // Claim existing rewards
        uint256 pendingRewards = getPendingRewards(msg.sender);
        if (pendingRewards > 0) {
            userRewardDebt[msg.sender] = (userStakes[msg.sender] * rewardPerToken) / 1e18;
            totalRewardsDistributed += pendingRewards;
            require(rewardToken.transfer(msg.sender, pendingRewards), "Transfer failed");
            emit RewardsClaimed(msg.sender, pendingRewards);
        }
        
        // Update user stake
        userStakes[msg.sender] += amount;
        totalStaked += amount;
        userLockTime[msg.sender] = block.timestamp;
        
        emit Staked(msg.sender, amount, block.timestamp);
    }
    
    /**
     * @dev Bekleyen ödülleri hesapla
     */
    function getPendingRewards(address user) public view returns (uint256) {
        if (userStakes[user] == 0) {
            return 0;
        }
        
        uint256 currentRewardPerToken = rewardPerToken;
        
        if (totalStaked > 0 && block.timestamp >= miningStartTime && block.timestamp <= miningEndTime) {
            uint256 timePassed = block.timestamp - lastRewardTime;
            uint256 rewards = (timePassed * DAILY_REWARDS) / 1 days;
            currentRewardPerToken += (rewards * 1e18) / totalStaked;
        }
        
        uint256 userReward = (userStakes[user] * currentRewardPerToken) / 1e18;
        return userReward - userRewardDebt[user];
    }
    
    /**
     * @dev Mining bilgilerini getir
     */
    function getMiningInfo() external view returns (
        uint256 totalStaked_,
        uint256 totalRewardsDistributed_,
        uint256 remainingRewards_,
        uint256 miningProgress_,
        uint256 timeRemaining_,
        uint256 dailyRewards_
    ) {
        uint256 remainingRewards = TOTAL_REWARDS - totalRewardsDistributed;
        uint256 miningProgress = (totalRewardsDistributed * 100) / TOTAL_REWARDS;
        uint256 timeRemaining = 0;
        
        if (block.timestamp < miningEndTime) {
            timeRemaining = miningEndTime - block.timestamp;
        }
        
        return (
            totalStaked,
            totalRewardsDistributed,
            remainingRewards,
            miningProgress,
            timeRemaining,
            DAILY_REWARDS
        );
    }
    
    /**
     * @dev Kullanıcı bilgilerini getir
     */
    function getUserInfo(address user) external view returns (
        uint256 stakedAmount,
        uint256 pendingRewards,
        uint256 lockTime,
        uint256 unlockTime,
        bool canUnstake
    ) {
        uint256 lockEndTime = userLockTime[user] + LOCK_PERIOD;
        bool canUnstake_ = block.timestamp >= lockEndTime;
        
        return (
            userStakes[user],
            getPendingRewards(user),
            userLockTime[user],
            lockEndTime,
            canUnstake_
        );
    }
    
    /**
     * @dev Mining'i sonlandır
     */
    function endMining() external onlyAdmin {
        require(block.timestamp > miningEndTime, "Mining not ended yet");
        
        emit MiningEnded(totalRewardsDistributed);
    }
    
    /**
     * @dev Ödül token'larını çek (sadece admin)
     */
    function withdrawRewardTokens() external onlyAdmin {
        uint256 balance = rewardToken.balanceOf(address(this));
        require(balance > 0, "No reward tokens to withdraw");
        
        rewardToken.transfer(msg.sender, balance);
    }
    
    /**
     * @dev LP token'ları çek (sadece admin)
     */
    function withdrawLPTokens() external onlyAdmin {
        uint256 balance = lpToken.balanceOf(address(this));
        require(balance > 0, "No LP tokens to withdraw");
        
        lpToken.transfer(msg.sender, balance);
    }
    
    /**
     * @dev Mining'i pause/unpause
     */
    function setPaused(bool _paused) external onlyAdmin {
        if (_paused) {
            _pause();
        } else {
            _unpause();
        }
    }
    
    /**
     * @dev Günlük ödül miktarını güncelle
     */
    function updateDailyRewards(uint256 newDailyRewards) external onlyRewardManager {
        require(newDailyRewards > 0, "Invalid daily rewards");
        require(newDailyRewards <= TOTAL_REWARDS, "Exceeds total rewards");
        
        // Update daily rewards (would need to add state variable)
    }
    
    /**
     * @dev Ödülleri güncelle
     */
    function _updateRewards() internal {
        if (totalStaked == 0) {
            lastRewardTime = block.timestamp;
            return;
        }
        
        if (block.timestamp > lastRewardTime && block.timestamp <= miningEndTime) {
            uint256 timePassed = block.timestamp - lastRewardTime;
            uint256 rewards = (timePassed * DAILY_REWARDS) / 1 days;
            
            if (rewards > 0) {
                rewardPerToken += (rewards * 1e18) / totalStaked;
                lastRewardTime = block.timestamp;
            }
        }
    }
    
    // Emergency functions
    function emergencyWithdraw() external onlyAdmin {
        // Emergency withdrawal logic
    }
    
    function emergencyPause() external onlyAdmin {
        _pause();
    }
} 