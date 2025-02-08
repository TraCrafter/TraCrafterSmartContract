// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {LendingPool} from "./LendingPool.sol";

contract LendingPoolFactory {
    // collateral, borrow
    function createLendingPool(address LendingPoolToken1, address LendingPoolToken2) public returns (address) {
        LendingPool lendingPool = new LendingPool(LendingPoolToken1, LendingPoolToken2);
        return address(lendingPool);
    }
}
