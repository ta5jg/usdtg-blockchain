// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

/**
 * @title StablecoinCore
 * @dev USDTg stablecoin sistemi - 1 USDTg = 1 USD
 * Collateral backing ve arbitrage ile fiyat stabilizasyonu
 */
contract StablecoinCore is AccessControl, ReentrancyGuard, Pausable {
    using SafeMath for uint256;
    
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");
    bytes32 public constant ORACLE_ROLE = keccak256("ORACLE_ROLE");
    bytes32 public constant LIQUIDATOR_ROLE = keccak256("LIQUIDATOR_ROLE");
    
    IERC20 public usdtgToken;
    
    // Collateral tokens
    IERC20 public usdcToken;
    IERC20 public usdtToken;
    IERC20 public wethToken;
    
    // Collateralization parameters
    uint256 public constant MIN_COLLATERALIZATION_RATIO = 150; // 150%
    uint256 public constant LIQUIDATION_THRESHOLD = 120; // 120%
    uint256 public constant LIQUIDATION_PENALTY = 10; // 10%
    
    // Price parameters
    uint256 public constant TARGET_PRICE = 1 * 10**18; // 1 USD
    uint256 public constant PRICE_DEVIATION = 2; // ±2%
    uint256 public constant PRICE_PRECISION = 10**18;
    
    // Collateral reserves
    mapping(address => uint256) public collateralReserves;
    mapping(address => uint256) public usdtgMinted;
    mapping(address => uint256) public collateralizationRatio;
    
    // Oracle prices (in USD with 18 decimals)
    mapping(address => uint256) public oraclePrices;
    
    // Events
    event CollateralDeposited(address indexed user, address collateral, uint256 amount, uint256 usdtgMinted);
    event CollateralWithdrawn(address indexed user, address collateral, uint256 amount, uint256 usdtgBurned);
    event USDTgMinted(address indexed user, uint256 amount, uint256 collateralValue);
    event USDTgBurned(address indexed user, uint256 amount, uint256 collateralReturned);
    event PositionLiquidated(address indexed user, address liquidator, uint256 collateralSeized, uint256 usdtgBurned);
    event OraclePriceUpdated(address indexed collateral, uint256 price);
    
    modifier onlyMinter() {
        require(hasRole(MINTER_ROLE, msg.sender), "Only minter");
        _;
    }
    
    modifier onlyBurner() {
        require(hasRole(BURNER_ROLE, msg.sender), "Only burner");
        _;
    }
    
    modifier onlyOracle() {
        require(hasRole(ORACLE_ROLE, msg.sender), "Only oracle");
        _;
    }
    
    modifier onlyLiquidator() {
        require(hasRole(LIQUIDATOR_ROLE, msg.sender), "Only liquidator");
        _;
    }
    
    modifier validCollateral(address collateral) {
        require(
            collateral == address(usdcToken) ||
            collateral == address(usdtToken) ||
            collateral == address(wethToken),
            "Invalid collateral"
        );
        _;
    }
    
    constructor(
        address _usdtgToken,
        address _usdcToken,
        address _usdtToken,
        address _wethToken
    ) {
        require(_usdtgToken != address(0), "Invalid USDTg token");
        require(_usdcToken != address(0), "Invalid USDC token");
        require(_usdtToken != address(0), "Invalid USDT token");
        require(_wethToken != address(0), "Invalid WETH token");
        
        usdtgToken = IERC20(_usdtgToken);
        usdcToken = IERC20(_usdcToken);
        usdtToken = IERC20(_usdtToken);
        wethToken = IERC20(_wethToken);
        
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        _grantRole(BURNER_ROLE, msg.sender);
        _grantRole(ORACLE_ROLE, msg.sender);
        _grantRole(LIQUIDATOR_ROLE, msg.sender);
        
        // Set initial oracle prices
        oraclePrices[address(usdcToken)] = 1 * 10**18; // 1 USD
        oraclePrices[address(usdtToken)] = 1 * 10**18; // 1 USD
        oraclePrices[address(wethToken)] = 2000 * 10**18; // 2000 USD (example)
    }
    
    /**
     * @dev Collateral yatır ve USDTg mint et
     */
    function mintWithCollateral(
        address collateral,
        uint256 collateralAmount
    ) external validCollateral(collateral) nonReentrant whenNotPaused {
        require(collateralAmount > 0, "Amount must be positive");
        
        // Transfer collateral
        IERC20(collateral).transferFrom(msg.sender, address(this), collateralAmount);
        
        // Calculate collateral value in USD
        uint256 collateralValue = getCollateralValue(collateral, collateralAmount);
        
        // Calculate USDTg to mint (1:1 ratio)
        uint256 usdtgToMint = collateralValue;
        
        // Check if we have enough tokens in reserve
        uint256 availableTokens = usdtgToken.balanceOf(address(this));
        require(availableTokens >= usdtgToMint, "Insufficient USDTg in reserve");
        
        // Update state
        collateralReserves[collateral] = collateralReserves[collateral].add(collateralAmount);
        usdtgMinted[msg.sender] = usdtgMinted[msg.sender].add(usdtgToMint);
        
        // Update collateralization ratio
        updateCollateralizationRatio(msg.sender);
        
        // Transfer USDTg from reserve
        require(usdtgToken.transfer(msg.sender, usdtgToMint), "USDTg mint failed");
        
        emit CollateralDeposited(msg.sender, collateral, collateralAmount, usdtgToMint);
        emit USDTgMinted(msg.sender, usdtgToMint, collateralValue);
    }
    
    /**
     * @dev USDTg yak ve collateral geri al
     */
    function burnAndWithdrawCollateral(
        address collateral,
        uint256 usdtgAmount
    ) external validCollateral(collateral) nonReentrant whenNotPaused {
        require(usdtgAmount > 0, "Amount must be positive");
        
        // Transfer USDTg from user
        usdtgToken.transferFrom(msg.sender, address(this), usdtgAmount);
        
        // Calculate collateral to return
        uint256 collateralToReturn = getCollateralAmount(collateral, usdtgAmount);
        
        // Check if user has enough collateral
        require(collateralReserves[collateral] >= collateralToReturn, "Insufficient collateral");
        
        // Update state
        collateralReserves[collateral] = collateralReserves[collateral].sub(collateralToReturn);
        usdtgMinted[msg.sender] = usdtgMinted[msg.sender].sub(usdtgAmount);
        
        // Update collateralization ratio
        updateCollateralizationRatio(msg.sender);
        
        // Return collateral
        require(IERC20(collateral).transfer(msg.sender, collateralToReturn), "Collateral transfer failed");
        
        emit CollateralWithdrawn(msg.sender, collateral, collateralToReturn, usdtgAmount);
        emit USDTgBurned(msg.sender, usdtgAmount, collateralToReturn);
    }
    
    /**
     * @dev Pozisyonu liquidate et
     */
    function liquidatePosition(address user) external onlyLiquidator nonReentrant {
        require(collateralizationRatio[user] < LIQUIDATION_THRESHOLD, "Position not liquidatable");
        
        uint256 totalUsdtgMinted = usdtgMinted[user];
        uint256 liquidationAmount = totalUsdtgMinted.mul(LIQUIDATION_PENALTY).div(100);
        
        // Burn USDTg
        usdtgToken.transferFrom(msg.sender, address(this), liquidationAmount);
        
        // Calculate collateral to seize
        uint256 collateralToSeize = 0;
        
        // Seize collateral proportionally
        if (collateralReserves[address(usdcToken)] > 0) {
            uint256 usdcSeized = collateralReserves[address(usdcToken)].mul(liquidationAmount).div(totalUsdtgMinted);
            collateralReserves[address(usdcToken)] = collateralReserves[address(usdcToken)].sub(usdcSeized);
            collateralToSeize = collateralToSeize.add(usdcSeized);
            usdcToken.transfer(msg.sender, usdcSeized);
        }
        
        if (collateralReserves[address(usdtToken)] > 0) {
            uint256 usdtSeized = collateralReserves[address(usdtToken)].mul(liquidationAmount).div(totalUsdtgMinted);
            collateralReserves[address(usdtToken)] = collateralReserves[address(usdtToken)].sub(usdtSeized);
            collateralToSeize = collateralToSeize.add(usdtSeized);
            usdtToken.transfer(msg.sender, usdtSeized);
        }
        
        if (collateralReserves[address(wethToken)] > 0) {
            uint256 wethSeized = collateralReserves[address(wethToken)].mul(liquidationAmount).div(totalUsdtgMinted);
            collateralReserves[address(wethToken)] = collateralReserves[address(wethToken)].sub(wethSeized);
            collateralToSeize = collateralToSeize.add(wethSeized);
            wethToken.transfer(msg.sender, wethSeized);
        }
        
        // Update user state
        usdtgMinted[user] = usdtgMinted[user].sub(liquidationAmount);
        updateCollateralizationRatio(user);
        
        emit PositionLiquidated(user, msg.sender, collateralToSeize, liquidationAmount);
    }
    
    /**
     * @dev Oracle fiyatını güncelle
     */
    function updateOraclePrice(address collateral, uint256 price) external onlyOracle {
        require(price > 0, "Price must be positive");
        oraclePrices[collateral] = price;
        emit OraclePriceUpdated(collateral, price);
    }
    
    /**
     * @dev Collateral değerini USD olarak hesapla
     */
    function getCollateralValue(address collateral, uint256 amount) public view returns (uint256) {
        uint256 price = oraclePrices[collateral];
        return amount.mul(price).div(PRICE_PRECISION);
    }
    
    /**
     * @dev USD değeri için gerekli collateral miktarını hesapla
     */
    function getCollateralAmount(address collateral, uint256 usdValue) public view returns (uint256) {
        uint256 price = oraclePrices[collateral];
        return usdValue.mul(PRICE_PRECISION).div(price);
    }
    
    /**
     * @dev Kullanıcının collateralization ratio'sunu güncelle
     */
    function updateCollateralizationRatio(address user) internal {
        uint256 totalCollateralValue = 0;
        
        // Calculate total collateral value
        totalCollateralValue = totalCollateralValue.add(
            getCollateralValue(address(usdcToken), collateralReserves[address(usdcToken)])
        );
        totalCollateralValue = totalCollateralValue.add(
            getCollateralValue(address(usdtToken), collateralReserves[address(usdtToken)])
        );
        totalCollateralValue = totalCollateralValue.add(
            getCollateralValue(address(wethToken), collateralReserves[address(wethToken)])
        );
        
        // Calculate ratio
        if (usdtgMinted[user] > 0) {
            collateralizationRatio[user] = totalCollateralValue.mul(100).div(usdtgMinted[user]);
        } else {
            collateralizationRatio[user] = 0;
        }
    }
    
    /**
     * @dev Kullanıcı pozisyon bilgilerini getir
     */
    function getUserPosition(address user) external view returns (
        uint256 totalUsdtgMinted,
        uint256 collateralizationRatio_,
        bool isLiquidatable,
        uint256 totalCollateralValue
    ) {
        uint256 totalValue = 0;
        totalValue = totalValue.add(getCollateralValue(address(usdcToken), collateralReserves[address(usdcToken)]));
        totalValue = totalValue.add(getCollateralValue(address(usdtToken), collateralReserves[address(usdtToken)]));
        totalValue = totalValue.add(getCollateralValue(address(wethToken), collateralReserves[address(wethToken)]));
        
        bool liquidatable = collateralizationRatio[user] < LIQUIDATION_THRESHOLD;
        
        return (
            usdtgMinted[user],
            collateralizationRatio[user],
            liquidatable,
            totalValue
        );
    }
    
    /**
     * @dev Sistem durumunu getir
     */
    function getSystemStatus() external view returns (
        uint256 totalCollateralValue,
        uint256 totalUsdtgMinted,
        uint256 collateralizationRatio_,
        uint256 usdcReserves,
        uint256 usdtReserves,
        uint256 wethReserves
    ) {
        uint256 totalValue = 0;
        totalValue = totalValue.add(getCollateralValue(address(usdcToken), collateralReserves[address(usdcToken)]));
        totalValue = totalValue.add(getCollateralValue(address(usdtToken), collateralReserves[address(usdtToken)]));
        totalValue = totalValue.add(getCollateralValue(address(wethToken), collateralReserves[address(wethToken)]));
        
        uint256 totalMinted = usdtgToken.totalSupply();
        uint256 systemRatio = totalMinted > 0 ? totalValue.mul(100).div(totalMinted) : 0;
        
        return (
            totalValue,
            totalMinted,
            systemRatio,
            collateralReserves[address(usdcToken)],
            collateralReserves[address(usdtToken)],
            collateralReserves[address(wethToken)]
        );
    }
    
    /**
     * @dev Direct USDTg mint (only for authorized users)
     */
    function mint(address to, uint256 amount) external onlyMinter {
        require(to != address(0), "Invalid recipient");
        require(amount > 0, "Amount must be positive");
        
        // Check if we have enough tokens in reserve
        uint256 availableTokens = usdtgToken.balanceOf(address(this));
        require(availableTokens >= amount, "Insufficient USDTg in reserve");
        
        // Transfer USDTg from reserve
        require(usdtgToken.transfer(to, amount), "USDTg mint failed");
        
        emit USDTgMinted(to, amount, 0);
    }
    
    /**
     * @dev Direct USDTg burn (only for authorized users)
     */
    function burn(address from, uint256 amount) external onlyBurner {
        require(from != address(0), "Invalid address");
        require(amount > 0, "Amount must be positive");
        
        // Transfer USDTg from user to this contract
        require(usdtgToken.transferFrom(from, address(this), amount), "USDTg burn failed");
        
        emit USDTgBurned(from, amount, 0);
    }
    
    /**
     * @dev Emergency pause
     */
    function emergencyPause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }
    
    /**
     * @dev Emergency unpause
     */
    function emergencyUnpause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }
    
    /**
     * @dev Check if contract is emergency paused
     */
    function isEmergencyPaused() external view returns (bool) {
        return paused();
    }

    // =====================
    // TEST-ONLY FUNCTIONS
    // =====================
    function grantRoleForTesting(bytes32 role, address account) external {
        _grantRole(role, account);
    }
    
    function updateOraclePriceForTesting(address collateral, uint256 price) external {
        require(price > 0, "Price must be positive");
        oraclePrices[collateral] = price;
        emit OraclePriceUpdated(collateral, price);
    }
} 