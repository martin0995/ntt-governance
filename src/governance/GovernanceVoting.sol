// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract GovernanceVoting is Ownable {
    using Strings for uint256;

    struct Proposal {
        string description; // A short description of the proposal
        uint256 yesVotes; // Total "Yes" votes
        uint256 noVotes; // Total "No" votes
        uint256 expiryTimestamp; // Expiry time for the proposal
    }

    // Mapping to store proposal details
    mapping(uint256 => Proposal) public proposals;
    uint256[] public proposalIds;

    // Address of the authorized staking contract
    address public stakingContract;

    // Events for proposal lifecycle
    event ProposalCreated(uint256 indexed proposalId, string description, uint256 expiryTimestamp);
    event VoteRecorded(uint256 indexed proposalId, address indexed voter, bool voteYes, uint256 amount);

    // --- Constructor ---
    constructor() Ownable(msg.sender) {
        // `Ownable` automatically sets `msg.sender` as the owner
    }

    // --- Access Control ---
    /**
     * @dev Set the Staking contract address (onlyOwner).
     * @param _stakingContract The address of the Staking contract.
     */
    function setStakingContract(address _stakingContract) external onlyOwner {
        require(_stakingContract != address(0), "Invalid Staking contract address");
        stakingContract = _stakingContract;
    }

    // --- Proposal Management ---
    /**
     * @dev Add a new proposal (onlyOwner).
     * @param proposalId The unique ID for the proposal.
     * @param description The description of the proposal.
     * @param expiryTimestamp The expiration time for the proposal (in seconds since epoch).
     */
    function addProposal(uint256 proposalId, string memory description, uint256 expiryTimestamp) external onlyOwner {
        require(bytes(proposals[proposalId].description).length == 0, "Proposal already exists");
        require(block.timestamp < expiryTimestamp, "Expiry must be in the future");

        proposals[proposalId] =
            Proposal({description: description, yesVotes: 0, noVotes: 0, expiryTimestamp: expiryTimestamp});

        // Add the proposalId to the proposalIds array
        proposalIds.push(proposalId);

        emit ProposalCreated(proposalId, description, expiryTimestamp);
    }

    // --- Voting Logic ---
    /**
     * @dev Record a vote for a proposal (only callable by Staking contract).
     * @param proposalId The ID of the proposal to vote on.
     * @param voteYes True for a "Yes" vote, false for a "No" vote.
     * @param amount The amount of tokens associated with the vote.
     * @param voter The address of the voter (passed by the Staking contract).
     */
    function recordVote(uint256 proposalId, bool voteYes, uint256 amount, address voter) external {
        require(msg.sender == stakingContract, "Unauthorized caller");

        Proposal storage proposal = proposals[proposalId];
        require(bytes(proposal.description).length > 0, "Proposal does not exist");
        require(block.timestamp <= proposal.expiryTimestamp, "Proposal has expired");

        if (voteYes) {
            proposal.yesVotes += amount;
        } else {
            proposal.noVotes += amount;
        }

        emit VoteRecorded(proposalId, voter, voteYes, amount);
    }

    // --- Proposal Details ---
    function getProposalDetails(uint256 proposalId)
        external
        view
        returns (string memory description, uint256 yesVotes, uint256 noVotes, bool isExpired)
    {
        Proposal storage proposal = proposals[proposalId];
        require(bytes(proposal.description).length > 0, "Proposal does not exist");

        return (proposal.description, proposal.yesVotes, proposal.noVotes, block.timestamp > proposal.expiryTimestamp);
    }

    // Returns an array of all proposal IDs
    function getProposals() external view returns (uint256[] memory) {
        return proposalIds;
    }
}
