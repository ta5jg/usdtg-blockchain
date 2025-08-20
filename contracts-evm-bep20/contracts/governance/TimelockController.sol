// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Address.sol";

contract TimelockController is AccessControl {
    using Address for address;

    bytes32 public constant PROPOSER_ROLE = keccak256("PROPOSER_ROLE");
    bytes32 public constant EXECUTOR_ROLE = keccak256("EXECUTOR_ROLE");
    bytes32 public constant CANCELLER_ROLE = keccak256("CANCELLER_ROLE");

    uint256 public constant MIN_DELAY = 0;
    uint256 public constant MAX_DELAY = 30 days;

    mapping(bytes32 => uint256) private _timestamps;
    uint256 private _minDelay;

    event CallScheduled(
        bytes32 indexed id,
        uint256 indexed index,
        address target,
        uint256 value,
        bytes data,
        bytes32 predecessor,
        uint256 delay
    );

    event CallExecuted(
        bytes32 indexed id,
        uint256 indexed index,
        address target,
        uint256 value,
        bytes data
    );

    event Cancelled(bytes32 indexed id);

    event MinDelayChange(uint256 oldDuration, uint256 newDuration);

    modifier onlyRoleOrOpenRole(bytes32 role) {
        if (!hasRole(role, address(0))) {
            _checkRole(role, _msgSender());
        }
        _;
    }

    constructor(
        uint256 minDelay,
        address[] memory proposers,
        address[] memory executors,
        address admin
    ) {
        _setRoleAdmin(CANCELLER_ROLE, CANCELLER_ROLE);
        _setRoleAdmin(PROPOSER_ROLE, CANCELLER_ROLE);
        _setRoleAdmin(EXECUTOR_ROLE, CANCELLER_ROLE);

        if (admin != address(0)) {
            _setupRole(DEFAULT_ADMIN_ROLE, admin);
            _setupRole(CANCELLER_ROLE, admin);
        }

        for (uint256 i = 0; i < proposers.length; ++i) {
            _setupRole(PROPOSER_ROLE, proposers[i]);
        }

        for (uint256 i = 0; i < executors.length; ++i) {
            _setupRole(EXECUTOR_ROLE, executors[i]);
        }

        _minDelay = minDelay;
        emit MinDelayChange(0, minDelay);
    }

    function schedule(
        address target,
        uint256 value,
        bytes calldata data,
        bytes32 predecessor,
        bytes32 salt,
        uint256 delay
    ) public virtual onlyRole(PROPOSER_ROLE) {
        bytes32 id = hashOperation(target, value, data, predecessor, salt);
        _schedule(id, delay);
        emit CallScheduled(id, 0, target, value, data, predecessor, delay);
    }

    function execute(
        address target,
        uint256 value,
        bytes calldata data,
        bytes32 predecessor,
        bytes32 salt
    ) public payable virtual onlyRoleOrOpenRole(EXECUTOR_ROLE) {
        bytes32 id = hashOperation(target, value, data, predecessor, salt);
        _beforeCall(id, predecessor);
        _call(id, 0, target, value, data);
        _afterCall(id);
    }

    function cancel(bytes32 id) public virtual onlyRole(CANCELLER_ROLE) {
        _cancel(id);
    }

    function getMinDelay() public view virtual returns (uint256) {
        return _minDelay;
    }

    function hashOperation(
        address target,
        uint256 value,
        bytes calldata data,
        bytes32 predecessor,
        bytes32 salt
    ) public pure virtual returns (bytes32) {
        return keccak256(abi.encode(target, value, data, predecessor, salt));
    }

    function getTimestamp(bytes32 id) public view virtual returns (uint256) {
        return _timestamps[id];
    }

    function isOperation(bytes32 id) public view virtual returns (bool) {
        return getTimestamp(id) > 0;
    }

    function isOperationPending(bytes32 id) public view virtual returns (bool) {
        return isOperation(id) && !isOperationReady(id);
    }

    function isOperationReady(bytes32 id) public view virtual returns (bool) {
        uint256 timestamp = getTimestamp(id);
        return timestamp > 0 && timestamp <= block.timestamp;
    }

    function isOperationDone(bytes32 id) public view virtual returns (bool) {
        return getTimestamp(id) == 1;
    }

    function _schedule(bytes32 id, uint256 delay) private {
        require(!isOperation(id), "TimelockController: operation already scheduled");
        require(delay >= getMinDelay(), "TimelockController: insufficient delay");
        _timestamps[id] = block.timestamp + delay;
    }

    function _beforeCall(bytes32 id, bytes32 predecessor) private view {
        require(predecessor == bytes32(0) || isOperationDone(predecessor), "TimelockController: missing dependency");
        require(isOperationReady(id), "TimelockController: operation is not ready");
    }

    function _afterCall(bytes32 id) private {
        require(isOperationReady(id), "TimelockController: operation is not ready");
        _timestamps[id] = 1;
    }

    function _call(
        bytes32 id,
        uint256 index,
        address target,
        uint256 value,
        bytes calldata data
    ) private {
        (bool success, ) = target.call{value: value}(data);
        require(success, "TimelockController: underlying transaction reverted");

        emit CallExecuted(id, index, target, value, data);
    }

    function _cancel(bytes32 id) private {
        require(isOperation(id), "TimelockController: operation cannot be cancelled");
        delete _timestamps[id];

        emit Cancelled(id);
    }
} 