// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {IERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {LendingPoolFactory} from "../src/LendingPoolFactory.sol";
import {LendingPool} from "../src/LendingPool.sol";
import {Position} from "../src/Position.sol";
import {MockUSDC} from "../src/MockUSDC.sol";
import {MockWBTC} from "../src/MockWBTC.sol";

contract LendingPoolFactoryTest is Test {
    LendingPoolFactory public lendingPoolFactory;
    LendingPool public lendingPool;
    Position public position;

    MockUSDC public usdc;
    MockWBTC public wbtc;

    // address public wbtc = 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599; // collateral 1
    // address public usdc = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48; // collateral 2
    address public usdc2 = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48; // borrow

    address public alice = address(0x1);
    address public bob = address(0x2);

    function setUp() public {
        usdc = new MockUSDC();
        wbtc = new MockWBTC();

        vm.startPrank(alice);
        vm.createSelectFork("https://eth-mainnet.g.alchemy.com/v2/Ea4M-V84UObD22z2nNlwDD9qP8eqZuSI", 21197642);
        lendingPoolFactory = new LendingPoolFactory();

        // jalankan fungsi lendingPoolFactory.createLendingPool(wbtc, usdc);
        lendingPool = new LendingPool(address(wbtc), address(usdc));

        // jalankan fungsi lendingPool.createPosition();
        position = new Position(address(wbtc), address(usdc));

        usdc.mint(alice, 100e18);
        wbtc.mint(alice, 1e8);

        // usdc.mint(bob, 200e18);
        wbtc.mint(bob, 2e8);

        vm.stopPrank();
    }

    function test_checkAddresses() public view {
        // console.log("Lending Pool Factory: ", address(lendingPoolFactory));
        // console.log("Lending Pool: ", address(lendingPool));
        // console.log("Position: ", address(position));
    }

    function test_createPosition() public {
        vm.startPrank(alice);
        lendingPool.createPosition();
        // console.log("Position Address: ", lendingPool.addressPosition(alice));
        vm.stopPrank();
    }

    function test_supply() public {
        vm.startPrank(alice);
        IERC20(address(usdc)).approve(address(lendingPool), 100e18);
        lendingPool.supply(100e18);
        // console.log("Total Supply Assets: ", lendingPool.totalSupplyAssets());
        // console.log("Total Supply Shares: ", lendingPool.totalSupplyShares());
        // console.log("User Supply Shares: ", lendingPool.userSupplyShares(alice));
        vm.stopPrank();
    }

    function test_withdraw() public {
        vm.startPrank(alice);
        IERC20(address(usdc)).approve(address(lendingPool), 100e18);
        lendingPool.supply(100e18);
        lendingPool.withdraw(100e18);
        // console.log("Total Supply Assets: ", lendingPool.totalSupplyAssets());
        // console.log("Total Supply Shares: ", lendingPool.totalSupplyShares());
        // console.log("User Supply Shares: ", lendingPool.userSupplyShares(alice));
        vm.stopPrank();
    }

    function test_supplyCollateralByPosition() public {
        test_supply();

        vm.startPrank(bob);

        lendingPool.createPosition();

        IERC20(address(wbtc)).approve(address(lendingPool), 1e8);
        lendingPool.supplyCollateralByPosition(1e8);
        // console.log("User Collaterals: ", lendingPool.userCollaterals(alice));
        vm.stopPrank();
    }

    function test_borrowByPosition() public {
        vm.startPrank(alice);
        IERC20(address(usdc)).approve(address(lendingPool), 100e18);
        lendingPool.supply(100e18);
        console.log("Total Supply Assets: ", lendingPool.totalSupplyAssets());
        console.log("Total Supply Shares: ", lendingPool.totalSupplyShares());
        console.log("User Supply Shares: ", lendingPool.userSupplyShares(alice));
        vm.stopPrank();

        vm.startPrank(bob);
        lendingPool.createPosition();
        // Supply 1 WBTC as Collateral 
        IERC20(address(wbtc)).approve(address(lendingPool), 1e8);
        lendingPool.supplyCollateralByPosition(1e8);
        // Borrow 90 USDC
        lendingPool.borrowByPosition(90e10);
        console.log("User Borrow Shares: ", lendingPool.userBorrowShares(bob));
        // check bob balance
        console.log("Bob USDC Balance: ", usdc.balanceOf(bob));
        vm.stopPrank();

        vm.startPrank(bob);
        lendingPool.createPosition();
        // Supply 1 WBTC as Collateral 
        IERC20(address(wbtc)).approve(address(lendingPool), 1e8);
        lendingPool.supplyCollateralByPosition(1e8);
        // Borrow 90 USDC
        lendingPool.borrowByPosition(90e10);
        console.log("User Borrow Shares: ", lendingPool.userBorrowShares(bob));
        // check bob balance
        console.log("Bob USDC Balance: ", usdc.balanceOf(bob));
        vm.stopPrank();
        
        // check total supply shares
        // console.log("Total Supply Shares: ", lendingPool.totalSupplyShares());
    }
}
