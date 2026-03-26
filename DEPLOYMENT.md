# PayNode Protocol Contract Deployment Guide

This document provides standardized deployment commands for the PayNode Protocol.

## 🗂️ Deployment Constants
- **Compiler Version:** v0.8.20
- **Optimizer:** Enabled (200 runs)
- **Protocol Treasury:** `0x598bF63F5449876efafa7b36b77Deb2070621C0E`

---
## 🧪 1. Base Sepolia (Testnet)
Deploy using the specialized deployment script for the testnet.

- **Current v1.4 Address:** `0x24cD8b68aaC209217ff5a6ef1Bf55a59f2c8Ca6F`

```bash
cd packages/contracts && \
...
forge script script/DeploySepolia.s.sol:DeploySepolia \
  --rpc-url https://sepolia.base.org \
  --private-key <YOUR_PRIVATE_KEY> \
  --broadcast \
  -vvvv
```
### 🧪 1.1 Deploying Mock USDC (Testnet Only)
To test M2M payments with USDC on Base Sepolia, you can deploy a mock token for sandbox testing.

- **Mock USDC Address:** `<NEWLY_DEPLOYED_ADDRESS>` (Base Sepolia)

```bash
cd packages/contracts && \
forge script script/DeployMockUSDC.s.sol:DeployMockUSDC \
  --rpc-url https://sepolia.base.org \
  --private-key <YOUR_PRIVATE_KEY> \
  --broadcast \
  -vvvv
```
*Tip: After deployment, verify the contract on Basescan to enable easy `mint` calls via the web UI:*
```bash
forge verify-contract <DEPLOYED_ADDRESS> src/MockUSDC.sol:MockUSDC --rpc-url https://sepolia.base.org
```

---

## 🚀 2. Base Mainnet (Production)
Deploy using the specialized deployment script for the production environment.

```bash
cd packages/contracts && \
forge script script/DeployPOM.s.sol:DeployPOM \
  --rpc-url https://mainnet.base.org \
  --private-key <YOUR_PRIVATE_KEY> \
  --broadcast \
  -vvvv
```

---

## 📝 3. Post-Deployment Checklist

1. **Verify on Basescan:**
   - After deployment, note the `PayNodeRouter Deployed to:` address in the console output.
   - Go to [Basescan](https://basescan.org/) and search for the address.
   - Click "Contract" -> "Verify and Publish".
   - Use `Solidity (Single File)` mode. If you need a flattened file, run:
     ```bash
     forge flatten src/PayNodeRouter.sol > Flattened.sol
     ```

2. **Update & Sync Ecosystem Config:**
   After deployment, update the `ROUTER_ADDRESS` and `USDC_ADDRESS` (Sandbox) in each sub-package. 
   
   **Option A: Manual Update (Legacy Locations)**
   Ensure the following locations are updated if necessary:
   - `packages/sdk-js/src/index.ts`
   - `packages/sdk-python/paynode_sdk/client.py`
   - `apps/paynode-web/.env` (`NEXT_PUBLIC_PAYNODE_ROUTER_ADDRESS`)

   **Option B: Automated Sync (Recommended)**
   The project now uses a central `paynode-config.json`. To sync new addresses across the Web app and SDKs automatically:
   - Update `router` and `tokens.USDC` entries in `paynode-config.json`.
   - Run the sync script from the project root:
     ```bash
     python3 scripts/sync-config.py
     ```

3. **Transfer Ownership (Optional):**
   If deploying with a hot wallet, consider transferring ownership to a multisig (Gnosis Safe) using `transferOwnership`.
