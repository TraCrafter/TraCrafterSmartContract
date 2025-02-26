// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

import {Script, console} from "forge-std/Script.sol";
import {LendingPool} from "../src/LendingPool.sol";

contract LendingPoolScript is Script {
    LendingPool public lendingPool;

    function setUp() public {
        vm.createSelectFork(vm.rpcUrl("rise_sepolia"));
    }

    function run() public {
        uint256 privateKey = vm.envUint("DEPLOYER_WALLET_PRIVATE_KEY");
        vm.startBroadcast(privateKey);
        lendingPool = new LendingPool(
            address(0x3A6c69259bC97E0912C7a678ca5331A93d2bfA46),
            address(0x373e1981F97607B4073Ee8bB23e3810CdAAAD1f8),
            address(0xB4B02595698b7f5dce44ad3a7F300454932835DE),
            700000000000000000
        );
        vm.stopBroadcast();
    }
}
