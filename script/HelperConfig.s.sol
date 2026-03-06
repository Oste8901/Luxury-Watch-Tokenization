// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Script} from "forge-std/Script.sol";

contract HelperConfig is Script {
    struct NetworkConfig {
        string initialBaseUri;
    }

    NetworkConfig public activeNetworkConfig;

    constructor() {
        if (block.chainid == 84532) { // Base Sepolia
            activeNetworkConfig = getBaseSepoliaConfig();
        } else {
            activeNetworkConfig = getAnvilConfig();
        }
    }

    function getBaseSepoliaConfig() public pure returns (NetworkConfig memory) {
        return NetworkConfig({
            initialBaseUri: "ipfs://bafybeicgoa2y4zhzqolx6ghciwmkiismqfpegqab7hbhndadnbneamkkwa/"
        });
    }

    function getAnvilConfig() public pure returns (NetworkConfig memory) {
        return NetworkConfig({
            initialBaseUri: "ipfs://test-cid/"
        });
    }
}