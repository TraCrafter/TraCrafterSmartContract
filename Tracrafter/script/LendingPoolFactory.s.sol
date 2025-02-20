// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

import {Script, console} from "forge-std/Script.sol";
import {LendingPoolFactory} from "../src/LendingPoolFactory.sol";

contract LendingPoolFactoryScript is Script {
    LendingPoolFactory public lendingPoolFactory;
    address public oracle = 0x6E87c01682E547Bf69c73B5F0A1b4aAAE91A1EE1;

    function setUp() public {
        vm.createSelectFork(vm.rpcUrl("manta_sepolia"));
    }

    function run() public {
        uint256 privateKey = vm.envUint("DEPLOYER_WALLET_PRIVATE_KEY");
        vm.startBroadcast(privateKey);

        lendingPoolFactory = new LendingPoolFactory(oracle);
        vm.stopBroadcast();
    }
}
