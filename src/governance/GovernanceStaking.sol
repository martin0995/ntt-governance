// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

interface IGovernanceVoting {
    function recordVote(uint256 proposalId, bool voteYes, uint256 amount, address voter) external;
    function getProposalDetails(uint256 proposalId) external view returns (
        string memory description,
        uint256 yesVotes,
        uint256 noVotes,
        bool isExpired
    );
}

contract StakingContract is Ownable {
    using EnumerableSet for EnumerableSet.UintSet;

    IERC20 public stakingToken;
    address public governanceContract;

    struct LockedVote {
        uint256 amount;
        bool hasVoted;
    }

    // Mapping of voter -> proposalId -> LockedVote
    mapping(address => mapping(uint256 => LockedVote)) public lockedVotes;

    // Track proposals voted on by each voter (for duplicate prevention)
    mapping(address => EnumerableSet.UintSet) private voterProposals;

    event TokensLocked(address indexed voter, uint256 proposalId, uint256 amount, bool voteYes);
    event TokensWithdrawn(address indexed voter, uint256 proposalId, uint256 amount);

    // General log messages
    event Log(string message);
    event LogAddress(string message, address value);
    event LogUint(string message, uint256 value);
    event LogBool(string message, bool value);

    constructor(address _stakingToken, address _governanceContract) {
        require(_stakingToken != address(0), "Invalid staking token address");
        require(_governanceContract != address(0), "Invalid governance contract address");
        stakingToken = IERC20(_stakingToken);
        governanceContract = _governanceContract;
    }

    // --- Core Voting Logic ---
    function vote(uint256 proposalId, bool voteYes, uint256 amount) external {
        emit Log("Start: vote function called");

        require(governanceContract != address(0), "Governance contract not set");
        emit LogAddress("Governance contract address", governanceContract);

        require(amount > 0, "Cannot vote with zero tokens");
        emit LogUint("Amount to lock", amount);

        require(address(stakingToken) != address(0), "Invalid staking token");
        emit LogAddress("Staking token address", address(stakingToken));

        IGovernanceVoting governance = IGovernanceVoting(governanceContract);

        // Ensure the proposal exists and is active
        emit LogUint("Checking proposal ID", proposalId);
        (, , , bool isExpired) = governance.getProposalDetails(proposalId);
        require(!isExpired, "Proposal has expired");

        // Prevent double voting
        require(!voterProposals[msg.sender].contains(proposalId), "Already voted on this proposal");

        // Lock the tokens
        emit Log("Transferring tokens to the contract");
        stakingToken.transferFrom(msg.sender, address(this), amount);
        emit Log("Tokens transferred");

        lockedVotes[msg.sender][proposalId] = LockedVote(amount, true);
        voterProposals[msg.sender].add(proposalId);

        // Record the vote in the Governance contract
        governance.recordVote(proposalId, voteYes, amount, msg.sender);

        emit TokensLocked(msg.sender, proposalId, amount, voteYes);
        emit Log("End: vote completed successfully");
    }

    function withdrawTokens(uint256 proposalId) external {
        require(governanceContract != address(0), "Governance contract not set");

        // Check if the proposal has expired
        IGovernanceVoting governance = IGovernanceVoting(governanceContract);
        (, , , bool isExpired) = governance.getProposalDetails(proposalId);
        require(isExpired, "Proposal has not expired yet");

        // Retrieve the locked vote
        LockedVote storage lockedVote = lockedVotes[msg.sender][proposalId];
        require(lockedVote.hasVoted, "No tokens locked for this proposal");
        require(lockedVote.amount > 0, "No tokens to withdraw");

        // Unlock and transfer tokens back to the user
        uint256 amountToWithdraw = lockedVote.amount;
        lockedVote.amount = 0; // Reset the locked amount to prevent re-entry
        stakingToken.transfer(msg.sender, amountToWithdraw);

        emit TokensWithdrawn(msg.sender, proposalId, amountToWithdraw);
    }


    // --- Helper Functions ---
    function getLockedTokens(address voter, uint256 proposalId) external view returns (uint256) {
        return lockedVotes[voter][proposalId].amount;
    }

    function hasVoted(address voter, uint256 proposalId) external view returns (bool) {
        return voterProposals[voter].contains(proposalId);
    }
}
