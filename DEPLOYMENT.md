# PayNode Protocol Contract Deployment Guide

This document provides standardized deployment commands for the PayNode Protocol.

## 🗂️ Deployment Constants
- **Compiler Version:** v0.8.20
- **Optimizer:** Enabled (200 runs)
- **Protocol Treasury:** `0x598bF63F5449876efafa7b36b77Deb2070621C0E`

---
## 🧪 1. Base Sepolia (Testnet)
Deploy using the specialized deployment script for the testnet.

- **Current v1.1 Address:** `0xB587Bc36aaCf65962eCd6Ba59e2DA76f2f575408`

```bash
cd packages/contracts && \
...
forge script script/DeploySepolia.s.sol:DeploySepolia \
  --rpc-url https://sepolia.base.org \
  --private-key <YOUR_PRIVATE_KEY> \
  --broadcast \
  -vvvv
```
*Note: If the official RPC is slow, use `https://base-sepolia-rpc.publicnode.com`.*

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

2. **Update Ecosystem Config:**
   Update the `ROUTER_ADDRESS` in the following locations:
   - `packages/sdk-js/src/index.ts`
   - `packages/sdk-python/paynode_sdk/client.py`
   - `apps/paynode-web/.env` (`NEXT_PUBLIC_PAYNODE_ROUTER_ADDRESS`)

3. **Transfer Ownership (Optional):**
   If deploying with a hot wallet, consider transferring ownership to a multisig (Gnosis Safe) using `transferOwnership`.
