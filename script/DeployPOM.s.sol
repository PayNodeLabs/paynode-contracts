// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {PayNodeRouter} from "../src/PayNodeRouter.sol";

/**
 * @title DeployPOM (Production - Safe)
 * @notice Deploys ONLY the PayNodeRouter on Mainnet using CREATE2.
 * @dev Use with --private-key or --interactive flag.
 */
contract DeployPOM is Script {
    // --- 💎 The deterministic SALT 💎 ---
    bytes32 public constant SALT = 0x5061794e6f64655f50726f746f636f6c5f76315f47656e657369730000000000;

    function run() external {
        // treasury: The 1% protocol fee recipient
        address treasury = 0x598bF63F5449876efafa7b36b77Deb2070621C0E;

        // Use no-argument startBroadcast() to inherit the signer from CLI flags
        vm.startBroadcast();

        // Deploy PayNodeRouter using CREATE2
        PayNodeRouter router = new PayNodeRouter{salt: SALT}(treasury);

        console.log("----------------------------------------------");
        console.log("MAINNET DEPLOYMENT LOG");
        console.log("PayNodeRouter Address:", address(router));
        console.log("Protocol Treasury:", treasury);
        console.log("Deployer Address:", msg.sender);
        console.log("----------------------------------------------");

        vm.stopBroadcast();
    }
}
