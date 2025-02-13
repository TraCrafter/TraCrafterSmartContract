// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {IERC20Metadata} from "openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {Position} from "./Position.sol";

interface ISwapRouter {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    function exactInputSingle(
        ExactInputSingleParams calldata params
    ) external payable returns (uint256 amountOut);
}

interface IOracle {
    function getPrice(
        address _collateral,
        address _borrow
    ) external view returns (uint256);

    function getQuoteDecimal(address _token) external view returns (uint256);
}

contract LendingPool {
    error ZeroAmount();
    error PositionUnavailable();
    error InsufficientShares();
    error InsufficientLiquidity();
    error InsufficientCollateral();
    error FlashloanFailed();
    error PositionNotCreated();
    error InvalidOracle();
    error LTVExceedMaxAmount();

    event CreatePosition(address user, address positionAddress);
    event Supply(address user, uint256 amount, uint256 shares);
    event Withdraw(address user, uint256 amount, uint256 shares);
    event SupplyCollateralByPosition(address user, uint256 amount);
    event WithdrawCollateral(address user, uint256 amount);
    event BorrowByPosition(address user, uint256 amount, uint256 shares);
    event RepayByPosition(address user, uint256 amount, uint256 shares);
    event RepayWithCollateralByPosition(address user, uint256 shares);
    event Flashloan(address user, address token, uint256 amount);
    event SwapByPosition(
        address user,
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 amountOut
    );

    Position public position;

    uint256 public totalSupplyAssets;
    uint256 public totalSupplyShares;
    uint256 public totalBorrowAssets;
    uint256 public totalBorrowShares;

    mapping(address => uint256) public userSupplyShares;
    mapping(address => uint256) public userBorrowShares;
    mapping(address => uint256) public userCollaterals;
    mapping(address => address) public addressPosition;

    address public collateralToken; // collateral(?)
    address public borrowToken; // borrow(?)
    address public router = 0xE592427A0AEce92De3Edee1F18E0157C05861564;
    address public oracle;

    uint256 public lastAccrued;

    uint256 ltv; // percentage

    modifier positionRequired() {
        if (addressPosition[msg.sender] == address(0))
            revert PositionNotCreated();
        _;
    }

    constructor(
        address _collateralToken,
        address _borrowToken,
        address _oracle,
        uint256 _ltv
    ) {
        collateralToken = _collateralToken;
        borrowToken = _borrowToken;
        lastAccrued = block.timestamp;
        if (_oracle == address(0)) revert InvalidOracle();
        oracle = _oracle;

        if (_ltv > 1e18) revert LTVExceedMaxAmount();
        ltv = _ltv;
    }

    function createPosition() public {
        if (addressPosition[msg.sender] == address(0)) {
            position = new Position(collateralToken, borrowToken);
            addressPosition[msg.sender] = address(position);
        }
    }

    function supply(uint256 amount) public {
        if (amount == 0) revert ZeroAmount();
        // Tujuannya adalah untuk penyedia token supaya bisa borrow
        _accrueInterest();
        uint256 shares = 0;
        if (totalSupplyAssets == 0) {
            shares = amount;
        } else {
            shares = (amount * totalSupplyShares) / totalSupplyAssets;
        }

        userSupplyShares[msg.sender] += shares;
        totalSupplyShares += shares;
        totalSupplyAssets += amount;

        IERC20(borrowToken).transferFrom(msg.sender, address(this), amount);

        emit Supply(msg.sender, amount, shares);
    }

    function withdraw(uint256 shares) external {
        if (shares == 0) revert ZeroAmount();
        if (shares > userSupplyShares[msg.sender]) revert InsufficientShares();

        _accrueInterest();

        uint256 amount = ((shares * totalSupplyAssets) / totalSupplyShares);

        userSupplyShares[msg.sender] -= shares;
        totalSupplyShares -= shares;
        totalSupplyAssets -= amount;

        if (totalSupplyAssets < totalBorrowAssets) {
            revert InsufficientLiquidity();
        }

        IERC20(borrowToken).transfer(msg.sender, amount);

        emit Withdraw(msg.sender, amount, shares);
    }

    function accrueInterest() public {
        _accrueInterest();
    }

    function _accrueInterest() internal {
        uint256 borrowRate = 10;

        uint256 interestPerYear = (totalBorrowAssets * borrowRate) / 100;
        // 1000 * 10 / 100 = 100/year

        uint256 elapsedTime = block.timestamp - lastAccrued;
        // 1 hari

        uint256 interest = (interestPerYear * elapsedTime) / 365 days;
        // interest = $100 * 1 hari / 365 hari  = $0.27

        totalSupplyAssets += interest;
        totalBorrowAssets += interest; // apakah harus nambah
        lastAccrued = block.timestamp;
    }

    function supplyCollateralByPosition(
        uint256 amount
    ) public positionRequired {
        if (amount == 0) revert ZeroAmount();
        accrueInterest();
        userCollaterals[msg.sender] += amount;
        IERC20(collateralToken).transferFrom(msg.sender, address(this), amount);

        emit SupplyCollateralByPosition(msg.sender, amount);
    }

    function withdrawCollateral(uint256 amount) public {
        if (amount == 0) revert ZeroAmount();
        if (amount > userCollaterals[msg.sender])
            revert InsufficientCollateral();

        _accrueInterest();

        userCollaterals[msg.sender] -= amount;

        IERC20(collateralToken).transfer(msg.sender, amount);

        emit WithdrawCollateral(msg.sender, amount);
    }

    function _isHealthy(address user) internal view {
        // addition isHealthy
        uint256 positionValue = 0;
        if (addressPosition[msg.sender] != address(0)) {
            uint256 positionLength = Position(addressPosition[msg.sender])
                .getTokenOwnerLength();
            for (uint256 i = 0; i < positionLength; i++) {
                address tokenAddress = Position(addressPosition[msg.sender])
                    .getTokenOwnerAddress(i);

                uint256 positionPrice = IOracle(oracle).getPrice(
                    tokenAddress,
                    borrowToken
                );
                uint256 positionDecimal = IOracle(oracle).getQuoteDecimal(
                    tokenAddress
                );
                positionValue +=
                    (position.getTokenBalance(tokenAddress) * positionPrice) /
                    positionDecimal;
            }
        }

        uint256 collateralPrice = IOracle(oracle).getPrice(
            collateralToken,
            borrowToken
        );
        uint256 collateralDecimals = 10 **
            IERC20Metadata(collateralToken).decimals(); // 1e18

        uint256 borrowed = userBorrowShares[user] != 0
            ? (userBorrowShares[user] * totalBorrowAssets) / totalBorrowShares
            : 0; // karena sebelumnya jika 0 * 0 / 0 itu tidak bisa, maka harus diprotect kalau userBorrowShares[user] == 0 langsung aja borrow kasih nilai 0

        uint256 collateralValue = (userCollaterals[user] * collateralPrice) /
            collateralDecimals; // 1e18 * 2633.51578211 /  1e18
        uint256 maxBorrow = ((collateralValue) * ltv) / 1e18; // 2633.51578211 * 70%
        // uint256 maxBorrow = ((collateralValue + positionValue) * ltv) / 1e18; // 2633.51578211 * 70%

        if (borrowed > maxBorrow) revert InsufficientCollateral();
    }

    function borrowByPosition(uint256 amount) public positionRequired {
        _accrueInterest();
        uint256 shares = 0;
        if (totalBorrowShares == 0) {
            shares = amount;
        } else {
            shares = ((amount * totalBorrowShares) / totalBorrowAssets);
        }

        userBorrowShares[msg.sender] += shares;
        totalBorrowShares += shares;
        totalBorrowAssets += amount;
        _isHealthy(msg.sender);
        if (totalBorrowAssets > totalSupplyAssets) {
            revert InsufficientLiquidity();
        }
        IERC20(borrowToken).transfer(msg.sender, amount);

        emit BorrowByPosition(msg.sender, amount, shares);
    }

    function repayByPosition(uint256 shares) public positionRequired {
        if (shares == 0) revert ZeroAmount();

        _accrueInterest();

        uint256 borrowAmount = ((shares * totalBorrowAssets) /
            totalBorrowShares);
        userBorrowShares[msg.sender] -= shares; // 500 - 400
        totalBorrowShares -= shares; // 500 - 400
        totalBorrowAssets -= borrowAmount; // 550 - x

        IERC20(borrowToken).transferFrom(
            msg.sender,
            address(this),
            borrowAmount
        );

        emit RepayByPosition(msg.sender, borrowAmount, shares);
    }

    function repayWithCollateralsByPosition(uint256 shares) public {
        _accrueInterest();

        totalBorrowAssets -= shares;
        totalBorrowShares -= shares;
        userBorrowShares[msg.sender] -= shares;

        IERC20(borrowToken).transferFrom(msg.sender, address(this), shares);

        emit RepayWithCollateralByPosition(msg.sender, shares);
    }

    function FlashLoan(
        address token,
        uint256 amount,
        bytes calldata data
    ) external {
        if (amount == 0) revert ZeroAmount();

        IERC20(token).transfer(msg.sender, amount);

        (bool success, ) = address(msg.sender).call(data);
        if (!success) revert FlashloanFailed();

        IERC20(token).transferFrom(msg.sender, address(this), amount);

        emit Flashloan(msg.sender, token, amount);
    }

    function swapByPosition(
        address _tokenDestination,
        uint256 amountIn,
        uint256 amountOutMin
    ) public positionRequired returns (uint256 amountOut) {
        if (amountIn == 0) revert ZeroAmount();

        userCollaterals[msg.sender] -= amountIn;

        IERC20(collateralToken).approve(router, amountIn);
        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter
            .ExactInputSingleParams({
                tokenIn: collateralToken,
                tokenOut: _tokenDestination,
                fee: 3000,
                recipient: address(this),
                deadline: block.timestamp,
                amountIn: amountIn,
                amountOutMinimum: amountOutMin,
                sqrtPriceLimitX96: 0
            });

        collateralToken = _tokenDestination;
        amountOut = ISwapRouter(router).exactInputSingle(params);
        position.swapToken(_tokenDestination, amountOut);

        emit SwapByPosition(
            msg.sender,
            collateralToken,
            _tokenDestination,
            amountIn,
            amountOut
        );
    }

    function getTokenLengthByPosition()
        public
        view
        positionRequired
        returns (uint256)
    {
        return Position(addressPosition[msg.sender]).getTokenOwnerLength();
    }

    function getTokenAddressByPosition(
        uint256 _index
    ) public view positionRequired returns (address) {
        return
            Position(addressPosition[msg.sender]).getTokenOwnerAddress(_index);
    }

    function getTokenAmountByPosition(
        uint256 _index
    ) public view positionRequired returns (uint256) {
        return
            Position(addressPosition[msg.sender]).getTokenOwnerAmount(_index);
    }

    function getTokenDecimalByPosition(
        uint256 _index
    ) public view positionRequired returns (uint256) {
        return
            IERC20Metadata(
                Position(addressPosition[msg.sender]).getTokenOwnerAddress(
                    _index
                )
            ).decimals();
    }
}
