# Minimal Account Abstraction

*Part of the Cyfrin Updraft Advanced Foundry Course*

## What is Account Abstraction?

Traditional wallets (like MetaMask) are controlled by a single private key. Account Abstraction lets you create smart contract wallets with custom logic for:
- Multi-signature approval
- Social recovery
- Gasless transactions
- Custom authentication methods

## What's in this repo?

This repository contains two minimal implementations:

1. **Ethereum version** (`src/ethereum/MinimalAccount.sol`)
   - Uses ERC-4337 standard
   - Works with EntryPoint contracts
   - Sends UserOperations

2. **ZkSync version** (`src/zksync/ZkMinimalAccount.sol`) 
   - Uses ZkSync's native Account Abstraction
   - Different transaction flow than Ethereum
   - More integrated with the protocol

Both versions do the same thing: let you create a smart contract that can send transactions on behalf of an owner.

# Getting Started

## Requirements

- [Git](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git) 
- [Foundry](https://getfoundry.sh/)
- [Foundry-ZkSync](https://github.com/matter-labs/foundry-zksync) for ZkSync development

## Quick Setup

```bash
git clone git@github.com:ryanfro7/foundry-minimal-account-abstraction.git
cd foundry-minimal-account-abstraction
make install
```

## Testing

```bash
# Test Ethereum version
make test

# Test ZkSync version  
make zktest
```

## Deploying

### Ethereum

```bash
make deployEth
make sendUserOp
```

### ZkSync

First, set up your environment:
1. Copy `.env.example` to `.env`
2. Add your private key and password
3. Encrypt your key: `make encryptKey`
4. Delete the plaintext key from `.env`!

Then deploy:
```bash
make zkdeploy
make sendTx
```

# Understanding the Code

## Key Files

### Ethereum Implementation
- `src/ethereum/MinimalAccount.sol` - The main smart contract wallet
- `script/SendPackedUserOp.s.sol` - Script to send transactions
- `test/ethereum/MinimalAccountTest.t.sol` - Tests for the Ethereum version

### ZkSync Implementation  
- `src/zksync/ZkMinimalAccount.sol` - ZkSync version of the wallet
- `javascript-scripts/SendAATx.ts` - TypeScript script to send ZkSync transactions
- `test/zksync/ZkMinimalAccountTest.t.sol` - Tests for ZkSync version

## How to Customize This

Want to build your own Account Abstraction wallet? Here's where to start:

1. **Change the validation logic** in `validateUserOp()` or `validateTransaction()`
   - Add multi-sig requirements
   - Implement social recovery
   - Add spending limits

2. **Modify execution logic** in `execute()` 
   - Add transaction batching
   - Implement automatic payments
   - Add access controls

3. **Update the deployment scripts** to use your custom logic

## Common Use Cases

- **Multi-signature wallets**: Require multiple signatures for transactions
- **Social recovery**: Let friends help recover your wallet
- **Gasless transactions**: Let apps pay gas for users
- **Spending limits**: Set daily/monthly spending caps
- **Subscription payments**: Automatic recurring payments

Remember: This is educational code. Don't use it with real money without a security audit!