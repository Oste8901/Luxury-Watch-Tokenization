// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Script} from "forge-std/Script.sol";
import {LuxuryWatch} from "../contracts/LuxuryWatch.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

contract DeployLuxuryWatch is Script {
    function run() external returns (LuxuryWatch) {
        HelperConfig helperConfig = new HelperConfig();
        (string memory initialUri) = helperConfig.activeNetworkConfig();

        vm.startBroadcast();
        LuxuryWatch watchContract = new LuxuryWatch();
        // Since your contract has a default URI, we update it to the config version
        watchContract.setBaseURI(initialUri);
        vm.stopBroadcast();

        return watchContract;
    }
}