// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

import {Script, console} from "forge-std/Script.sol";
import {Position} from "../src/Position.sol";

contract PositionScript is Script {
    Position public position;

    function setUp() public {
        string memory rpcUrl = vm.envString("MANTA_SEPOLIA_RPC_URL");
        vm.createSelectFork(rpcUrl);
    }

    function run() public {
        uint256 privateKey = vm.envUint("DEPLOYER_WALLET_PRIVATE_KEY");
        vm.startBroadcast(privateKey);
        position = new Position(
            address(0xa7A93C5F0691a5582BAB12C0dE7081C499aECE7f), address(0xA61Eb0D33B5d69DC0D0CE25058785796296b1FBd)
        );
        vm.stopBroadcast();
    }
}
