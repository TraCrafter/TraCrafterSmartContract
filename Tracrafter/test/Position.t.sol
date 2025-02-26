// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

interface Position {
    function getTokenOwnerBalances(address _token) external view returns (uint256);
    function counter() external view returns (uint256);
    function getAllTokenOwnerAddress() external view returns (address[] memory);
}

contract PositionTest is Test {
    Position position;
    address ahmad = 0x9CB49d64564819f4396730b408cb16A03315B340;
    address mockUsdc = 0x373e1981F97607B4073Ee8bB23e3810CdAAAD1f8;

    address constant CONTRACT_ADDRESS = 0xeeB5738177E3Ea0d85352d547986Ae87E00E79cE;

    function setUp() public {
        vm.createSelectFork("https://testnet.riselabs.xyz");
        position = Position(CONTRACT_ADDRESS);
    }

    function test_tokenBalances() public {
        vm.startPrank(ahmad);
        console.log("Testing token", position.getTokenOwnerBalances(mockUsdc));
        console.log("counter", position.counter());
        console.log("position mockUsdc IERC20 balance", IERC20(mockUsdc).balanceOf(CONTRACT_ADDRESS));
        console.log("all", position.getAllTokenOwnerAddress().length);
        // 56,153.525351
        vm.stopPrank();
    }
}
