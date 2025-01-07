# Governance Voting with NTT

## Introduction

This repository provides a framework for decentralized governance voting using a staking mechanism. It utilizes an ERC20 token deployed across multiple chains and integrates Wormhole's NTT (Native Token Transfers) for cross-chain functionality. The governance contract manages proposals and voting, while the staking contract handles token locking and vote recording.

This guide outlines the steps for deploying the contracts, testing the voting process, and interacting with the deployed contracts on the Sepolia testnet.

## Prerequisites
Before proceeding, ensure you have the following:

 - Forge installed
 - An ERC20 token deployed on the respective chains
 - NTT (Native Token Transfers) deployed for those ERC20 tokens using the Wormhole Protocol
 - Funded wallets with testnet ETH for gas fees
 - `.env` file containing

## Contract Deployment

1. Deploy Governance Contract

   Deploy the governance contract using the following command:
   
   ```bash
   forge script script/DeployGovernanceVoting.s.sol \
       --rpc-url https://ethereum-sepolia-rpc.publicnode.com \
       --private-key <PRIVATE_KEY> \
       --broadcast
   ```
   
   Post-deployment:
   
    - Add the governance contract address to the `.env` file as GOVERNANCE_CONTRACT_ADDRESS
    - Add the token contract address (ERC20) to the `.env` file as TOKEN_ADDRESS

2. Deploy Staking Contract

   Deploy the staking contract using the following command:
   
   ```bash
   forge script script/DeployStakingContract.s.sol \
       --rpc-url https://ethereum-sepolia-rpc.publicnode.com \
       --private-key <PRIVATE_KEY> \
       --broadcast
   ```
   
   Post-deployment:
   
    - Add the staking contract address to the .env file as STAKING_CONTRACT_ADDRESS

3. Update Governance Contract with Staking Address

   Link the staking contract to the governance contract:
   
   ```bash
   forge script script/UpdateGovernanceWithStaking.s.sol \
       --rpc-url https://ethereum-sepolia-rpc.publicnode.com \
       --private-key <PRIVATE_KEY> \
       --broadcast
   ```

## Testing

### Create a Proposal

Create a new proposal with a 5-minute expiry and proposal ID as 1:

```bash
cast send <GOVERNANCE_CONTRACT_ADDRESS> \
    "addProposal(uint256,string,uint256)" \
    1 "Proposal to test voting" $(($(date +%s) + 300)) \
    --rpc-url https://ethereum-sepolia-rpc.publicnode.com \
    --private-key <PRIVATE_KEY>
```

### Set Allowance

Ensure the staking contract has permission to transfer tokens on behalf of the voter:

1. Check the current allowance:

   ```bash
   cast call <TOKEN_ADDRESS> \
       "allowance(address,address)(uint256)" \
       <VOTER_ADDRESS> <STAKING_CONTRACT_ADDRESS> \
       --rpc-url https://ethereum-sepolia-rpc.publicnode.com
   ```

2. If the result is 0, set the allowance:

   ```bash
   cast send <TOKEN_ADDRESS> \
       "approve(address,uint256)" \
       <STAKING_CONTRACT_ADDRESS> 10000 \
       --rpc-url https://ethereum-sepolia-rpc.publicnode.com \
       --private-key <PRIVATE_KEY>
   ```

### Vote on the Proposal

Cast your vote (e.g., voting "Yes" with 1 token):

```bash
cast send <STAKING_CONTRACT_ADDRESS> \
    "vote(uint256,bool,uint256)" \
    1 true 1000000000000000000 \
    --rpc-url https://ethereum-sepolia-rpc.publicnode.com \
    --private-key <PRIVATE_KEY>
```

### Verify Proposal Details

Check the details of a specific proposal:

```bash
cast call <GOVERNANCE_CONTRACT_ADDRESS> \
    "getProposalDetails(uint256)" 1 \
    --rpc-url https://ethereum-sepolia-rpc.publicnode.com
```

Decode the details:

```bash
cast --abi-decode "getProposalDetails()(string,uint256,uint256,uint256)" <ENCODED_DETAILS>
```

Retrieve all proposal IDs:

```bash
cast call <GOVERNANCE_CONTRACT_ADDRESS \
    "getProposals()(uint256[])" \
    --rpc-url https://ethereum-sepolia-rpc.publicnode.com
```

### Withdraw Locked Tokens

Withdraw tokens locked during voting once the proposal expires:

```bash
cast send <STAKING_CONTRACT_ADDRESS> \
    "withdrawTokens(uint256)" \
    1 \
    --rpc-url https://ethereum-sepolia-rpc.publicnode.com \
    --private-key <PRIVATE_KEY>
```

## Additional Notes

 - This guide is tailored for the Sepolia Testnet. Adjust RPC URLs and environment variables if deploying on another network
 - Ensure the ERC20 token supports cross-chain transfers via Wormhole's NTT technology
