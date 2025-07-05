// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./StableCoin.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

contract StableEngine {
    address public wBTCPriceFeed;

    IERC20 public wBTC;
    StableCoin public stableCoin;

    constructor(address _wBTC, address _stableCoin, address _wBTCPriceFeed) {
        wBTC = IERC20(_wBTC);
        stableCoin = StableCoin(_stableCoin);
        wBTCPriceFeed = _wBTCPriceFeed;
    }

    function depositCollateral() external {}

    function withdrawCollateral() external {}

    function liquidate() external {}

    function _checkHealthFactor() internal view returns (uint256 healthFactor) {}

    function _getwBTCPrice() internal view returns (uint256 price) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(wBTCPriceFeed);
        (, int256 priceInt,,,) = priceFeed.latestRoundData();
        require(priceInt > 0, "Invalid price");
        return uint256(priceInt);
    }
}
