// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {MockUSDC} from "../src/MockUSDC.sol";

/**
 * @title DeployMockUSDC
 * @notice Script for deploying MockUSDC to testnets.
 */
contract DeployMockUSDC is Script {
    function run() external {
        vm.startBroadcast();

        MockUSDC usdc = new MockUSDC();

        console.log("----------------------------------------------");
        console.log("Mock USDC Deployed to:", address(usdc));
        console.log("Name:", usdc.name());
        console.log("Symbol:", usdc.symbol());
        console.log("Initial Balance (Deployer):", usdc.balanceOf(msg.sender));
        console.log("----------------------------------------------");

        vm.stopBroadcast();
    }
}
