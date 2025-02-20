// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

import {Script, console} from "forge-std/Script.sol";
import {LendingPool} from "../src/LendingPool.sol";

contract LendingPoolScript is Script {
    LendingPool public lendingPool;

    function setUp() public {
        vm.createSelectFork(vm.rpcUrl("op_sepolia"));
    }

    function run() public {
        uint256 privateKey = vm.envUint("DEPLOYER_WALLET_PRIVATE_KEY");
        vm.startBroadcast(privateKey);
        lendingPool = new LendingPool(
            address(0xa7A93C5F0691a5582BAB12C0dE7081C499aECE7f),
            address(0xA61Eb0D33B5d69DC0D0CE25058785796296b1FBd),
            address(0x9eF28B341CAD6D916d13325D85E803e245d88fB5),
            700000000000000000
        );
        vm.stopBroadcast();
    }
}
