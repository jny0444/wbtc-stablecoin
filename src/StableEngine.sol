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
    uint256 constant COLLATERAL_FACTOR = 75;

    mapping(address user => uint256 collateralAmount) public collateralAmounts;
    mapping(address user => uint256 stableCoinAmount) public mintedStablecoin;

    constructor(address _wBTC, address _stableCoin, address _wBTCPriceFeed) {
        wBTC = IERC20(_wBTC);
        stableCoin = StableCoin(_stableCoin);
        wBTCPriceFeed = _wBTCPriceFeed;
    }

    function depositCollateral(uint256 amountwBTC) external {
        require(amountwBTC > 0, "Amount must be greater than zero");

        // must call APPROVE on wBTC before calling this function
        require(wBTC.transferFrom(msg.sender, address(this), amountwBTC), "Transfer failed");
        collateralAmounts[msg.sender] += amountwBTC;

        uint256 usdValue = _getUSDValue(amountwBTC);
        require(usdValue > 0, "Invalid wBTC price");

        _mintSTC(usdValue);
    }

    function withdrawCollateral() external {}

    function liquidate() external {}

    function _mintSTC(uint256 usdValue) internal {
        uint256 mintSTCAmount = (usdValue * COLLATERAL_FACTOR) / 100;
        require(mintSTCAmount > 0, "Mint amount must be greater than zero");

        stableCoin.mint(msg.sender, mintSTCAmount);
        mintedStablecoin[msg.sender] += mintSTCAmount;
    }

    function _burnSTC(uint256 usdValue) internal {
        uint256 mintSTCAmount = (usdValue * COLLATERAL_FACTOR) / 100;
        require(mintSTCAmount > 0, "Burn amount must be greater than zero");

        stableCoin.burnFrom(msg.sender, mintSTCAmount);
    }

    function _checkHealthFactor() internal view returns (uint256 healthFactor) {
        
    }

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
