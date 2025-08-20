// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

/**
 * @title StablecoinManager
 * @dev Stablecoin işlemleri için özel fee ve yönetim sistemi
 */
contract StablecoinManager is AccessControl, ReentrancyGuard {
    using SafeMath for uint256;
    
    bytes32 public constant FEE_ADMIN_ROLE = keccak256("FEE_ADMIN_ROLE");
    bytes32 public constant ORACLE_ROLE = keccak256("ORACLE_ROLE");
    
    // Fee rates (basis points)
    uint256 public mintFee = 5; // 0.05%
    uint256 public burnFee = 5; // 0.05%
    uint256 public transferFee = 2; // 0.02%
    uint256 public liquidationFee = 30; // 0.3%
    
    // Fee recipient
    address public feeRecipient;
    
    // Fee exemptions
    mapping(address => bool) public feeExempted;
    
    // Fee tracking
    uint256 public totalFeesCollected;
    mapping(address => uint256) public feesCollectedFrom;
    
    // Events
    event FeeUpdated(string operation, uint256 newFee);
    event FeeRecipientUpdated(address indexed newRecipient);
    event FeeExemptionUpdated(address indexed account, bool exempt);
    event FeeCollected(address indexed from, string operation, uint256 feeAmount);
    
    modifier onlyFeeAdmin() {
        require(hasRole(FEE_ADMIN_ROLE, msg.sender), "Only fee admin");
        _;
    }
    
    modifier onlyOracle() {
        require(hasRole(ORACLE_ROLE, msg.sender), "Only oracle");
        _;
    }
    
    modifier validFeePercent(uint256 _feePercent) {
        require(_feePercent <= 100, "Fee cannot exceed 1%");
        _;
    }
    
    modifier validAddress(address addr) {
        require(addr != address(0), "Invalid address");
        _;
    }
    
    constructor(address _feeRecipient, address _multisigWallet) {
        require(_feeRecipient != address(0), "Invalid fee recipient");
        require(_multisigWallet != address(0), "Invalid multisig wallet");
        
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(FEE_ADMIN_ROLE, msg.sender);
        _grantRole(ORACLE_ROLE, msg.sender);
        
        feeRecipient = _feeRecipient;
        feeExempted[_multisigWallet] = true;
    }
    
    /**
     * @dev Mint işlemi için fee hesapla
     */
    function calculateMintFee(address user, uint256 amount) external view returns (uint256 fee, uint256 net) {
        if (mintFee == 0 || feeExempted[user]) {
            return (0, amount);
        }
        
        fee = amount.mul(mintFee).div(10000);
        net = amount.sub(fee);
        
        require(net > 0, "Net amount must be positive");
        return (fee, net);
    }
    
    /**
     * @dev Burn işlemi için fee hesapla
     */
    function calculateBurnFee(address user, uint256 amount) external view returns (uint256 fee, uint256 net) {
        if (burnFee == 0 || feeExempted[user]) {
            return (0, amount);
        }
        
        fee = amount.mul(burnFee).div(10000);
        net = amount.sub(fee);
        
        require(net > 0, "Net amount must be positive");
        return (fee, net);
    }
    
    /**
     * @dev Transfer işlemi için fee hesapla
     */
    function calculateTransferFee(address from, address to, uint256 amount) external view returns (uint256 fee, uint256 net) {
        if (transferFee == 0 || feeExempted[from] || feeExempted[to]) {
            return (0, amount);
        }
        
        fee = amount.mul(transferFee).div(10000);
        net = amount.sub(fee);
        
        require(net > 0, "Net amount must be positive");
        return (fee, net);
    }
    
    /**
     * @dev Liquidation işlemi için fee hesapla
     */
    function calculateLiquidationFee(address liquidator, uint256 amount) external view returns (uint256 fee, uint256 net) {
        if (liquidationFee == 0 || feeExempted[liquidator]) {
            return (0, amount);
        }
        
        fee = amount.mul(liquidationFee).div(10000);
        net = amount.sub(fee);
        
        require(net > 0, "Net amount must be positive");
        return (fee, net);
    }
    
    /**
     * @dev Fee topla ve kaydet
     */
    function collectFee(address from, string memory operation, uint256 feeAmount) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (feeAmount > 0) {
            totalFeesCollected = totalFeesCollected.add(feeAmount);
            feesCollectedFrom[from] = feesCollectedFrom[from].add(feeAmount);
            
            emit FeeCollected(from, operation, feeAmount);
        }
    }
    
    /**
     * @dev Fee oranlarını güncelle
     */
    function setMintFee(uint256 _fee) external onlyFeeAdmin validFeePercent(_fee) {
        mintFee = _fee;
        emit FeeUpdated("mint", _fee);
    }
    
    function setBurnFee(uint256 _fee) external onlyFeeAdmin validFeePercent(_fee) {
        burnFee = _fee;
        emit FeeUpdated("burn", _fee);
    }
    
    function setTransferFee(uint256 _fee) external onlyFeeAdmin validFeePercent(_fee) {
        transferFee = _fee;
        emit FeeUpdated("transfer", _fee);
    }
    
    function setLiquidationFee(uint256 _fee) external onlyFeeAdmin validFeePercent(_fee) {
        liquidationFee = _fee;
        emit FeeUpdated("liquidation", _fee);
    }
    
    /**
     * @dev Fee recipient'ı güncelle
     */
    function setFeeRecipient(address _feeRecipient) external onlyFeeAdmin validAddress(_feeRecipient) {
        feeRecipient = _feeRecipient;
        emit FeeRecipientUpdated(_feeRecipient);
    }
    
    /**
     * @dev Fee muafiyeti ayarla
     */
    function setFeeExemption(address account, bool exempt) external onlyFeeAdmin validAddress(account) {
        feeExempted[account] = exempt;
        emit FeeExemptionUpdated(account, exempt);
    }
    
    /**
     * @dev Toplu fee muafiyeti ayarla
     */
    function setFeeExemptionBatch(address[] calldata accounts, bool exempt) external onlyFeeAdmin {
        require(accounts.length <= 100, "Too many accounts");
        for (uint256 i = 0; i < accounts.length; i++) {
            require(accounts[i] != address(0), "Invalid address in batch");
            feeExempted[accounts[i]] = exempt;
            emit FeeExemptionUpdated(accounts[i], exempt);
        }
    }
    
    /**
     * @dev Fee bilgilerini getir
     */
    function getFeeInfo() external view returns (
        uint256 mintFee_,
        uint256 burnFee_,
        uint256 transferFee_,
        uint256 liquidationFee_,
        address feeRecipient_,
        uint256 totalFeesCollected_
    ) {
        return (
            mintFee,
            burnFee,
            transferFee,
            liquidationFee,
            feeRecipient,
            totalFeesCollected
        );
    }
    
    /**
     * @dev Kullanıcı fee istatistiklerini getir
     */
    function getUserFeeStats(address user) external view returns (
        uint256 feesCollectedFromUser,
        bool isExempted
    ) {
        return (feesCollectedFrom[user], feeExempted[user]);
    }
    
    /**
     * @dev Emergency fee ayarları
     */
    function emergencySetFees(
        uint256 _mintFee,
        uint256 _burnFee,
        uint256 _transferFee,
        uint256 _liquidationFee
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_mintFee <= 100 && _burnFee <= 100 && _transferFee <= 100 && _liquidationFee <= 100, "Fees too high");
        
        mintFee = _mintFee;
        burnFee = _burnFee;
        transferFee = _transferFee;
        liquidationFee = _liquidationFee;
        
        emit FeeUpdated("emergency_mint", _mintFee);
        emit FeeUpdated("emergency_burn", _burnFee);
        emit FeeUpdated("emergency_transfer", _transferFee);
        emit FeeUpdated("emergency_liquidation", _liquidationFee);
    }
} 