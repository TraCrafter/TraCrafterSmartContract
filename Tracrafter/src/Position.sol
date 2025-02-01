// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {LendingPool} from "./LendingPool.sol";

contract Position {
    uint256 public supp1;

    address public collateral1;
    address public borrowAssets;
    address public owner;

    constructor(address _collateral1, address _borrow) {
        collateral1 = _collateral1;
        borrowAssets = _borrow;
        owner = msg.sender;
    }
}
