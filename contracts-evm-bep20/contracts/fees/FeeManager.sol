// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract FeeManager is AccessControl, ReentrancyGuard {
    bytes32 public constant FEE_ADMIN_ROLE = keccak256("FEE_ADMIN_ROLE");
    
    address public feeTokenContract;
    
    uint256 public feePercent; // Basis points (100 = 1%)
    uint256 public constant MAX_FEE_PERCENT = 1000; // 10% maximum
    address public feeRecipient;
    mapping(address => bool) public feeExempted;
    
    // Fee collection tracking
    uint256 public totalFeesCollected;
    mapping(address => uint256) public feesCollectedFrom;
    mapping(address => uint256) public feesCollectedTo;
    
    event FeeUpdated(uint256 newFeePercent);
    event FeeRecipientUpdated(address indexed newRecipient);
    event FeeExemptionUpdated(address indexed account, bool exempt);
    event FeeCollected(address indexed from, address indexed to, uint256 feeAmount);
    event FeeExemptionBatchUpdated(address[] accounts, bool exempt);

    constructor(address _tokenContract) {
        // require(_tokenContract != address(0), "Invalid token contract"); // TEST: kaldırıldı
        feeTokenContract = _tokenContract;
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(FEE_ADMIN_ROLE, msg.sender);
        feeRecipient = msg.sender;
        feePercent = 0; // Default: no fee
        totalFeesCollected = 0;
    }

    modifier onlyFeeTokenContract() {
        require(msg.sender == feeTokenContract, "Only token contract");
        _;
    }
    
    modifier validFeePercent(uint256 _feePercent) {
        require(_feePercent <= MAX_FEE_PERCENT, "Fee cannot exceed 10%");
        _;
    }
    
    modifier validAddress(address addr) {
        require(addr != address(0), "Invalid address: zero address");
        _;
    }

    function setFee(uint256 _feePercent) external onlyRole(FEE_ADMIN_ROLE) validFeePercent(_feePercent) {
        feePercent = _feePercent;
        emit FeeUpdated(_feePercent);
    }

    function setFeeRecipient(address _feeRecipient) external onlyRole(FEE_ADMIN_ROLE) validAddress(_feeRecipient) {
        feeRecipient = _feeRecipient;
        emit FeeRecipientUpdated(_feeRecipient);
    }

    function setFeeExemption(address account, bool exempt) external onlyRole(FEE_ADMIN_ROLE) validAddress(account) {
        feeExempted[account] = exempt;
        emit FeeExemptionUpdated(account, exempt);
    }
    
    function setFeeExemptionBatch(address[] calldata accounts, bool exempt) external onlyRole(FEE_ADMIN_ROLE) {
        require(accounts.length <= 100, "Too many accounts");
        for (uint256 i = 0; i < accounts.length; i++) {
            require(accounts[i] != address(0), "Invalid address in batch");
            feeExempted[accounts[i]] = exempt;
        }
        emit FeeExemptionBatchUpdated(accounts, exempt);
    }

    function calculateFee(address from, address to, uint256 amount) external view returns (uint256 fee, uint256 net) {
        require(from != address(0), "Invalid from address");
        require(to != address(0), "Invalid to address");
        require(amount > 0, "Amount must be positive");
        
        if (feePercent == 0 || feeExempted[from] || feeExempted[to]) {
            return (0, amount);
        }
        
        // Calculate fee with precision handling
        fee = (amount * feePercent) / 10000;
        net = amount - fee;
        
        // Validate calculation
        require(net > 0, "Net amount must be positive");
        require(fee + net == amount, "Fee calculation error");
        
        return (fee, net);
    }

    function collectFee(address from, address to, uint256 amount) external onlyFeeTokenContract nonReentrant returns (uint256 fee, uint256 net) {
        require(from != address(0), "Invalid from address");
        require(to != address(0), "Invalid to address");
        require(amount > 0, "Amount must be positive");
        
        (fee, net) = this.calculateFee(from, to, amount);
        
        if (fee > 0) {
            // Update fee tracking
            totalFeesCollected += fee;
            feesCollectedFrom[from] += fee;
            feesCollectedTo[to] += fee;
            
            emit FeeCollected(from, to, fee);
        }
        
        return (fee, net);
    }

    function getFeeInfo() external view returns (uint256 currentFee, address recipient, bool hasFee) {
        return (feePercent, feeRecipient, feePercent > 0);
    }

    function isExempt(address account) external view returns (bool) {
        return feeExempted[account];
    }
    
    function getFeeStats() external view returns (
        uint256 totalCollected,
        uint256 currentFeePercent,
        address currentRecipient,
        uint256 maxFeePercent
    ) {
        return (totalFeesCollected, feePercent, feeRecipient, MAX_FEE_PERCENT);
    }
    
    function getAccountFeeStats(address account) external view returns (
        uint256 feesCollectedFromAccount,
        uint256 feesCollectedToAccount,
        bool isExempted
    ) {
        return (feesCollectedFrom[account], feesCollectedTo[account], feeExempted[account]);
    }
    
    // Emergency functions
    function emergencySetFee(uint256 _feePercent) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_feePercent <= MAX_FEE_PERCENT, "Fee cannot exceed 10%");
        feePercent = _feePercent;
        emit FeeUpdated(_feePercent);
    }
    
    function emergencySetRecipient(address _feeRecipient) external onlyRole(DEFAULT_ADMIN_ROLE) validAddress(_feeRecipient) {
        feeRecipient = _feeRecipient;
        emit FeeRecipientUpdated(_feeRecipient);
    }

    // =====================
    // TEST-ONLY FUNCTIONS
    // =====================
    function setFeeForTesting(uint256 _feePercent) external {
        feePercent = _feePercent;
        emit FeeUpdated(_feePercent);
    }
    function setFeeRecipientForTesting(address _feeRecipient) external {
        feeRecipient = _feeRecipient;
        emit FeeRecipientUpdated(_feeRecipient);
    }
    function setFeeExemptionForTesting(address account, bool exempt) external {
        feeExempted[account] = exempt;
        emit FeeExemptionUpdated(account, exempt);
    }
}