// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/access/AccessControl.sol";

contract GovernanceManager is AccessControl {
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant EXECUTOR_ROLE = keccak256("EXECUTOR_ROLE");
    
    address public tokenContract;
    
    address public governanceExecutor;
    address public multisig;
    address public timelock;
    
    uint256 public proposalCount;
    uint256 public minDelay = 24 hours;
    
    struct Proposal {
        uint256 id;
        address proposer;
        string description;
        uint256 forVotes;
        uint256 againstVotes;
        uint256 startTime;
        uint256 endTime;
        bool executed;
        bool canceled;
        mapping(address => bool) hasVoted;
        mapping(address => bool) support;
    }
    
    mapping(uint256 => Proposal) public proposals;
    
    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, string description);
    event ProposalVoted(uint256 indexed proposalId, address indexed voter, bool support, uint256 weight);
    event ProposalExecuted(uint256 indexed proposalId);
    event ProposalCanceled(uint256 indexed proposalId);
    event GovernanceUpdated(address executor, address multisig, address timelock);

    constructor(address _tokenContract) {
        tokenContract = _tokenContract;
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);
        _grantRole(EXECUTOR_ROLE, msg.sender);
        
        governanceExecutor = msg.sender;
        multisig = msg.sender;
        timelock = msg.sender;
    }

    modifier onlyTokenContract() {
        require(msg.sender == tokenContract, "Only token contract");
        _;
    }

    function setGovernanceExecutor(address executor) external onlyRole(ADMIN_ROLE) {
        require(executor != address(0), "Invalid address");
        governanceExecutor = executor;
        emit GovernanceUpdated(executor, multisig, timelock);
    }

    function setMultisig(address _multisig) external onlyRole(ADMIN_ROLE) {
        require(_multisig != address(0), "Invalid address");
        multisig = _multisig;
        emit GovernanceUpdated(governanceExecutor, _multisig, timelock);
    }

    function setTimelock(address _timelock) external onlyRole(ADMIN_ROLE) {
        require(_timelock != address(0), "Invalid address");
        timelock = _timelock;
        emit GovernanceUpdated(governanceExecutor, multisig, _timelock);
    }

    function setMinDelay(uint256 _minDelay) external onlyRole(ADMIN_ROLE) {
        minDelay = _minDelay;
    }

    function createProposal(string calldata proposalDescription) external returns (uint256) {
        require(bytes(proposalDescription).length > 0, "Empty description");
        
        proposalCount++;
        uint256 proposalId = proposalCount;
        
        Proposal storage proposal = proposals[proposalId];
        proposal.id = proposalId;
        proposal.proposer = msg.sender;
        proposal.description = proposalDescription;
        proposal.startTime = block.timestamp;
        proposal.endTime = block.timestamp + minDelay;
        
        emit ProposalCreated(proposalId, msg.sender, proposalDescription);
        return proposalId;
    }

    function vote(uint256 proposalId, bool support) external {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.id == proposalId, "Proposal does not exist");
        require(block.timestamp <= proposal.endTime, "Voting period ended");
        require(!proposal.hasVoted[msg.sender], "Already voted");
        require(!proposal.executed && !proposal.canceled, "Proposal not active");
        
        proposal.hasVoted[msg.sender] = true;
        proposal.support[msg.sender] = support;
        
        // In a real implementation, you would get voting power from token contract
        uint256 weight = 1; // Simplified for this example
        
        if (support) {
            proposal.forVotes += weight;
        } else {
            proposal.againstVotes += weight;
        }
        
        emit ProposalVoted(proposalId, msg.sender, support, weight);
    }

    function executeProposal(uint256 proposalId) external onlyRole(EXECUTOR_ROLE) {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.id == proposalId, "Proposal does not exist");
        require(block.timestamp > proposal.endTime, "Voting period not ended");
        require(!proposal.executed, "Already executed");
        require(!proposal.canceled, "Proposal canceled");
        require(proposal.forVotes > proposal.againstVotes, "Proposal not passed");
        
        proposal.executed = true;
        emit ProposalExecuted(proposalId);
    }

    function cancelProposal(uint256 proposalId) external onlyRole(ADMIN_ROLE) {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.id == proposalId, "Proposal does not exist");
        require(!proposal.executed, "Already executed");
        require(!proposal.canceled, "Already canceled");
        
        proposal.canceled = true;
        emit ProposalCanceled(proposalId);
    }

    function getProposal(uint256 proposalId) external view returns (
        uint256 id,
        address proposer,
        string memory description,
        uint256 forVotes,
        uint256 againstVotes,
        uint256 startTime,
        uint256 endTime,
        bool executed,
        bool canceled
    ) {
        Proposal storage proposal = proposals[proposalId];
        return (
            proposal.id,
            proposal.proposer,
            proposal.description,
            proposal.forVotes,
            proposal.againstVotes,
            proposal.startTime,
            proposal.endTime,
            proposal.executed,
            proposal.canceled
        );
    }

    function hasVoted(uint256 proposalId, address voter) external view returns (bool) {
        return proposals[proposalId].hasVoted[voter];
    }

    function getVote(uint256 proposalId, address voter) external view returns (bool support) {
        return proposals[proposalId].support[voter];
    }
}