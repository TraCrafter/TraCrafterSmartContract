// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

import {Script, console} from "forge-std/Script.sol";
import {Position} from "../src/Position.sol";

contract PositionScript is Script {
    Position public position;

    function setUp() public {
        vm.createSelectFork(vm.rpcUrl("op_sepolia"));
    }

    function run() public {
        uint256 privateKey = vm.envUint("DEPLOYER_WALLET_PRIVATE_KEY");
        vm.startBroadcast(privateKey);
        position = new Position(
            address(0x2581acd5925797CFbC1E4D4F7F7C0F84CCcDf874), address(0xeC5B45249298cD0b1c67122f0149E698EF0458BE)
        );
        vm.stopBroadcast();
    }
}
