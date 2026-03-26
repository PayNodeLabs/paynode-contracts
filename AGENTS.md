# AGENTS.MD — CONTRACTS

## OVERVIEW
Foundry-based smart contracts for the PayNode stateless payment router on Base L2.

## STRUCTURE
- `src/`: Core logic (`PayNodeRouter.sol`, `MockUSDC.sol`).
- `test/`: Unit, integration, and fuzz tests (`*.t.sol`).
- `script/`: Deployment and configuration scripts (`*.s.sol`).
- `lib/`: Forge standard library and OpenZeppelin dependencies.

## WHERE TO LOOK
- **Logic:** `src/PayNodeRouter.sol` contains the `pay()` and `payWithPermit()` entries.
- **Config:** `script/Config.s.sol` (auto-generated) holds protocol addresses and constants.
- **Tests:** `test/PayNodeRouter.t.sol` provides examples of permit signature generation.
- **Deployment:** `script/DeploySepolia.s.sol` for network-specific deployment logic.

## CONVENTIONS
- **Testing:** Use `vm.expectEmit` for all `PaymentReceived` events.
- **Permits:** Always test `payWithPermit` using `vm.sign` with known private keys.
- **Gas:** Monitor contract sizes with `forge build --sizes` during PRs.
- **Formatting:** Strict adherence to `forge fmt`.
- **Fuzzing:** Use `uint256 amount` fuzzing in tests to verify fee calculation at scale.

## ANTI-PATTERNS
- **No Storage:** Never add `SSTORE` operations to `PayNodeRouter`. Use events only.
- **No Hardcoding:** Do not hardcode addresses in `src/`. Use `script/Config.s.sol`.
- **Safe Transfer:** Never use `transfer()`. Use `SafeERC20` for all token movements.
- **Permit Safety:** Don't ignore the `deadline` parameter in permit functions.
