// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/access/AccessControl.sol";

abstract contract AccessManager is AccessControl {
    address public governanceExecutor;
    address public multisig;
    address public timelock;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    event GovernanceExecutorUpdated(address indexed oldExecutor, address indexed newExecutor);
    event MultisigUpdated(address indexed oldMultisig, address indexed newMultisig);
    event TimelockUpdated(address indexed oldTimelock, address indexed newTimelock);

    modifier onlyGovernance() {
        require(msg.sender == governanceExecutor, "Not governance executor");
        _;
    }

    modifier onlyMultisig() {
        require(msg.sender == multisig, "Not multisig");
        _;
    }

    modifier onlyTimelock() {
        require(msg.sender == timelock, "Not timelock");
        _;
    }

    function setGovernanceExecutor(address executor) external virtual onlyRole(DEFAULT_ADMIN_ROLE) {
        require(executor != address(0), "Invalid address");
        address oldExecutor = governanceExecutor;
        governanceExecutor = executor;
        emit GovernanceExecutorUpdated(oldExecutor, executor);
    }

    function setMultisig(address _multi) external virtual onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_multi != address(0), "Invalid address");
        address oldMultisig = multisig;
        multisig = _multi;
        emit MultisigUpdated(oldMultisig, _multi);
    }

    function setTimelock(address _timelock) external virtual onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_timelock != address(0), "Invalid address");
        address oldTimelock = timelock;
        timelock = _timelock;
        emit TimelockUpdated(oldTimelock, _timelock);
    }

    function getAccessInfo() external view virtual returns (
        address governance,
        address multisig_,
        address timelock_
    ) {
        return (governanceExecutor, multisig, timelock);
    }
}