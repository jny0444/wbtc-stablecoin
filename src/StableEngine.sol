// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./StableCoin.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

contract StableEngine {
    address public wBTCPriceFeed;

    IERC20 public wBTC;
    StableCoin public stableCoin;

    uint256 constant PRECISION = 1e18;
    uint256 constant ADDITIONAL_FEED_PRECISION = 1e10;
    uint256 constant COLLATERAL_FACTOR = 175; // 75% more than the value added as collateral

    constructor(address _wBTC, address _stableCoin, address _wBTCPriceFeed) {
        wBTC = IERC20(_wBTC);
        stableCoin = StableCoin(_stableCoin);
        wBTCPriceFeed = _wBTCPriceFeed;
    }

    function depositCollateral(uint256 amountwBTC) external {
        require(amountwBTC > 0, "Amount must be greater than zero");

        // must call APPROVE on wBTC before calling this function
        require(wBTC.transferFrom(msg.sender, address(this), amountwBTC), "Transfer failed");
        uint256 wBTCPrice = _getUSDValue(amountwBTC);
        require(wBTCPrice > 0, "Invalid wBTC price");

        uint256 stcAmoun = (wBTCPrice);
    }

    function getSTC() external {}

    function withdrawCollateral() external {}

    function burnSTC() external {}

    function liquidate() external {}

    function _checkHealthFactor() internal view returns (uint256 healthFactor) {}

    function _getwBTCPrice() internal view returns (uint256 price) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(wBTCPriceFeed);
        (, int256 priceInt,,,) = priceFeed.latestRoundData();
        require(priceInt > 0, "Invalid price");
        return uint256(priceInt);
    }

    function _getUSDValue(uint256 _amount) internal view returns (uint256 usdValue) {
        return ((uint256(_getwBTCPrice()) * ADDITIONAL_FEED_PRECISION) * _amount) / PRECISION;
    }

    function _getwBTCDecimals() internal view returns (uint8 decimals) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(wBTCPriceFeed);
        return priceFeed.decimals();
    }
}
