// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script, console2} from "forge-std/Script.sol";
import {GovernanceVoting} from "../src/governance/GovernanceVoting.sol";

contract UpdateGovernanceWithStaking is Script {
    function run() public {
        vm.startBroadcast();

        // Replace with the GovernanceVoting address
        address governanceVotingAddress = vm.envAddress("GOVERNANCE_ADDRESS");
        require(governanceVotingAddress != address(0), "Invalid GovernanceVoting address");

        // Replace with the StakingContract address
        address stakingContractAddress = vm.envAddress("STAKING_CONTRACT_ADDRESS");
        require(stakingContractAddress != address(0), "Invalid StakingContract address");

        console2.log("Updating GovernanceVoting at:", governanceVotingAddress);
        console2.log("Setting StakingContract address to:", stakingContractAddress);

        // Update GovernanceVoting
        GovernanceVoting governanceVoting = GovernanceVoting(governanceVotingAddress);
        governanceVoting.setStakingContract(stakingContractAddress);

        console2.log("StakingContract address set in GovernanceVoting:", stakingContractAddress);

        vm.stopBroadcast();
    }
}
