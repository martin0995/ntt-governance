// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script, console2} from "forge-std/Script.sol";
import {StakingContract} from "../src/governance/GovernanceStaking.sol";

contract DeployStakingContract is Script {
    function run() public {
        vm.startBroadcast();

        // Replace with the GovernanceVoting address from Step 1
        address governanceVotingAddress = vm.envAddress("GOVERNANCE_ADDRESS");
        require(governanceVotingAddress != address(0), "Invalid GovernanceVoting address");

        // Replace with the token address
        address stakingTokenAddress = vm.envAddress("STAKING_TOKEN_ADDRESS");
        require(stakingTokenAddress != address(0), "Invalid staking token address");

        // Deploy StakingContract
        StakingContract stakingContract = new StakingContract(stakingTokenAddress, governanceVotingAddress);

        console2.log("StakingContract deployed at:", address(stakingContract));

        vm.stopBroadcast();
    }
}