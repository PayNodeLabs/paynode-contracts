// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {PayNodeRouter} from "../src/PayNodeRouter.sol";
import {Config} from "./Config.s.sol";

contract DeploySepolia is Script {
    function run() external {
        address treasury = Config.TREASURY;

        vm.startBroadcast();
        PayNodeRouter router = new PayNodeRouter(treasury);
        console.log("PayNodeRouter Deployed to:", address(router));
        vm.stopBroadcast();
    }
}
