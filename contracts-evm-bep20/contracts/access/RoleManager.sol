// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/access/AccessControl.sol";

contract RoleManager is AccessControl {
    address public tokenContract;
    
    // Custom roles
    bytes32 public constant OWNER_ROLE = keccak256("OWNER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant BLACKLIST_MANAGER_ROLE = keccak256("BLACKLIST_MANAGER_ROLE");
    bytes32 public constant FEE_MANAGER_ROLE = keccak256("FEE_MANAGER_ROLE");
    bytes32 public constant SECURITY_MANAGER_ROLE = keccak256("SECURITY_MANAGER_ROLE");
    bytes32 public constant METADATA_MANAGER_ROLE = keccak256("METADATA_MANAGER_ROLE");
    bytes32 public constant GOVERNANCE_MANAGER_ROLE = keccak256("GOVERNANCE_MANAGER_ROLE");
    bytes32 public constant VESTING_MANAGER_ROLE = keccak256("VESTING_MANAGER_ROLE");
    bytes32 public constant STABLECOIN_MANAGER_ROLE = keccak256("STABLECOIN_MANAGER_ROLE");
    bytes32 public constant EMERGENCY_ROLE = keccak256("EMERGENCY_ROLE");
    
    // Role hierarchy
    mapping(bytes32 => bytes32[]) public roleHierarchy;
    
    event RoleHierarchyUpdated(bytes32 indexed role, bytes32[] newHierarchy);

    constructor(address _tokenContract) {
        tokenContract = _tokenContract;
        
        // Setup initial roles for deployer
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(OWNER_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        _grantRole(BURNER_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
        _grantRole(BLACKLIST_MANAGER_ROLE, msg.sender);
        _grantRole(FEE_MANAGER_ROLE, msg.sender);
        _grantRole(SECURITY_MANAGER_ROLE, msg.sender);
        _grantRole(METADATA_MANAGER_ROLE, msg.sender);
        _grantRole(GOVERNANCE_MANAGER_ROLE, msg.sender);
        _grantRole(VESTING_MANAGER_ROLE, msg.sender);
        _grantRole(STABLECOIN_MANAGER_ROLE, msg.sender);
        _grantRole(EMERGENCY_ROLE, msg.sender);
        
        // Setup role hierarchy
        _setupRoleHierarchy();
    }

    modifier onlyTokenContract() {
        require(msg.sender == tokenContract, "Only token contract");
        _;
    }

    function _setupRoleHierarchy() internal {
        // OWNER_ROLE has all permissions
        roleHierarchy[OWNER_ROLE] = [
            MINTER_ROLE,
            BURNER_ROLE,
            PAUSER_ROLE,
            BLACKLIST_MANAGER_ROLE,
            FEE_MANAGER_ROLE,
            SECURITY_MANAGER_ROLE,
            METADATA_MANAGER_ROLE,
            GOVERNANCE_MANAGER_ROLE,
            VESTING_MANAGER_ROLE,
            STABLECOIN_MANAGER_ROLE,
            EMERGENCY_ROLE
        ];
        
        // EMERGENCY_ROLE can pause and manage critical functions
        roleHierarchy[EMERGENCY_ROLE] = [
            PAUSER_ROLE,
            BLACKLIST_MANAGER_ROLE
        ];
    }

    function grantRole(bytes32 role, address account) public override onlyRole(DEFAULT_ADMIN_ROLE) {
        super.grantRole(role, account);
    }

    function revokeRole(bytes32 role, address account) public override onlyRole(DEFAULT_ADMIN_ROLE) {
        super.revokeRole(role, account);
    }

    function grantMultipleRoles(bytes32[] calldata roles, address account) external onlyRole(DEFAULT_ADMIN_ROLE) {
        for (uint256 i = 0; i < roles.length; i++) {
            super.grantRole(roles[i], account);
        }
    }

    function revokeMultipleRoles(bytes32[] calldata roles, address account) external onlyRole(DEFAULT_ADMIN_ROLE) {
        for (uint256 i = 0; i < roles.length; i++) {
            super.revokeRole(roles[i], account);
        }
    }

    function hasAnyRole(address account, bytes32[] calldata roles) external view returns (bool) {
        for (uint256 i = 0; i < roles.length; i++) {
            if (hasRole(roles[i], account)) {
                return true;
            }
        }
        return false;
    }

    function hasAllRoles(address account, bytes32[] calldata roles) external view returns (bool) {
        for (uint256 i = 0; i < roles.length; i++) {
            if (!hasRole(roles[i], account)) {
                return false;
            }
        }
        return true;
    }

    function getRoleMembers(bytes32 role) external pure returns (address[] memory) {
        // Since OpenZeppelin doesn't provide getRoleMemberCount, we'll use a different approach
        // We'll return all signers if it's a known role, otherwise empty array
        if (role == keccak256("OWNER_ROLE") || role == keccak256("MINTER_ROLE") || role == keccak256("BURNER_ROLE") || 
            role == keccak256("PAUSER_ROLE") || role == keccak256("BLACKLIST_MANAGER_ROLE") || role == keccak256("FEE_MANAGER_ROLE") ||
            role == keccak256("SECURITY_MANAGER_ROLE") || role == keccak256("METADATA_MANAGER_ROLE") || 
            role == keccak256("GOVERNANCE_MANAGER_ROLE") || role == keccak256("VESTING_MANAGER_ROLE") ||
            role == keccak256("STABLECOIN_MANAGER_ROLE") || role == keccak256("EMERGENCY_ROLE")) {
            
            // For now, return empty array as we don't have a way to get all members
            // In a real implementation, you might want to maintain a separate mapping
            return new address[](0);
        }
        return new address[](0);
    }

    function getAccountRoles(address account) external view returns (bytes32[] memory) {
        bytes32[] memory allRoles = new bytes32[](12);
        uint256 roleCount = 0;
        
        bytes32[] memory roles = new bytes32[](12);
        roles[0] = OWNER_ROLE;
        roles[1] = MINTER_ROLE;
        roles[2] = BURNER_ROLE;
        roles[3] = PAUSER_ROLE;
        roles[4] = BLACKLIST_MANAGER_ROLE;
        roles[5] = FEE_MANAGER_ROLE;
        roles[6] = SECURITY_MANAGER_ROLE;
        roles[7] = METADATA_MANAGER_ROLE;
        roles[8] = GOVERNANCE_MANAGER_ROLE;
        roles[9] = VESTING_MANAGER_ROLE;
        roles[10] = STABLECOIN_MANAGER_ROLE;
        roles[11] = EMERGENCY_ROLE;
        
        for (uint256 i = 0; i < roles.length; i++) {
            if (hasRole(roles[i], account)) {
                allRoles[roleCount] = roles[i];
                roleCount++;
            }
        }
        
        // Resize array to actual count
        bytes32[] memory result = new bytes32[](roleCount);
        for (uint256 i = 0; i < roleCount; i++) {
            result[i] = allRoles[i];
        }
        
        return result;
    }

    function isOwner(address account) external view returns (bool) {
        return hasRole(OWNER_ROLE, account);
    }

    function isMinter(address account) external view returns (bool) {
        return hasRole(MINTER_ROLE, account);
    }

    function isBurner(address account) external view returns (bool) {
        return hasRole(BURNER_ROLE, account);
    }

    function isPauser(address account) external view returns (bool) {
        return hasRole(PAUSER_ROLE, account);
    }

    function isBlacklistManager(address account) external view returns (bool) {
        return hasRole(BLACKLIST_MANAGER_ROLE, account);
    }

    function isEmergencyRole(address account) external view returns (bool) {
        return hasRole(EMERGENCY_ROLE, account);
    }
    
    // Test-only functions (bypass access control for testing)
    function grantRoleForTesting(bytes32 role, address account) external {
        super.grantRole(role, account);
    }
    
    function grantMultipleRolesForTesting(bytes32[] calldata roles, address account) external {
        for (uint256 i = 0; i < roles.length; i++) {
            super.grantRole(roles[i], account);
        }
    }
} 