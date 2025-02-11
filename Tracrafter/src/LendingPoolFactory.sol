// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {LendingPool} from "./LendingPool.sol";

contract LendingPoolFactory {
    // collateral, borrow
    // oracle statis(?)
    // cuman owner yang bisa atur dan pasang address nya
    function createLendingPool(address LendingPoolToken1, address LendingPoolToken2, address oracle, uint256 LTV) public returns (address) {
        LendingPool lendingPool = new LendingPool(LendingPoolToken1, LendingPoolToken2, oracle, LTV);
        return address(lendingPool);
    }
}
