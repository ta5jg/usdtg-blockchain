// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

interface ITimelockController {
    function schedule(
        address target,
        uint256 value,
        bytes calldata data,
        bytes32 predecessor,
        bytes32 salt,
        uint256 delay
    ) external;
    
    function execute(
        address target,
        uint256 value,
        bytes calldata data,
        bytes32 predecessor,
        bytes32 salt
    ) external payable;
    
    function cancel(bytes32 id) external;
    
    function getMinDelay() external view returns (uint256);
    
    function getTimestamp(bytes32 id) external view returns (uint256);
    
    function isOperation(bytes32 id) external view returns (bool);
    
    function isOperationPending(bytes32 id) external view returns (bool);
    
    function isOperationReady(bytes32 id) external view returns (bool);
    
    function isOperationDone(bytes32 id) external view returns (bool);
    
    function getRoleAdmin(bytes32 role) external view returns (bytes32);
    
    function hasRole(bytes32 role, address account) external view returns (bool);
} 