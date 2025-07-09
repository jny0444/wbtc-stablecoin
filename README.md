# wBTC Stablecoin

A decentralized stablecoin backed by Wrapped Bitcoin (wBTC) collateral, featuring overcollateralization and automated liquidations.

## 📋 Overview

This project implements a CDP (Collateralized Debt Position) stablecoin system where users can:

- Deposit wBTC as collateral
- Mint stablecoins at a 75% collateralization ratio
- Maintain healthy positions or face liquidation
- Earn liquidation bonuses by liquidating undercollateralized positions

## 🏗️ Architecture

### Core Contracts

- **StableEngine.sol** - Main protocol logic handling deposits, withdrawals, minting, and liquidations
- **StableCoin.sol** - ERC20 stablecoin token with minting/burning capabilities

### Key Features

- **Overcollateralization**: 133% minimum collateralization ratio (75% loan-to-value)
- **Liquidation System**: 10% liquidation bonus for liquidators
- **Price Feeds**: Chainlink oracle integration with staleness protection
- **Security**: Reentrancy protection, pause mechanism, and access controls
- **Events**: Comprehensive event logging for monitoring and frontend integration

## 🔧 Technical Specifications

### Collateralization

- **Collateral Factor**: 75% (users can borrow up to 75% of their collateral value)
- **Liquidation Threshold**: Health factor < 1.0
- **Liquidation Bonus**: 10% of collateral value

### Security Features

- Reentrancy protection on all external functions
- Emergency pause functionality
- Price feed staleness checks (1-hour threshold)
- Ownable access control for admin functions

### Price Feeds

- Uses Chainlink aggregators for wBTC/USD pricing
- Built-in staleness and validity checks
- Price precision handling with 18 decimal normalization

## 🚀 Getting Started

### Prerequisites

```bash
# Install Foundry
curl -L https://foundry.paradigm.xyz | bash
foundryup

# Clone the repository
git clone <repository-url>
cd wbtc-stablecoin
```

### Installation

```bash
# Install dependencies
forge install

# Build the project
forge build

# Run tests
forge test
```

### Deployment

```bash
# Deploy to local network
forge script script/Deploy.s.sol --rpc-url <RPC_URL> --private-key <PRIVATE_KEY>

# Verify contracts
forge verify-contract <CONTRACT_ADDRESS> <CONTRACT_NAME> --chain-id <CHAIN_ID>
```

## 📖 Usage

### For Users

#### Depositing Collateral and Minting Stablecoins

```solidity
// 1. Approve wBTC spending
wBTC.approve(stableEngineAddress, amount);

// 2. Deposit collateral and mint stablecoins
stableEngine.depositCollateral(amount);
```

#### Withdrawing Collateral

```solidity
// Withdraw collateral (burns corresponding stablecoins)
stableEngine.withdrawCollateral(amount);
```

#### Checking Account Status

```solidity
// Get health factor
uint256 healthFactor = stableEngine.getUserHealthFactor(userAddress);

// Get account information
(uint256 stableCoinMinted, uint256 collateralValue) =
    stableEngine.getAccountInformation(userAddress);
```

### For Liquidators

```solidity
// Liquidate undercollateralized position
stableEngine.liquidate(liquidateeAddress);
```

### For Admins

```solidity
// Emergency controls
stableEngine.pause();
stableEngine.unpause();
stableEngine.emergencyWithdraw(tokenAddress, amount);
```

## 🎯 Functions Reference

### Core Functions

| Function                      | Description                            | Access |
| ----------------------------- | -------------------------------------- | ------ |
| `depositCollateral(uint256)`  | Deposit wBTC and mint stablecoins      | Public |
| `withdrawCollateral(uint256)` | Withdraw wBTC and burn stablecoins     | Public |
| `liquidate(address)`          | Liquidate undercollateralized position | Public |

### View Functions

| Function                           | Return              | Description                 |
| ---------------------------------- | ------------------- | --------------------------- |
| `getUserHealthFactor(address)`     | `uint256`           | Get user's health factor    |
| `getCollateralValueInUSD(address)` | `uint256`           | Get USD value of collateral |
| `getCurrentwBTCPrice()`            | `uint256`           | Get current wBTC price      |
| `getAccountInformation(address)`   | `(uint256,uint256)` | Get complete account info   |

### Admin Functions

| Function                             | Description              | Access |
| ------------------------------------ | ------------------------ | ------ |
| `pause()`                            | Pause all operations     | Owner  |
| `unpause()`                          | Resume operations        | Owner  |
| `emergencyWithdraw(address,uint256)` | Emergency token recovery | Owner  |

## 📊 Events

```solidity
event CollateralDeposited(address indexed user, uint256 amount, uint256 stableCoinMinted);
event CollateralWithdrawn(address indexed user, uint256 amount, uint256 stableCoinBurned);
event Liquidated(address indexed liquidatee, address indexed liquidator, uint256 collateralAmount, uint256 bonus);
```

## 🧮 Economics

### Health Factor Calculation

```
Health Factor = (Collateral Value in USD × Precision) / (Stablecoin Debt × Precision)
```

### Liquidation Condition

A position becomes liquidatable when:

```
Health Factor < 1.0
```

### Liquidation Rewards

Liquidators receive:

```
Total Reward = Collateral + (Collateral × 10%)
```

## ⚠️ Risks and Considerations

### Smart Contract Risks

- Code bugs or vulnerabilities
- Oracle manipulation or failure
- Flash loan attacks

### Economic Risks

- wBTC price volatility
- Liquidation cascades during market stress
- Insufficient liquidator participation

### Operational Risks

- Admin key compromise
- Chainlink oracle downtime
- Network congestion affecting liquidations

## 🔒 Security

### Auditing

- [ ] Code review completed
- [ ] External audit performed
- [ ] Bug bounty program launched

### Best Practices

- ✅ Reentrancy protection
- ✅ Access controls
- ✅ Emergency pause mechanism
- ✅ Price feed validation
- ✅ Comprehensive event logging

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

**⚠️ DISCLAIMER**: This project is for educational purposes. Do not use in production without proper auditing and testing.
