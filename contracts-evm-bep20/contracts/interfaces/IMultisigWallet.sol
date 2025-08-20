// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

interface IMultisigWallet {
    function submitTransaction(address target, uint256 value, bytes calldata data, string calldata description) external returns (uint256 txId);
    function confirmTransaction(uint256 txId) external;
    function revokeConfirmation(uint256 txId) external;
    function executeTransaction(uint256 txId) external;
    function addSigner(address signer) external;
    function removeSigner(address signer) external;
    function updateRequiredSignatures(uint256 newRequired) external;
    function getTransaction(uint256 txId) external view returns (address target, uint256 value, bytes memory data, bool executed, uint256 confirmationCount, uint256 timestamp, string memory description);
    function getSigners() external view returns (address[] memory);
    function isConfirmed(uint256 txId, address signer) external view returns (bool);
    function getTransactionConfirmations(uint256 txId) external view returns (address[] memory);
    function getPendingTransactions() external view returns (uint256[] memory);
    function requiredSignatures() external view returns (uint256);
    function totalSigners() external view returns (uint256);
    function isSigner(address account) external view returns (bool);
} 