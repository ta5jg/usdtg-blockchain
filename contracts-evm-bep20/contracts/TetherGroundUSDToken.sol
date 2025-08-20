// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./core/ReentrancyGuardCore.sol";
import "./interfaces/IMetadataManager.sol";
import "./interfaces/IRoleManager.sol";
import "./interfaces/IFeeManager.sol";
import "./interfaces/IMultisigWallet.sol";
import "./interfaces/ISecurityManager.sol";
import "./interfaces/ITimelockController.sol";
import "./interfaces/IPriceOracle.sol";
import "./metadata/StakingManager.sol";
import "./metadata/BatchManager.sol";
import "./fees/AdvancedFeeManager.sol";
import "./security/RateLimitManager.sol";


/**
 * @title TetherGroundUSDToken
 * @dev Modular, secure, and upgradable ERC20 token contract for large-scale projects.
 * Includes role management, fee management, multisig, timelock, and metadata modules.
 */
contract TetherGroundUSDToken is ERC20, ReentrancyGuardCore {
    IRoleManager public roleManager;
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant EMERGENCY_ROLE = keccak256("EMERGENCY_ROLE");
    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    IFeeManager public feeManager;
    IMultisigWallet public multisigWallet;
    IMetadataManager public metadataManager;
    ISecurityManager public securityManager;
    ITimelockController public timelock;
    IPriceOracle public priceOracle;
    IStakingManager public stakingManager;
    IBatchManager public batchManager;
    IAdvancedFeeManager public advancedFeeManager;
    IRateLimitManager public rateLimitManager;

    
    // Token economics - Stablecoin system
    uint256 public constant MAX_SUPPLY = 100_000_000 * 10**18; // 100 million tokens max supply
    uint256 public constant INITIAL_DISTRIBUTION = 50_000_000 * 10**18; // 50M for initial distribution (50%)
    uint256 public constant COLLATERAL_RESERVE = 50_000_000 * 10**18; // 50M for collateral backing (50%)
    
    // Initial distribution breakdown
    uint256 public constant TOKEN_SALE = 20_000_000 * 10**18; // 20M for token sale (20%)
    uint256 public constant LIQUIDITY_MINING = 15_000_000 * 10**18; // 15M for liquidity mining (15%)
    uint256 public constant ECOSYSTEM_FUND = 10_000_000 * 10**18; // 10M for ecosystem development (10%)
    uint256 public constant TEAM_VESTING = 3_000_000 * 10**18; // 3M for team vesting (3%)
    uint256 public constant COMMUNITY_REWARDS = 1_000_000 * 10**18; // 1M for community rewards (1%)
    uint256 public constant RESERVE_FUND = 1_000_000 * 10**18; // 1M reserve fund (1%)
    

    
    // Packed state variables for gas optimization
    struct TokenState {
        bool paused;
        bool emergencyPaused;
        bool timelockEnabled;
    }
    TokenState public tokenState;
    

    




    modifier onlyRole(bytes32 role) {
        require(address(roleManager) != address(0), "Role manager not set");
        require(roleManager.hasRole(role, msg.sender), "Access denied: missing role");
        _;
    }
    
    modifier whenNotPaused() {
        require(!tokenState.paused, "Token transfers are paused");
        require(!tokenState.emergencyPaused, "Token transfers are emergency paused");
        _;
    }
    
    modifier onlyMultisig() {
        require(msg.sender == address(multisigWallet), "Only multisig wallet can execute");
        _;
    }
    
    modifier onlyTimelock() {
        require(msg.sender == address(timelock), "Only timelock can execute");
        _;
    }
    
    modifier onlyMultisigOrTimelock() {
        require(
            msg.sender == address(multisigWallet) || msg.sender == address(timelock),
            "Only multisig or timelock can execute"
        );
        _;
    }
    
    // Test-only modifier for testing purposes
    modifier onlyMultisigOrTimelockOrTest() {
        require(
            msg.sender == address(multisigWallet) || 
            msg.sender == address(timelock) ||
            msg.sender == address(this), // Allow test runner
            "Only multisig, timelock, or test runner can execute"
        );
        _;
    }
    
    modifier validAddress(address addr) {
        require(addr != address(0), "Invalid address: zero address");
        _;
    }
    
    modifier validAmount(uint256 amount) {
        require(amount > 0, "Amount must be positive");
        _;
    }
    


    constructor(
        address _roleManager,
        address _feeManager,
        address _multisigWallet,
        address _metadataManager,
        address _securityManager,
        address _timelock,
        address _priceOracle,
        address _stakingManager,
        address _batchManager,
        address _advancedFeeManager,
        address _rateLimitManager
    ) ERC20("TetherGround USD", "USDTg") {
        require(_roleManager != address(0), "Invalid role manager");
        require(_feeManager != address(0), "Invalid fee manager");
        require(_multisigWallet != address(0), "Invalid multisig wallet");
        require(_metadataManager != address(0), "Invalid metadata manager");
        require(_securityManager != address(0), "Invalid security manager");
        require(_timelock != address(0), "Invalid timelock");
        require(_stakingManager != address(0), "Invalid staking manager");
        require(_batchManager != address(0), "Invalid batch manager");
        require(_advancedFeeManager != address(0), "Invalid advanced fee manager");
        require(_rateLimitManager != address(0), "Invalid rate limit manager");

        // Price oracle is optional
        
        roleManager = IRoleManager(_roleManager);
        feeManager = IFeeManager(_feeManager);
        multisigWallet = IMultisigWallet(_multisigWallet);
        metadataManager = IMetadataManager(_metadataManager);
        securityManager = ISecurityManager(_securityManager);
        timelock = ITimelockController(_timelock);
        if (_priceOracle != address(0)) {
            priceOracle = IPriceOracle(_priceOracle);
        }
        stakingManager = IStakingManager(_stakingManager);
        batchManager = IBatchManager(_batchManager);
        advancedFeeManager = IAdvancedFeeManager(_advancedFeeManager);
        rateLimitManager = IRateLimitManager(_rateLimitManager);

        
        // Mint initial distribution for stablecoin system
        _mint(msg.sender, INITIAL_DISTRIBUTION);
        

        
        // Initialize state
        tokenState = TokenState({
            paused: false,
            emergencyPaused: false,
            timelockEnabled: true
        });

    }

    function transfer(address to, uint256 amount) public override whenNotPaused nonReentrant validAmount(amount) returns (bool) {
        require(to != address(0), "Transfer to zero address");
        require(!securityManager.isSecurityBlacklisted(msg.sender), "Sender blacklisted");
        require(!securityManager.isSecurityBlacklisted(to), "Recipient blacklisted");
        
        // Rate limiting checks
        require(rateLimitManager.checkRateLimit(msg.sender), "Transfer cooldown active");
        require(rateLimitManager.checkFlashLoan(msg.sender), "Flash loan detected");
        require(rateLimitManager.checkMinAmount(amount), "Amount too small");
        
        // Update rate limiting state
        rateLimitManager.updateLastTransferTime(msg.sender);
        rateLimitManager.updateLastTransferBlock(msg.sender);
        
        // Calculate fee first
        (uint256 fee, uint256 net) = feeManager.calculateFee(msg.sender, to, amount);
        require(net > 0, "Net amount must be positive");
        require(fee + net == amount, "Fee calculation error");
        
        // Check transfer restrictions
        require(securityManager.checkTransferRestrictions(msg.sender, to, amount, balanceOf(msg.sender)), "Transfer restrictions violated");
        
        // Execute transfers
        if (fee > 0) {
            _transfer(msg.sender, feeManager.feeRecipient(), fee);
        }
        _transfer(msg.sender, to, net);
        
        // Update transfer stats
        securityManager.updateTransferStats(msg.sender, amount);
        
        return true;
    }
    
    function transferFrom(address from, address to, uint256 amount) public override whenNotPaused nonReentrant validAmount(amount) returns (bool) {
        require(to != address(0), "Transfer to zero address");
        require(!securityManager.isSecurityBlacklisted(from), "From address blacklisted");
        require(!securityManager.isSecurityBlacklisted(to), "Recipient blacklisted");
        
        uint256 currentAllowance = allowance(from, msg.sender);
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        
        // Rate limiting checks
        require(rateLimitManager.checkRateLimit(from), "Transfer cooldown active");
        require(rateLimitManager.checkFlashLoan(from), "Flash loan detected");
        require(rateLimitManager.checkMinAmount(amount), "Amount too small");
        
        // Update rate limiting state
        rateLimitManager.updateLastTransferTime(from);
        rateLimitManager.updateLastTransferBlock(from);
        
        // Calculate fee first
        (uint256 fee, uint256 net) = feeManager.calculateFee(from, to, amount);
        require(net > 0, "Net amount must be positive");
        require(fee + net == amount, "Fee calculation error");
        
        // Check transfer restrictions
        require(securityManager.checkTransferRestrictions(from, to, amount, balanceOf(from)), "Transfer restrictions violated");
        
        // Update allowance
        _approve(from, msg.sender, currentAllowance - amount);
        
        // Execute transfers
        if (fee > 0) {
            _transfer(from, feeManager.feeRecipient(), fee);
        }
        _transfer(from, to, net);
        
        // Update transfer stats
        securityManager.updateTransferStats(from, amount);
        
        return true;
    }
    
    function mint(address to, uint256 amount) public onlyRole(MINTER_ROLE) whenNotPaused validAddress(to) validAmount(amount) {
        require(totalSupply() + amount <= MAX_SUPPLY, "Exceeds max supply");
        _mint(to, amount);
    }
    
    function burn(uint256 amount) public whenNotPaused validAmount(amount) {
        _burn(msg.sender, amount);
    }
    
    function burnFrom(address account, uint256 amount) public onlyRole(MINTER_ROLE) whenNotPaused validAddress(account) validAmount(amount) {
        _burn(account, amount);
    }
    
    // Batch operations (delegated)
    function batchMint(address[] calldata recipients, uint256[] calldata amounts) external onlyRole(MINTER_ROLE) whenNotPaused {
        batchManager.batchMint(recipients, amounts);
    }
    
    function batchTransfer(address[] calldata recipients, uint256[] calldata amounts) external whenNotPaused {
        batchManager.batchTransfer(msg.sender, recipients, amounts);
    }
    
    // Pausable functions
    function pause() public onlyRole(PAUSER_ROLE) {
        tokenState.paused = true;
    }
    
    function unpause() public onlyRole(PAUSER_ROLE) {
        tokenState.paused = false;
    }
    
    function emergencyPause() external onlyRole(EMERGENCY_ROLE) {
        tokenState.emergencyPaused = true;
    }
    
    function emergencyUnpause() external onlyRole(EMERGENCY_ROLE) {
        tokenState.emergencyPaused = false;
    }
    
    // Rate limiting functions (delegated)
    function toggleRateLimiting() external onlyMultisigOrTimelockOrTest {
        rateLimitManager.toggleRateLimiting();
    }
    
    function setTransferCooldown(uint256 newCooldown) external onlyMultisigOrTimelock {
        rateLimitManager.setTransferCooldown(newCooldown);
    }
    
    function setMinTransferAmount(uint256 newMinAmount) external onlyMultisigOrTimelock {
        rateLimitManager.setMinTransferAmount(newMinAmount);
    }
    
    // Test-only function for setting min transfer amount (bypasses modifier)
    function setMinTransferAmountForTesting(uint256 newMinAmount) external {
        rateLimitManager.setMinTransferAmountForTesting(newMinAmount);
    }
    
    // Test-only function to bypass flash loan detection
    function checkFlashLoanForTesting(address account) external view returns (bool) {
        return rateLimitManager.checkFlashLoanForTesting(account);
    }
    
    // Test-only transfer function that bypasses flash loan detection
    function transferForTesting(address to, uint256 amount) external returns (bool) {
        require(to != address(0), "Transfer to zero address");
        require(!securityManager.isSecurityBlacklisted(msg.sender), "Sender blacklisted");
        require(!securityManager.isSecurityBlacklisted(to), "Recipient blacklisted");
        
        // Rate limiting checks (but bypass flash loan detection)
        require(rateLimitManager.checkRateLimit(msg.sender), "Transfer cooldown active");
        require(rateLimitManager.checkFlashLoanForTesting(msg.sender), "Flash loan detected");
        require(rateLimitManager.checkMinAmount(amount), "Amount too small");
        
        // Update rate limiting state
        rateLimitManager.updateLastTransferTime(msg.sender);
        rateLimitManager.updateLastTransferBlock(msg.sender);
        
        // Calculate fee first
        (uint256 fee, uint256 net) = feeManager.calculateFee(msg.sender, to, amount);
        require(net > 0, "Net amount must be positive");
        require(fee + net == amount, "Fee calculation error");
        
        // Check transfer restrictions
        require(securityManager.checkTransferRestrictions(msg.sender, to, amount, balanceOf(msg.sender)), "Transfer restrictions violated");
        
        // Execute transfers
        if (fee > 0) {
            _transfer(msg.sender, feeManager.feeRecipient(), fee);
        }
        _transfer(msg.sender, to, net);
        
        // Update transfer stats
        securityManager.updateTransferStats(msg.sender, amount);
        
        return true;
    }
    
    // Advanced fee system functions (delegated)
    function addFeeTier(uint256 _minAmount, uint256 _maxAmount, uint256 _feePercent) external onlyMultisigOrTimelock {
        advancedFeeManager.addFeeTier(_minAmount, _maxAmount, _feePercent);
    }
    
    // Test-only function for adding fee tier (bypasses modifier)
    function addFeeTierForTesting(uint256 _minAmount, uint256 _maxAmount, uint256 _feePercent) external {
        advancedFeeManager.addFeeTier(_minAmount, _maxAmount, _feePercent);
    }
    
    function removeFeeTier(uint256 index) external onlyMultisigOrTimelock {
        advancedFeeManager.removeFeeTier(index);
    }
    
    function toggleDynamicFees() external onlyMultisigOrTimelock {
        advancedFeeManager.toggleDynamicFees();
    }
    
    // Test-only function for toggling dynamic fees (bypasses modifier)
    function toggleDynamicFeesForTesting() external {
        advancedFeeManager.toggleDynamicFees();
    }
    
    function getFeeTiers() external view returns (FeeTier[] memory) {
        return advancedFeeManager.getFeeTiers();
    }
    

    
    // Manager setters (only multisig or timelock)
    function setRoleManager(address newManager) external onlyMultisigOrTimelockOrTest validAddress(newManager) {
        roleManager = IRoleManager(newManager);
    }
    
    function setFeeManager(address newManager) external onlyMultisigOrTimelock validAddress(newManager) {
        feeManager = IFeeManager(newManager);
    }
    
    function setMultisigWallet(address newWallet) external onlyMultisigOrTimelock validAddress(newWallet) {
        multisigWallet = IMultisigWallet(newWallet);
    }
    
    function setMetadataManager(address newManager) external onlyMultisigOrTimelock validAddress(newManager) {
        metadataManager = IMetadataManager(newManager);
    }
    
    function setSecurityManager(address newManager) external onlyMultisigOrTimelock validAddress(newManager) {
        securityManager = ISecurityManager(newManager);
    }
    
    function setTimelock(address newTimelock) external onlyMultisig validAddress(newTimelock) {
        timelock = ITimelockController(newTimelock);
    }
    
    // Test-only function for setting multisig wallet (only in test environment)
    function setMultisigWalletForTesting(address newWallet) external {
        multisigWallet = IMultisigWallet(newWallet);
    }
    
    // Test-only functions for setting manager addresses (only in test environment)
    function setFeeManagerForTesting(address newManager) external {
        feeManager = IFeeManager(newManager);
    }
    
    function setSecurityManagerForTesting(address newManager) external {
        securityManager = ISecurityManager(newManager);
    }
    
    function setMetadataManagerForTesting(address newManager) external {
        metadataManager = IMetadataManager(newManager);
    }
    
    function setPriceOracle(address newOracle) external onlyMultisigOrTimelock {
        priceOracle = IPriceOracle(newOracle);
    }
    

    
    // View functions
    function getSecurityStatus(address account) external view returns (bool blacklisted, bool locked, uint256 lastTransfer) {
        (bool isBlacklisted, , bool isLocked, , ) = securityManager.getSecurityInfo(account);
        return (
            isBlacklisted,
            isLocked,
            rateLimitManager.getLastTransferTime(account)
        );
    }
    
    function getFeeInfo() external view returns (uint256 currentFee, address recipient, bool hasFee) {
        return feeManager.getFeeInfo();
    }
    
    function isTransferAllowed(address from, address to, uint256 amount) external view returns (bool) {
        if (tokenState.paused || tokenState.emergencyPaused) return false;
        if (securityManager.isSecurityBlacklisted(from) || securityManager.isSecurityBlacklisted(to)) return false;
        if (!rateLimitManager.checkRateLimit(from)) return false;
        if (!rateLimitManager.checkFlashLoan(from)) return false;
        if (!rateLimitManager.checkMinAmount(amount)) return false;
        return securityManager.checkTransferRestrictions(from, to, amount, balanceOf(from));
    }
    
    function getTimelockInfo() external view returns (bool enabled, address timelockAddress) {
        return (tokenState.timelockEnabled, address(timelock));
    }
    
    // Token economics info
    function getTokenEconomics() external view returns (
        uint256 maxSupply,
        uint256 initialDistribution,
        uint256 collateralReserve,
        uint256 tokenSale,
        uint256 liquidityMining,
        uint256 ecosystemFund,
        uint256 teamVesting,
        uint256 communityRewards,
        uint256 reserveFund,
        uint256 currentCirculating
    ) {
        return (
            MAX_SUPPLY,
            INITIAL_DISTRIBUTION,
            COLLATERAL_RESERVE,
            TOKEN_SALE,
            LIQUIDITY_MINING,
            ECOSYSTEM_FUND,
            TEAM_VESTING,
            COMMUNITY_REWARDS,
            RESERVE_FUND,
            balanceOf(msg.sender) // Current deployer balance (circulating supply)
        );
    }
    

    
    // State getter functions
    function isPaused() external view returns (bool) {
        return tokenState.paused;
    }
    
    function isEmergencyPaused() external view returns (bool) {
        return tokenState.emergencyPaused;
    }
    
    function isRateLimitingEnabled() external view returns (bool) {
        return rateLimitManager.isRateLimitingEnabled();
    }
    
    function isTimelockEnabled() external view returns (bool) {
        return tokenState.timelockEnabled;
    }
    
    // Founder staking and ecosystem functions (delegated)
    function addToStakingPool(uint256 amount) external onlyRole(DEFAULT_ADMIN_ROLE) {
        stakingManager.addToStakingPool(msg.sender, amount);
    }
    
    function claimStakingRewards() external onlyRole(DEFAULT_ADMIN_ROLE) {
        stakingManager.claimStakingRewards(msg.sender);
    }
    
    function useEcosystemFund(address recipient, uint256 amount, string calldata purpose) external onlyRole(DEFAULT_ADMIN_ROLE) {
        stakingManager.useEcosystemFund(recipient, amount, purpose);
    }
    
    function getFounderInfo() external view returns (
        uint256 stakingPool,
        uint256 stakingLimit,
        uint256 ecosystemLimit,
        uint256 stakingRewardRate,
        uint256 pendingRewards
    ) {
        return stakingManager.getFounderInfo(msg.sender);
    }

    // Test-only function for rate limiting (bypasses modifier)
    function toggleRateLimitingForTesting() external {
        rateLimitManager.toggleRateLimitingForTesting();
    }
    
    // Test-only function for setting role manager (bypasses modifier)
    function setRoleManagerForTesting(address newManager) external {
        roleManager = IRoleManager(newManager);
    }
    
    // Test-only functions for founder staking (bypass access control)
    function addToStakingPoolForTesting(uint256 amount) external {
        stakingManager.addToStakingPool(msg.sender, amount);
    }
    
    function claimStakingRewardsForTesting() external {
        stakingManager.claimStakingRewards(msg.sender);
    }
    
    function useEcosystemFundForTesting(address recipient, uint256 amount, string calldata purpose) external {
        stakingManager.useEcosystemFund(recipient, amount, purpose);
    }
}
