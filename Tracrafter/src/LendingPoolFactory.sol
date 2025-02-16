// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {LendingPool} from "./LendingPool.sol";

contract LendingPoolFactory {
    event CreateLendingPool(
        address creator, address lendingPool, address token1, address token2, address oracle, uint256 LTV
    );

    address public oracle = 0x6E87c01682E547Bf69c73B5F0A1b4aAAE91A1EE1;
    // collateral, borrow
    // oracle statis(?)
    // cuman owner yang bisa atur dan pasang address nya

    function createLendingPool(address LendingPoolToken1, address LendingPoolToken2, uint256 LTV)
        public
        returns (address)
    {
        LendingPool lendingPool = new LendingPool(LendingPoolToken1, LendingPoolToken2, oracle, LTV);

        emit CreateLendingPool(msg.sender, address(lendingPool), LendingPoolToken1, LendingPoolToken2, oracle, LTV);
        return address(lendingPool);
    }
}
