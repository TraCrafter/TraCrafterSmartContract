// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {LendingPoolFactory} from "../src/LendingPoolFactory.sol";
import {LendingPool} from "../src/LendingPool.sol";
import {Position} from "../src/Position.sol";
import {MockUSDC} from "../src/MockUSDC.sol";
import {MockWBTC} from "../src/MockWBTC.sol";
import {PriceFeed} from "../src/PriceFeed.sol";

contract LendingPoolFactoryTest is Test {
    LendingPoolFactory public lendingPoolFactory;
    LendingPool public lendingPool;
    Position public position;
    PriceFeed public priceFeed;

    MockUSDC public usdc;
    MockWBTC public wbtc;

    address public alice = address(0x1);
    address public bob = address(0x2);

    bool priceFeedIsActive = false;

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
        if (priceFeedIsActive) priceFeed = new PriceFeed(address(wbtc), address(usdc));

        usdc.mint(alice, 100e6);
        wbtc.mint(alice, 1e8);

        // usdc.mint(bob, 200e6);
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
        IERC20(address(usdc)).approve(address(lendingPool), 100e6);
        lendingPool.supply(100e6);
        // console.log("Total Supply Assets: ", lendingPool.totalSupplyAssets());
        // console.log("Total Supply Shares: ", lendingPool.totalSupplyShares());
        // console.log("User Supply Shares: ", lendingPool.userSupplyShares(alice));
        vm.stopPrank();
    }

    function test_withdraw() public {
        vm.startPrank(alice);
        IERC20(address(usdc)).approve(address(lendingPool), 100e6);
        lendingPool.supply(100e6);
        lendingPool.withdraw(100e6);
        // console.log("Total Supply Assets: ", lendingPool.totalSupplyAssets());
        // console.log("Total Supply Shares: ", lendingPool.totalSupplyShares());
        // console.log("User Supply Shares: ", lendingPool.userSupplyShares(alice));
        vm.stopPrank();
    }

    function test_supplyCollateralByPosition() public {
        vm.startPrank(bob);

        lendingPool.createPosition();
        // ERC20 Token, each decimal ->
        // WBTC 8
        // USDC 6
        // ETH 18
        IERC20(address(wbtc)).approve(address(lendingPool), 1e8);
        lendingPool.supplyCollateralByPosition(1e8);
        // console.log("User Collaterals: ", lendingPool.userCollaterals(alice));
        vm.stopPrank();
    }

    function helper_supply(address _user, uint256 _amount) public {
        vm.startPrank(_user);
        IERC20(address(usdc)).approve(address(lendingPool), _amount);
        lendingPool.supply(_amount);
        vm.stopPrank();
    }

    function helper_supplyCollateral(address _user, uint256 _amount) public {
        vm.startPrank(_user);
        lendingPool.createPosition();
        IERC20(address(wbtc)).approve(address(lendingPool), _amount);
        lendingPool.supplyCollateralByPosition(_amount);
        vm.stopPrank();
    }

    function helper_borrow(address _user, uint256 _amount, bool _createPosition) public {
        vm.startPrank(_user);
        if (_createPosition) lendingPool.createPosition();
        lendingPool.borrowByPosition(_amount);
        vm.stopPrank();
    }

    function helper_repay(address _user, uint256 _amount) public {
        vm.startPrank(_user);
        IERC20(address(usdc)).approve(address(lendingPool), _amount);
        lendingPool.repayByPosition(_amount);
        vm.stopPrank();
    }

    function test_borrowByPosition() public {
        // Alice supply 100 USDC
        helper_supply(alice, 100e6);

        console.log("Total Supply Assets:", lendingPool.totalSupplyAssets());
        console.log("Total Supply Shares:", lendingPool.totalSupplyShares());
        console.log("User Supply Shares: ", lendingPool.userSupplyShares(alice));
        console.log("----------------------------------------------------------------");
        console.log("Bob WBTC Balance Before: ", wbtc.balanceOf(bob));
        console.log("Bob USDC Balance Before: ", usdc.balanceOf(bob));

        helper_supplyCollateral(bob, 1e8);
        console.log("Bob WBTC Balance After: ", wbtc.balanceOf(bob));
        //BOB USDC balance before
        console.log("----------------------------------------------------------------");
        // Borrow 9 USDC
        console.log("Bob USDC Balance Before: ", usdc.balanceOf(bob));
        helper_borrow(bob, 9e6, true);
        console.log("User Borrow Shares:   ", lendingPool.userBorrowShares(bob));
        console.log("Bob USDC Balance AFTER:     ", usdc.balanceOf(bob));
        console.log("----------------------------------------------------------------");

        console.log("----------------------------------------------------------------");
        // Borrow 9 USDC
        console.log("Bob USDC Balance Before II: ", usdc.balanceOf(bob));
        helper_borrow(bob, 9e6, false);
        console.log("User Borrow Shares II:   ", lendingPool.userBorrowShares(bob));
        console.log("Bob USDC Balance AFTER II:     ", usdc.balanceOf(bob));
        console.log("----------------------------------------------------------------");

        console.log("----------------------------------------------------------------");

        console.log("totalSupplyAssets setelah 0 hari =", lendingPool.totalSupplyAssets());
        console.log("totalBorrowAssets setelah 0 hari =", lendingPool.totalBorrowAssets());

        console.log("----------------------------------------------------------------");

        vm.warp(block.timestamp + 365 days);

        vm.startPrank(bob);
        lendingPool.accrueInterest();
        vm.stopPrank();

        console.log("totalSupplyAssets setelah 365 hari =", lendingPool.totalSupplyAssets()); // 100,9
        console.log("totalBorrowAssets setelah 365 hari =", lendingPool.totalBorrowAssets()); // 18,9
        console.log("user borrow shares setelah 365 hari =", lendingPool.userBorrowShares(bob));
    }

    function test_repayByPosition() public {
        helper_supply(alice, 100e6);
        helper_supplyCollateral(bob, 1e8);
        helper_borrow(bob, 9e6, true);
        helper_borrow(bob, 9e6, false);

        vm.warp(block.timestamp + 365 days);

        console.log("totalSupplyAssets setelah 365 hari =", lendingPool.totalSupplyAssets()); // 100,9
        console.log("totalBorrowAssets setelah 365 hari =", lendingPool.totalBorrowAssets()); // 18,9
        console.log("user borrow shares setelah 365 hari =", lendingPool.userBorrowShares(bob));

        console.log("----------------------------------------------------------------");

        vm.startPrank(bob);
        lendingPool.accrueInterest();
        vm.stopPrank();
        // Bob USDC Balance
        console.log("Bob USDC Balance: ", usdc.balanceOf(bob));
        console.log("----------------------------------------------------------------");
        usdc.mint(bob, 100e6);
        helper_repay(bob, 18e6);
        console.log("----------------------------------------------------------------");
        console.log("Bob repay USDC");
        console.log("----------------------------------------------------------------");
        // Check Bob USDC Shares
        console.log("Bob USDC Shares: ", lendingPool.userBorrowShares(bob));
        console.log("Total Borrow Shares: ", lendingPool.totalBorrowShares());
        console.log("Total Borrow Assets: ", lendingPool.totalBorrowAssets());
    }

    function test_priceFeed() public {
        if (priceFeedIsActive) {
            console.log("BTC Price: ", priceFeed.priceBTC());
            console.log("USDC Price: ", priceFeed.priceWETH());
            console.log("BTC Decimal: ", priceFeed.getQuoteDecimal());
            console.log("USDC Decimal: ", priceFeed.getBaseDecimal());
            console.log("BTC Description: ", priceFeed.getQuoteDescription());
            console.log("USDC Description: ", priceFeed.getBaseDescription());
        }
        // 91,527.61777140
        // 0.9994597
    }
}
// 100000000000000000000
// 100000000000000000000

// TRADE, COLLATERAL 2, PRICEFEED, LIKUIDASI
// Borrow 70% seharga assets

// Repay by collateral
// BTC naik -> kenaikan asset buat bayar hutang
