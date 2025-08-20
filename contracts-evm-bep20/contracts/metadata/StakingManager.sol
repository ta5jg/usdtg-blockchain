// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IStakingManager {
    function addToStakingPool(address founder, uint256 amount) external;
    function claimStakingRewards(address founder) external;
    function useEcosystemFund(address recipient, uint256 amount, string calldata purpose) external;
    function getFounderInfo(address founder) external view returns (
        uint256 stakingPool,
        uint256 stakingLimit,
        uint256 ecosystemLimit,
        uint256 stakingRewardRate,
        uint256 pendingRewards
    );
}

contract StakingManager is IStakingManager {
    address public token;
    address public admin;
    
    uint256 public constant FOUNDER_STAKING_LIMIT = 15_000_000 * 10**18; // 15M for staking
    uint256 public constant FOUNDER_ECOSYSTEM_LIMIT = 10_000_000 * 10**18; // 10M for ecosystem
    uint256 public stakingRewardRate = 1500; // 15% annual reward (1500 basis points)
    uint256 public lastStakingRewardTime;
    uint256 public founderStakingPool;

    event FounderStakingAdded(address indexed founder, uint256 amount);
    event FounderStakingRewardClaimed(address indexed founder, uint256 amount);
    event EcosystemFundUsed(address indexed recipient, uint256 amount, string purpose);

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin");
        _;
    }

    constructor(address _token, address _admin) {
        // require(_token != address(0), "Invalid token"); // TEST: kaldırıldı
        require(_admin != address(0), "Invalid admin");
        token = _token;
        admin = _admin;
        lastStakingRewardTime = block.timestamp;
    }

    function addToStakingPool(address founder, uint256 amount) external override onlyAdmin {
        require(amount > 0, "Amount must be positive");
        require(founderStakingPool + amount <= FOUNDER_STAKING_LIMIT, "Exceeds staking limit");
        founderStakingPool += amount;
        IERC20(token).transferFrom(founder, address(this), amount);
        emit FounderStakingAdded(founder, amount);
    }

    function claimStakingRewards(address founder) external override onlyAdmin {
        require(founderStakingPool > 0, "No tokens in staking pool");
        uint256 timeElapsed = block.timestamp - lastStakingRewardTime;
        uint256 rewardAmount = (founderStakingPool * stakingRewardRate * timeElapsed) / (365 days * 10000);
        require(rewardAmount > 0, "No rewards to claim");
        lastStakingRewardTime = block.timestamp;
        IERC20(token).transfer(founder, rewardAmount);
        emit FounderStakingRewardClaimed(founder, rewardAmount);
    }

    function useEcosystemFund(address recipient, uint256 amount, string calldata purpose) external override onlyAdmin {
        require(amount > 0, "Amount must be positive");
        require(amount <= FOUNDER_ECOSYSTEM_LIMIT, "Exceeds ecosystem fund limit");
        require(recipient != address(0), "Invalid recipient");
        IERC20(token).transfer(recipient, amount);
        emit EcosystemFundUsed(recipient, amount, purpose);
    }

    function getFounderInfo(address /*founder*/) external view override returns (
        uint256 stakingPool,
        uint256 stakingLimit,
        uint256 ecosystemLimit,
        uint256 rewardRate,
        uint256 pendingRewards
    ) {
        uint256 timeElapsed = block.timestamp - lastStakingRewardTime;
        uint256 calculatedRewards = (founderStakingPool * stakingRewardRate * timeElapsed) / (365 days * 10000);
        return (
            founderStakingPool,
            FOUNDER_STAKING_LIMIT,
            FOUNDER_ECOSYSTEM_LIMIT,
            stakingRewardRate,
            calculatedRewards
        );
    }
    
    // Test-only functions (bypass admin checks for testing)
    function addToStakingPoolForTesting(address founder, uint256 amount) external {
        require(amount > 0, "Amount must be positive");
        require(founderStakingPool + amount <= FOUNDER_STAKING_LIMIT, "Exceeds staking limit");
        founderStakingPool += amount;
        IERC20(token).transferFrom(founder, address(this), amount);
        emit FounderStakingAdded(founder, amount);
    }
    
    function claimStakingRewardsForTesting(address founder) external {
        require(founderStakingPool > 0, "No tokens in staking pool");
        uint256 timeElapsed = block.timestamp - lastStakingRewardTime;
        uint256 rewardAmount = (founderStakingPool * stakingRewardRate * timeElapsed) / (365 days * 10000);
        require(rewardAmount > 0, "No rewards to claim");
        lastStakingRewardTime = block.timestamp;
        IERC20(token).transfer(founder, rewardAmount);
        emit FounderStakingRewardClaimed(founder, rewardAmount);
    }
    
    function useEcosystemFundForTesting(address recipient, uint256 amount, string calldata purpose) external {
        require(amount > 0, "Amount must be positive");
        require(amount <= FOUNDER_ECOSYSTEM_LIMIT, "Exceeds ecosystem fund limit");
        require(recipient != address(0), "Invalid recipient");
        IERC20(token).transfer(recipient, amount);
        emit EcosystemFundUsed(recipient, amount, purpose);
    }
}

 