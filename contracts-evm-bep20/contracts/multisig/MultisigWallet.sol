// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract MultisigWallet is AccessControl, ReentrancyGuard {
    address public tokenContract;
    
    // Multisig configuration
    uint256 public requiredSignatures;
    uint256 public totalSigners;
    mapping(address => bool) public isSigner;
    address[] public signers;
    
    // Transaction management
    struct Transaction {
        address target;
        uint256 value;
        bytes data;
        bool executed;
        uint256 confirmations;
        uint256 timestamp;
        string description;
    }
    
    mapping(uint256 => Transaction) public transactions;
    mapping(uint256 => mapping(address => bool)) public confirmations;
    uint256 public transactionCount;
    
    // Events
    event TransactionSubmitted(uint256 indexed txId, address indexed target, uint256 value, string description);
    event TransactionConfirmed(uint256 indexed txId, address indexed signer);
    event TransactionRevoked(uint256 indexed txId, address indexed signer);
    event TransactionExecuted(uint256 indexed txId, address indexed target, uint256 value);
    event SignerAdded(address indexed signer);
    event SignerRemoved(address indexed signer);
    event RequiredSignaturesUpdated(uint256 newRequired);

    constructor(address _tokenContract, address[] memory _signers, uint256 _requiredSignatures) {
        tokenContract = _tokenContract;
        requiredSignatures = _requiredSignatures;
        
        require(_signers.length > 0, "At least one signer required");
        require(_requiredSignatures > 0 && _requiredSignatures <= _signers.length, "Invalid required signatures");
        
        for (uint256 i = 0; i < _signers.length; i++) {
            require(_signers[i] != address(0), "Invalid signer address");
            require(!isSigner[_signers[i]], "Duplicate signer");
            
            isSigner[_signers[i]] = true;
            signers.push(_signers[i]);
        }
        
        totalSigners = _signers.length;
        
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    modifier onlyTokenContract() {
        if (tokenContract != address(0)) {
            require(msg.sender == tokenContract, "Only token contract");
        }
        _;
    }

    modifier onlySigner() {
        require(isSigner[msg.sender], "Only signer");
        _;
    }

    modifier transactionExists(uint256 txId) {
        require(transactions[txId].target != address(0), "Transaction does not exist");
        _;
    }

    modifier notExecuted(uint256 txId) {
        require(!transactions[txId].executed, "Transaction already executed");
        _;
    }

    modifier notConfirmed(uint256 txId) {
        require(!confirmations[txId][msg.sender], "Transaction already confirmed");
        _;
    }

    modifier onlySelf() {
        require(msg.sender == address(this), "Only multisig can call");
        _;
    }

    function submitTransaction(
        address target,
        uint256 value,
        bytes calldata data,
        string calldata description
    ) external onlySigner returns (uint256 txId) {
        require(target != address(0), "Invalid target address");
        
        txId = transactionCount;
        transactionCount++;
        
        transactions[txId] = Transaction({
            target: target,
            value: value,
            data: data,
            executed: false,
            confirmations: 0,
            timestamp: block.timestamp,
            description: description
        });
        
        emit TransactionSubmitted(txId, target, value, description);
        
        return txId;
    }

    function confirmTransaction(uint256 txId) external 
        onlySigner 
        transactionExists(txId) 
        notExecuted(txId) 
        notConfirmed(txId) 
    {
        Transaction storage transaction = transactions[txId];
        transaction.confirmations++;
        confirmations[txId][msg.sender] = true;
        
        emit TransactionConfirmed(txId, msg.sender);
        
        if (transaction.confirmations >= requiredSignatures) {
            executeTransaction(txId);
        }
    }

    function revokeConfirmation(uint256 txId) external 
        onlySigner 
        transactionExists(txId) 
        notExecuted(txId) 
    {
        require(confirmations[txId][msg.sender], "Transaction not confirmed");
        
        Transaction storage transaction = transactions[txId];
        transaction.confirmations--;
        confirmations[txId][msg.sender] = false;
        
        emit TransactionRevoked(txId, msg.sender);
    }

    function executeTransaction(uint256 txId) public 
        onlySigner 
        transactionExists(txId) 
        notExecuted(txId) 
        nonReentrant 
    {
        Transaction storage transaction = transactions[txId];
        require(transaction.confirmations >= requiredSignatures, "Insufficient confirmations");
        
        transaction.executed = true;
        
        (bool success, ) = transaction.target.call{value: transaction.value}(transaction.data);
        require(success, "Transaction execution failed");
        
        emit TransactionExecuted(txId, transaction.target, transaction.value);
    }

    function addSigner(address signer) external onlySelf {
        require(signer != address(0), "Invalid signer address");
        require(!isSigner[signer], "Already a signer");
        
        isSigner[signer] = true;
        signers.push(signer);
        totalSigners++;
        
        emit SignerAdded(signer);
    }
    
    function addSignersBatch(address[] calldata newSigners) external onlySelf {
        require(newSigners.length <= 10, "Too many signers at once");
        
        for (uint256 i = 0; i < newSigners.length; i++) {
            require(newSigners[i] != address(0), "Invalid signer address");
            require(!isSigner[newSigners[i]], "Already a signer");
            
            isSigner[newSigners[i]] = true;
            signers.push(newSigners[i]);
            totalSigners++;
            
            emit SignerAdded(newSigners[i]);
        }
    }

    function removeSigner(address signer) external onlySelf {
        require(isSigner[signer], "Not a signer");
        require(totalSigners > requiredSignatures, "Cannot remove signer: too few remaining");
        
        isSigner[signer] = false;
        totalSigners--;
        
        // Remove from signers array
        for (uint256 i = 0; i < signers.length; i++) {
            if (signers[i] == signer) {
                signers[i] = signers[signers.length - 1];
                signers.pop();
                break;
            }
        }
        
        emit SignerRemoved(signer);
    }
    
    function removeSignersBatch(address[] calldata signersToRemove) external onlySelf {
        require(signersToRemove.length <= 5, "Too many signers to remove at once");
        
        for (uint256 i = 0; i < signersToRemove.length; i++) {
            require(isSigner[signersToRemove[i]], "Not a signer");
            require(totalSigners > requiredSignatures, "Cannot remove signer: too few remaining");
            
            isSigner[signersToRemove[i]] = false;
            totalSigners--;
            
            // Remove from signers array
            for (uint256 j = 0; j < signers.length; j++) {
                if (signers[j] == signersToRemove[i]) {
                    signers[j] = signers[signers.length - 1];
                    signers.pop();
                    break;
                }
            }
            
            emit SignerRemoved(signersToRemove[i]);
        }
    }

    function updateRequiredSignatures(uint256 newRequired) external onlySelf {
        require(newRequired > 0 && newRequired <= totalSigners, "Invalid required signatures");
        requiredSignatures = newRequired;
        emit RequiredSignaturesUpdated(newRequired);
    }

    function getTransaction(uint256 txId) external view returns (
        address target,
        uint256 value,
        bytes memory data,
        bool executed,
        uint256 confirmationCount,
        uint256 timestamp,
        string memory description
    ) {
        Transaction storage transaction = transactions[txId];
        return (
            transaction.target,
            transaction.value,
            transaction.data,
            transaction.executed,
            transaction.confirmations,
            transaction.timestamp,
            transaction.description
        );
    }

    function getSigners() external view returns (address[] memory) {
        return signers;
    }
    
    function getSignerInfo() external view returns (
        address[] memory allSigners,
        uint256 totalSigners_,
        uint256 requiredSignatures_,
        bool isOwner
    ) {
        return (
            signers,
            totalSigners,
            requiredSignatures,
            hasRole(DEFAULT_ADMIN_ROLE, msg.sender)
        );
    }
    
    function getSignerStatus(address signer) external view returns (
        bool isSigner_,
        uint256 signerIndex,
        bool isOwner_
    ) {
        uint256 index = type(uint256).max;
        for (uint256 i = 0; i < signers.length; i++) {
            if (signers[i] == signer) {
                index = i;
                break;
            }
        }
        
        return (
            isSigner[signer],
            index,
            hasRole(DEFAULT_ADMIN_ROLE, signer)
        );
    }

    function isConfirmed(uint256 txId, address signer) external view returns (bool) {
        return confirmations[txId][signer];
    }

    function getTransactionConfirmations(uint256 txId) external view returns (address[] memory) {
        address[] memory confirmedSigners = new address[](transactions[txId].confirmations);
        uint256 count = 0;
        
        for (uint256 i = 0; i < signers.length; i++) {
            if (confirmations[txId][signers[i]]) {
                confirmedSigners[count] = signers[i];
                count++;
            }
        }
        
        return confirmedSigners;
    }

    function getPendingTransactions() external view returns (uint256[] memory) {
        uint256[] memory pending = new uint256[](transactionCount);
        uint256 count = 0;
        
        for (uint256 i = 0; i < transactionCount; i++) {
            if (!transactions[i].executed) {
                pending[count] = i;
                count++;
            }
        }
        
        // Resize array
        uint256[] memory result = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            result[i] = pending[i];
        }
        
        return result;
    }

    // Emergency functions
    function emergencyPause() external onlySigner {
        // This would call the token contract's pause function
        // Implementation depends on token contract interface
    }

    function emergencyUnpause() external onlySigner {
        // This would call the token contract's unpause function
        // Implementation depends on token contract interface
    }

    // Receive function for ETH
    receive() external payable {}
} 