// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {LendingPool} from "./LendingPool.sol";

contract Position {
    struct TokenOwner {
        address token;
        uint256 amount;
    }

    address public collateral1;
    address public borrowAssets;
    address public owner;

    TokenOwner[] public tokenOwner;

    constructor(address _collateral1, address _borrow) {
        collateral1 = _collateral1;
        borrowAssets = _borrow;
        owner = msg.sender;
    }

    function liquidate() public {}

    function swapToken(address _token, uint256 _amount) public {
        uint256 tokenOwnerLength = tokenOwner.length;

        if (tokenOwnerLength == 0) {
            tokenOwner.push(TokenOwner(_token, _amount));
        } else {
            for (uint256 i = 0; i < tokenOwnerLength; i++) {
                if (tokenOwner[i].token == _token) {
                    tokenOwner[i].amount += _amount;
                }
            }
        }
    }

    function getTokenOwnerLength() public view returns (uint256) {
        return tokenOwner.length;
    }

    function getTokenOwnerAddress(uint256 _index) public view returns (address) {
        return tokenOwner[_index].token;
    }

    function getTokenOwnerAmount(uint256 _index) public view returns (uint256) {
        return tokenOwner[_index].amount;
    }
}
