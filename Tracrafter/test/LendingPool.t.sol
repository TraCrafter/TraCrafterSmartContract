// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {IERC20Metadata} from "openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {LendingPoolFactory} from "../src/LendingPoolFactory.sol";
import {LendingPool} from "../src/LendingPool.sol";
import {Position} from "../src/Position.sol";

import {PriceFeed} from "../src/PriceFeed.sol";

interface IOracle {
    function getPrice(address _collateral, address _borrow) external view returns (uint256);
    function getQuoteDecimal(address _token) external view returns (uint256);
}

contract LendingPoolFactoryTest is Test {
    LendingPoolFactory public lendingPoolFactory;
    LendingPool public lendingPool;
    Position public position;
    IOracle public oracle;

    PriceFeed public priceFeed;

    address public owner = makeAddr("owner");

    address public alice = makeAddr("alice");
    address public bob = makeAddr("bob");

    bool priceFeedIsActive = false;

    address weth = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2; // real weth
    address usdc = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48; // real usdc
    address pepe = 0x6982508145454Ce325dDbE47a25d4ec3d2311933; // real pepe

    address router = 0xE592427A0AEce92De3Edee1F18E0157C05861564;

    address ethUsd = 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419; // ETH/USD
    address usdcUsd = 0x8fFfFfd4AfB6115b954Bd326cbe7B4BA576818f6; // USDC/USD
    // address pepeUsd = 0x4ffC43a60e009B551865A93d232E33Fce9f01507; // SOL/USD

    function setUp() public {
        priceFeed = new PriceFeed();
        oracle = IOracle(address(priceFeed));

        vm.startPrank(alice);
        vm.createSelectFork("https://eth-mainnet.g.alchemy.com/v2/npJ88wr-vv5oxDKlp0mQYSfVXfN2nKif", 21829147);
        lendingPoolFactory = new LendingPoolFactory();
        lendingPool = new LendingPool(address(weth), address(usdc), address(oracle), 7e17);
        position = new Position(address(weth), address(usdc));
        vm.stopPrank();

        vm.startPrank(bob);
        lendingPool.createPosition();
        vm.stopPrank();

        deal(usdc, alice, 10000e6);
        deal(weth, alice, 1e18);

        deal(usdc, bob, 2000e6);
        deal(weth, bob, 2e18);

        priceFeed.addPriceFeed("ETH/USD", weth, ethUsd);
        priceFeed.addPriceFeed("USDC/USD", usdc, usdcUsd);
        priceFeed.addPriceManual("PEPE/USD", pepe, 0.00000954 * 10 ** 18, 18);
        // 522,974771273756619958
        // 522,97477127
    }

    function helper_supply(address _user, address _token, uint256 _amount) public {
        vm.startPrank(_user);
        IERC20(_token).approve(address(lendingPool), _amount);
        lendingPool.supply(_amount);
        vm.stopPrank();
    }

    function helper_supply_borrow() public {
        vm.startPrank(alice);
        IERC20(usdc).approve(address(lendingPool), 1000e6);
        lendingPool.supply(1000e6);
        vm.stopPrank();

        vm.startPrank(bob);
        IERC20(weth).approve(address(lendingPool), 1e18);
        lendingPool.supplyCollateralByPosition(1e18);
        lendingPool.borrowByPosition(500e6);
        vm.warp(block.timestamp + 365 days);
        lendingPool.accrueInterest();
        vm.stopPrank();
    }

    function helper_repay() public {
        helper_supply_borrow();

        vm.startPrank(bob);
        IERC20(usdc).approve(address(lendingPool), 500e6);
        lendingPool.repayByPosition(454e6); // 454 shares setara 499.4
        vm.stopPrank();

        vm.startPrank(bob);
        IERC20(usdc).approve(address(lendingPool), 300e6);
        lendingPool.repayByPosition(46e6); // 46 shares setara 50.6
        vm.stopPrank();
    }

    function test_borrow() public {
        // bob borrow 8000 usdc
        uint256 borrowed = 1900e6;

        // alice supply 1000 usdc
        helper_supply(alice, usdc, 10000e6);

        vm.startPrank(bob);
        // bob supply 1 WETH as collateral
        IERC20(weth).approve(address(lendingPool), 1e18);
        lendingPool.supplyCollateralByPosition(1e18);

        vm.expectRevert(LendingPool.InsufficientCollateral.selector);
        lendingPool.borrowByPosition(10_000e6);

        // bob borrow usdc
        vm.expectRevert(LendingPool.InsufficientCollateral.selector);
        lendingPool.borrowByPosition(borrowed);
        vm.stopPrank();
    }

    function test_withdraw() public {
        helper_supply(alice, usdc, 1000e6);
        vm.startPrank(alice);
        // zero Amount
        vm.expectRevert(LendingPool.ZeroAmount.selector);
        lendingPool.withdraw(0);

        // insufficient shares
        vm.expectRevert(LendingPool.InsufficientShares.selector);
        lendingPool.withdraw(10_000e6);

        lendingPool.withdraw(400e6);
        vm.stopPrank();

        console.log("alice balance: ", IERC20(usdc).balanceOf(alice));
    }

    function test_repay() public {
        helper_supply_borrow();

        console.log("balance bob usdc", IERC20(usdc).balanceOf(bob));
        console.log("total supply assets before", lendingPool.totalSupplyAssets()); // 1050e6
        console.log("total borrow assets before", lendingPool.totalBorrowAssets()); // 550e6
        console.log("total borrow shares before", lendingPool.totalBorrowShares()); // 500e6
        console.log("user borrow shares before", lendingPool.userBorrowShares(bob)); // 500e6

        vm.startPrank(bob);
        IERC20(usdc).approve(address(lendingPool), 500e6);
        lendingPool.repayByPosition(454e6); // 454 shares setara 499.4
        vm.stopPrank();

        console.log("balance bob usdc", IERC20(usdc).balanceOf(bob));
        console.log("total supply assets after repay", lendingPool.totalSupplyAssets()); // no changes
        console.log("total borrow assets after repay", lendingPool.totalBorrowAssets()); // 50.6e6
        console.log("total borrow shares after repay", lendingPool.totalBorrowShares()); // 46e6
        console.log("user borrow shares after repay", lendingPool.userBorrowShares(bob)); // 46e6

        vm.startPrank(bob);
        IERC20(usdc).approve(address(lendingPool), 300e6);
        lendingPool.repayByPosition(46e6); // 46 shares setara 50.6
        vm.stopPrank();

        console.log("bob balance", IERC20(usdc).balanceOf(bob));
        console.log("total supply assets after repay 2", lendingPool.totalSupplyAssets()); // no changes
        console.log("total borrow assets after repay 2", lendingPool.totalBorrowAssets()); // 0
        console.log("total borrow shares after repay 2", lendingPool.totalBorrowShares()); // 0
        console.log("user borrow shares after repay 2", lendingPool.userBorrowShares(bob)); // 0
    }

    function test_withdraw_withshares() public {
        helper_repay();

        console.log("alice balance before", IERC20(usdc).balanceOf(alice));
        vm.startPrank(alice);
        // zero Amount
        vm.expectRevert(LendingPool.ZeroAmount.selector);
        lendingPool.withdraw(0);

        // insufficient shares
        vm.expectRevert(LendingPool.InsufficientShares.selector);
        lendingPool.withdraw(10_000e6);

        lendingPool.withdraw(1000e6); // 1000 shares setara 1050 usdc
        vm.stopPrank();

        console.log("alice balance after", IERC20(usdc).balanceOf(alice));
    }

    function test_swap() public {
        console.log("test price feed PEPE", priceFeed.priceCollateral(pepe));
        console.log("test price feed WETH", priceFeed.priceCollateral(weth));

        vm.startPrank(bob);
        IERC20(weth).approve(address(lendingPool), 1.2e18); // awalnya deal 2 ether, jadi 0,8 ether
        lendingPool.supplyCollateralByPosition(1.2e18);
        vm.stopPrank();

        // berkurang udah bisa supply collateral
        console.log("bob balance weth", IERC20(weth).balanceOf(bob)); // 800000000000000000 = 0,8 ether
        vm.startPrank(bob);
        // supply 1,2 ether dikurangi 0.5 ether buat swap
        uint256 amountOut = lendingPool.swapByPosition(pepe, 0.2e18, 0);
        console.log(amountOut);
        vm.stopPrank();

        console.log("Bob's Collateral", lendingPool.userCollaterals(bob)); // 1 ether

        uint256 totalPepe = priceFeed.priceCollateral(pepe) * amountOut / 1e18;
        console.log("Price of PEPE/USD", totalPepe); // 262.32009831
        uint256 totalWETH = priceFeed.priceCollateral(weth) * lendingPool.userCollaterals(bob) / 1e18;
        console.log("Price of WETH/USD", totalWETH); // 3133.57000000
        
    }
}
