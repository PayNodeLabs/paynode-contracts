// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {PayNodeRouter} from "../src/PayNodeRouter.sol";

contract DeploySepolia is Script {
    function run() external {
        address treasury = 0x598bF63F5449876efafa7b36b77Deb2070621C0E;

        vm.startBroadcast();
        PayNodeRouter router = new PayNodeRouter(treasury);
        console.log("PayNodeRouter Deployed to:", address(router));
        vm.stopBroadcast();
    }
}
