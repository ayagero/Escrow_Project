## ESCROW PROJECT

A simple escrow smart contract built with Solidity and tested using Foundry.

## Setup
1. Install Foundry: `curl -L https://foundry.paradigm.xyz | bash`
2. Compile: `forge build`
3. Run tests: `forge test`

## Files
- `src/Escrow.sol`: Escrow smart contract
- `test/Escrow.t.sol`: Unit and fuzz tests

## Features
- Buyer deposits ETH
- Arbiter releases funds to seller or refunds to buyer
- State management and access control
