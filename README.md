# CeramicMarket Escrow Exchange

A decentralized marketplace for ceramic tiles with built-in escrow functionality on the Stacks blockchain.

## Overview

CeramicMarket provides a secure trading platform where buyers and sellers can transact ceramic tiles with automatic escrow protection, ensuring safe and trustless transactions.

## Features

- **Decentralized Listings**: Create and browse ceramic tile listings
- **Escrow Protection**: Automatic escrow holds funds until order completion
- **Multiple Tile Types**: Support for various ceramic tile categories
- **Platform Fees**: Built-in fee structure (2.5% platform fee)
- **Order Management**: Complete order lifecycle from listing to completion

## Contract Functions

### Public Functions

- `create-listing`: Create a new tile listing with price and quantity
- `place-order`: Place an order with automatic escrow deposit
- `complete-order`: Complete order and release escrow funds
- `cancel-order`: Cancel order and refund buyer

### Read-Only Functions

- `get-listing`: Retrieve listing details by ID
- `get-escrow`: Get escrow deposit information
- `get-platform-fee-rate`: Check current platform fee rate
- `get-next-listing-id`: Get next available listing ID

## Usage

```bash
# Create a listing
(contract-call? .ceramic-market-escrow create-listing "Porcelain Floor Tiles" u100 u50)

# Place an order
(contract-call? .ceramic-market-escrow place-order u1)

# Complete order (seller only)
(contract-call? .ceramic-market-escrow complete-order u1)
```
