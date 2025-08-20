// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

interface IGovernanceManager {
    function setGovernanceExecutor(address executor) external;
    function setMultisig(address _multisig) external;
    function setTimelock(address _timelock) external;
    function setMinDelay(uint256 _minDelay) external;
    function createProposal(string calldata proposalDescription) external returns (uint256);
    function vote(uint256 proposalId, bool support) external;
    function executeProposal(uint256 proposalId) external;
    function cancelProposal(uint256 proposalId) external;
    function getProposal(uint256 proposalId) external view returns (uint256, address, string memory, uint256, uint256, uint256, uint256, bool, bool);
    function hasVoted(uint256 proposalId, address voter) external view returns (bool);
    function getVote(uint256 proposalId, address voter) external view returns (bool support);
} 