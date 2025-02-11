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

    // address quoteFeed;
    // address baseFeed;

    struct PriceLists {
        string name;
        address feed;
    }

    // Collateral -> price oracle, Borrow -> price oracle
    mapping(address => address) public quoteFeed;
    mapping(address => address) public baseFeed;
    PriceLists[] public priceLists;
    address owner;

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function addPriceFeed(string memory _name, address _token, address _priceAddress) public onlyOwner {
        priceLists.push(PriceLists(_name, _priceAddress));
        quoteFeed[_token] = _priceAddress;
        baseFeed[_token] = _priceAddress;
    }

    function editPriceFeed(string memory _name, address _priceAddress, uint256 _index) public onlyOwner {
        priceLists[_index] = PriceLists(_name, _priceAddress);
    }

    function addPairPriceCollateral(address _collateral, address _priceAddress) public {
        quoteFeed[_collateral] = _priceAddress;
    }

    function addPairPriceBorrow(address _borrow, address _priceAddress) public {
        baseFeed[_borrow] = _priceAddress;
    }

    function getPrice(address _collateral, address _borrow) public view returns (uint256) {
        (, int256 quotePrice,,,) = IAggregatorV3(quoteFeed[_collateral]).latestRoundData();
        (, int256 basePrice,,,) = IAggregatorV3(baseFeed[_borrow]).latestRoundData();
        return uint256(quotePrice) * 1e6 / uint256(basePrice);
    }

    function priceCollateral(address _token) public view returns (uint256) {
        (, int256 quotePrice,,,) = IAggregatorV3(quoteFeed[_token]).latestRoundData();
        return uint256(quotePrice);
    }

    function priceBorrow(address _token) public view returns (uint256) {
        (, int256 quotePrice,,,) = IAggregatorV3(baseFeed[_token]).latestRoundData();
        return uint256(quotePrice);
    }

    function getQuoteDecimal(address _token) public view returns (uint8) {
        return IAggregatorV3(quoteFeed[_token]).decimals();
    }

    function getBaseDecimal(address _token) public view returns (uint8) {
        return IAggregatorV3(baseFeed[_token]).decimals();
    }

    function getQuoteDescription(address _token) public view returns (string memory) {
        return IAggregatorV3(quoteFeed[_token]).description();
    }

    function getBaseDescription(address _token) public view returns (string memory) {
        return IAggregatorV3(baseFeed[_token]).description();
    }
}
