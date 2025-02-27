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
            0xF47E3c53CE1259fEF635Ca319bd929Fd22Da1972, // collateral
            0x58E50D45A7Bec0aa0079b67B756FEE3CD8b21D3C, // borrow
            0xB4B02595698b7f5dce44ad3a7F300454932835DE,
            700000000000000000
        );
        vm.stopBroadcast();
    }
}
