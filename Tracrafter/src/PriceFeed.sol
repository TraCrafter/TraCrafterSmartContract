// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IAggregatorV3 {
    function decimals() external view returns (uint8);

    function description() external view returns (string memory);

    function version() external view returns (uint256);

    function getRoundData(uint80 _roundId)
        external
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);

    function latestRoundData()
        external
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);
}

contract PriceFeed {
    // address quoteFeed = 0xF4030086522a5bEEa4988F8cA5B36dbC97BeE88c; // BTC/USD
    // address quoteFeed = 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419; // ETH/USD
    // address baseFeed = 0x8fFfFfd4AfB6115b954Bd326cbe7B4BA576818f6; // USDC/USD

    address quoteFeed;
    address baseFeed;

    constructor(address _quoteFeed, address _baseFeed) {
        quoteFeed = _quoteFeed;
        baseFeed = _baseFeed;
    }

    function getPrice() public view returns (uint256) {
        (, int256 quotePrice,,,) = IAggregatorV3(quoteFeed).latestRoundData();
        (, int256 basePrice,,,) = IAggregatorV3(baseFeed).latestRoundData();
        return uint256(quotePrice) * 1e6 / uint256(basePrice);
    }

    function priceBTC() public view returns (uint256) {
        (, int256 quotePrice,,,) = IAggregatorV3(quoteFeed).latestRoundData();
        return uint256(quotePrice);
    }

    function priceWETH() public view returns (uint256) {
        (, int256 basePrice,,,) = IAggregatorV3(baseFeed).latestRoundData();
        return uint256(basePrice);
    }

    function getQuoteDecimal() public view returns (uint8) {
        return IAggregatorV3(quoteFeed).decimals();
    }
    function getBaseDecimal() public view returns (uint8) {
        return IAggregatorV3(baseFeed).decimals();
    }

    function getQuoteDescription() public view returns (string memory) {
        return IAggregatorV3(quoteFeed).description();
    }

    function getBaseDescription() public view returns (string memory) {
        return IAggregatorV3(baseFeed).description();
    }
}
