# Bitcoin-Backed Stablecoin System

A robust, decentralized stablecoin system implemented in Clarity, featuring Bitcoin collateralization, dynamic liquidation mechanisms, and comprehensive risk management.

## Overview

This smart contract implements a decentralized stablecoin system where users can deposit Bitcoin as collateral to mint stablecoins. The system maintains stability through overcollateralization and includes sophisticated mechanisms for liquidation, collateral management, and debt handling.

### Key Features

- **Bitcoin Collateralization**: Users can deposit BTC as collateral
- **Overcollateralization**: Minimum 150% collateralization ratio required
- **Liquidation Mechanism**: Automatic liquidation at 120% ratio
- **Price Oracle Integration**: Real-time BTC price feeds with validity checks
- **Risk Management**: Deposit limits and price validity periods
- **Transparent Operations**: Full visibility of system parameters and user positions

## System Parameters

- Minimum Collateralization Ratio: 150%
- Liquidation Threshold: 120%
- Minimum Deposit: 0.01 BTC
- Maximum Deposit: 10,000 BTC
- Price Validity Period: 144 blocks
- Maximum BTC Price: 1,000,000,000 (safety limit)

## Core Functions

### User Operations

1. **Deposit Collateral**

   ```clarity
   (deposit-collateral (amount uint))
   ```

   - Deposit BTC as collateral
   - Requires amount > MIN-DEPOSIT

2. **Mint Stablecoins**

   ```clarity
   (mint-stablecoin (amount uint))
   ```

   - Mint stablecoins against deposited collateral
   - Maintains minimum collateralization ratio

3. **Repay Debt**

   ```clarity
   (repay-stablecoin (amount uint))
   ```

   - Repay outstanding stablecoin debt
   - Reduces total supply

4. **Withdraw Collateral**
   ```clarity
   (withdraw-collateral (amount uint))
   ```
   - Withdraw excess collateral
   - Ensures position remains properly collateralized

### System Operations

1. **Liquidation**

   ```clarity
   (liquidate-position (user principal))
   ```

   - Liquidate undercollateralized positions
   - Triggered when ratio falls below 120%

2. **Price Updates**
   ```clarity
   (set-price (new-price uint))
   ```
   - Update BTC price (oracle only)
   - Includes freshness checks

## Installation

1. Clone the repository
2. Deploy using Clarinet or your preferred Stacks deployment tool
3. Initialize price oracle and system parameters

## Usage

### Creating a Position

```clarity
;; Deposit collateral
(contract-call? .stablecoin deposit-collateral u1000000)

;; Mint stablecoins
(contract-call? .stablecoin mint-stablecoin u500000)
```

### Managing Positions

```clarity
;; Check position health
(contract-call? .stablecoin get-collateral-ratio tx-sender)

;; Repay debt
(contract-call? .stablecoin repay-stablecoin u100000)
```

## Security Considerations

- Price oracle manipulation protection
- Minimum deposit requirements
- Maximum deposit limits
- Collateralization safety margins
- Price validity checks

## Contributing

Please read [CONTRIBUTING.md](CONTRIBUTING.md) for details on our code of conduct and the process for submitting pull requests.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Security

For security concerns, please review our [SECURITY.md](SECURITY.md) file.
