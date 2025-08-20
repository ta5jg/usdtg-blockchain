// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

interface IRoleManager {
    function grantRole(bytes32 role, address account) external;
    function revokeRole(bytes32 role, address account) external;
    function grantMultipleRoles(bytes32[] calldata roles, address account) external;
    function revokeMultipleRoles(bytes32[] calldata roles, address account) external;
    function hasAnyRole(address account, bytes32[] calldata roles) external view returns (bool);
    function hasAllRoles(address account, bytes32[] calldata roles) external view returns (bool);
    function getRoleMembers(bytes32 role) external view returns (address[] memory);
    function getAccountRoles(address account) external view returns (bytes32[] memory);
    function isOwner(address account) external view returns (bool);
    function isMinter(address account) external view returns (bool);
    function isBurner(address account) external view returns (bool);
    function isPauser(address account) external view returns (bool);
    function isBlacklistManager(address account) external view returns (bool);
    function isEmergencyRole(address account) external view returns (bool);
    function hasRole(bytes32 role, address account) external view returns (bool);
} 