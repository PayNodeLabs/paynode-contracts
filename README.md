# PayNode Smart Contracts

Solidity-based non-custodial M2M (Machine-to-Machine) payment routing contracts, designed to provide ultra-low latency and high-verifiability payment infrastructure for AI Agents.

## 📜 License

**Business Source License 1.1 (BSL-1.1)**
- Allows all non-commercial use and commercial use under specific conditions.
- Automatically transitions to **GPL-3.0-or-later** 2 years after publication.

## ⚡ Stateless Design and Gas Advantages

`PayNodeRouter` adopts a **Stateless** architectural design, which is intended to optimize Gas consumption in M2M scenarios to the extreme:

1. **Zero Storage (No SSTORE):** The contract does not maintain the settlement status of `orderId` internally. This means we do not need to record whether an order has been paid via storage variables on-chain.
2. **Event-driven:** All payment proofs are emitted through the `PaymentReceived` event.
   - `orderId` is defined as `indexed`, facilitating fast retrieval by SDKs/backends using Bloom Filters.
3. **Verification Cost Transfer:** The "authenticity" of the payment is verified by the SDK side through interaction with the RPC. This keeps the Gas consumption of a single payment to basic transfer operations + event emission (approximately 60k-80k Gas).
4. **Gas Comparison:** Compared to traditional custodial/order management contracts (which typically require 150k+ Gas), PayNode's execution cost on Base L2 is reduced by more than 50%.

## 🔄 `pay()` Core Function Logic

The `pay()` function is the primary entry point of the protocol, with the following execution flow:

1. **Input Parameter Validation:**
   - Ensure `merchant` and `token` addresses are valid.
   - `amount` must be greater than 0.
2. **Fee Calculation (Protocol Fee Split):**
   - The protocol currently sets a fixed fee of **1% (100 BPS)**.
   - `merchantAmount = amount * 99%`
   - `protocolFee = amount * 1%`
3. **Atomic Asset Transfer (SafeERC20):**
   - Use `IERC20.safeTransferFrom` to deduct assets from `msg.sender`.
   - Assets flow directly to the `merchant` address.
   - Fees flow directly to the `protocolTreasury` address.
4. **Log Emission (Emit Evidence):**
   - Emit `PaymentReceived(orderId, merchant, payer, token, amount, fee)`.
   - SDKs capture this event to confirm payment status.

## 🚀 Advanced Feature: `payWithPermit`

To completely eliminate the UX friction and multiple Gas consumptions brought by "Two-Step Approval" (Approve + Transfer) when AI Agents pay, the protocol supports EIP-2612 Permit. Agents only need to sign offline, and the SDK can complete all payment logic in a single transaction.

## 🛠️ Development Guide

Use the Foundry suite for testing and deployment:

```bash
# Compile
forge build

# Run full tests (including Fuzzing tests)
forge test -vvv

# Deploy to Base Sepolia
forge script script/Deploy.s.sol --rpc-url $BASE_RPC --broadcast
```
