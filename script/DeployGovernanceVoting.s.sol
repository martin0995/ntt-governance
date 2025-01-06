// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script, console2} from "forge-std/Script.sol";
import {GovernanceVoting} from "../src/governance/GovernanceVoting.sol";

contract DeployGovernanceVoting is Script {
    function run() public {
        vm.startBroadcast();

        // Deploy GovernanceVoting contract
        GovernanceVoting governanceVoting = new GovernanceVoting();

        console2.log("GovernanceVoting deployed at:", address(governanceVoting));

        vm.stopBroadcast();
    }
}