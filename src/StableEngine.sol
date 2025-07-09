// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./StableCoin.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract StableEngine is ReentrancyGuard, Pausable, Ownable {
    address public wBTCPriceFeed;

    IERC20 public wBTC;
    StableCoin public stableCoin;

    uint256 constant PRECISION = 1e18;
    uint256 constant ADDITIONAL_FEED_PRECISION = 1e10;
    uint256 constant COLLATERAL_FACTOR = 75;
    uint256 constant LIQUIDATION_BONUS = 10;
    uint256 constant PRICE_STALENESS_THRESHOLD = 3600; // 1 hour

    // Events
    event CollateralDeposited(address indexed user, uint256 amount, uint256 stableCoinMinted);
    event CollateralWithdrawn(address indexed user, uint256 amount, uint256 stableCoinBurned);
    event Liquidated(address indexed liquidatee, address indexed liquidator, uint256 collateralAmount, uint256 bonus);

    mapping(address user => uint256 collateralAmount) public collateralAmounts;
    mapping(address user => uint256 stableCoinAmount) public mintedStablecoin;

    constructor(address _wBTC, address _stableCoin, address _wBTCPriceFeed) Ownable(msg.sender) {
        wBTC = IERC20(_wBTC);
        stableCoin = StableCoin(_stableCoin);
        wBTCPriceFeed = _wBTCPriceFeed;
    }

    function depositCollateral(uint256 amountwBTC) external nonReentrant whenNotPaused {
        require(amountwBTC > 0, "Amount must be greater than zero");

        // must call APPROVE on wBTC before calling this function
        require(wBTC.transferFrom(msg.sender, address(this), amountwBTC), "Transfer failed");
        collateralAmounts[msg.sender] += amountwBTC;

        uint256 usdValue = _getUSDValue(amountwBTC);
        require(usdValue > 0, "Invalid wBTC price");

        _mintSTC(usdValue);
        uint256 mintedAmount = (usdValue * COLLATERAL_FACTOR) / 100;

        emit CollateralDeposited(msg.sender, amountwBTC, mintedAmount);
    }

    function withdrawCollateral(uint256 amountwBTC) external nonReentrant whenNotPaused {
        require(amountwBTC > 0, "Amount must be greater than zero");
        require(collateralAmounts[msg.sender] >= amountwBTC, "Insufficient collateral");

        collateralAmounts[msg.sender] -= amountwBTC;
        require(_checkHealthFactor() >= 1e18, "Health factor must be at least 1");

        require(wBTC.transfer(msg.sender, amountwBTC), "Transfer failed");
        uint256 usdValue = _getUSDValue(amountwBTC);
        require(usdValue > 0, "Invalid wBTC price");

        _burnSTC(usdValue);
        uint256 burnedAmount = (usdValue * COLLATERAL_FACTOR) / 100;

        emit CollateralWithdrawn(msg.sender, amountwBTC, burnedAmount);
    }

    function liquidate(address liquidatee) external nonReentrant {
        require(_checkHealthFactorForUser(liquidatee) < 1e18, "Health factor must be less than 1");

        uint256 collateralAmount = collateralAmounts[liquidatee];
        require(collateralAmount > 0, "No collateral to liquidate");

        uint256 stableCoinDebt = mintedStablecoin[liquidatee];
        require(stableCoinDebt > 0, "No stablecoin debt to liquidate");

        uint256 liquidationBonus = (collateralAmount * LIQUIDATION_BONUS) / 100;
        uint256 totalLiquidationReward = collateralAmount + liquidationBonus;

        if (totalLiquidationReward > collateralAmount) {
            totalLiquidationReward = collateralAmount;
        }

        require(wBTC.transfer(msg.sender, totalLiquidationReward), "Transfer failed");
        collateralAmounts[liquidatee] = 0;

        stableCoin.burnFrom(liquidatee, stableCoinDebt);
        mintedStablecoin[liquidatee] = 0;

        emit Liquidated(liquidatee, msg.sender, collateralAmount, liquidationBonus);
    }

    function _mintSTC(uint256 usdValue) internal {
        uint256 mintSTCAmount = (usdValue * COLLATERAL_FACTOR) / 100;
        require(mintSTCAmount > 0, "Mint amount must be greater than zero");

        stableCoin.mint(msg.sender, mintSTCAmount);
        mintedStablecoin[msg.sender] += mintSTCAmount;
    }

    function _burnSTC(uint256 usdValue) internal {
        uint256 mintSTCAmount = (usdValue * COLLATERAL_FACTOR) / 100;
        require(mintSTCAmount > 0, "Burn amount must be greater than zero");
        require(mintedStablecoin[msg.sender] >= mintSTCAmount, "Insufficient stablecoin balance");

        stableCoin.burnFrom(msg.sender, mintSTCAmount);
        mintedStablecoin[msg.sender] -= mintSTCAmount;
    }

    function _checkHealthFactor() internal view returns (uint256 healthFactor) {
        return _checkHealthFactorForUser(msg.sender);
    }

    function _checkHealthFactorForUser(address user) internal view returns (uint256 healthFactor) {
        uint256 collateralValue = _getUSDValue(collateralAmounts[user]);
        uint256 stableCoinValue = mintedStablecoin[user] * PRECISION;

        if (collateralValue == 0 || stableCoinValue == 0) {
            return type(uint256).max;
        }

        healthFactor = (collateralValue * PRECISION) / stableCoinValue;
        return healthFactor;
    }

    function _getwBTCPrice() internal view returns (uint256 price) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(wBTCPriceFeed);
        (uint80 roundId, int256 priceInt,, uint256 updatedAt, uint80 answeredInRound) = priceFeed.latestRoundData();

        require(priceInt > 0, "Invalid price");
        require(updatedAt > 0, "Round not complete");
        require(block.timestamp - updatedAt <= PRICE_STALENESS_THRESHOLD, "Price data is stale");
        require(answeredInRound >= roundId, "Stale price");

        return uint256(priceInt);
    }

    function _getUSDValue(uint256 _amount) internal view returns (uint256 usdValue) {
        return ((uint256(_getwBTCPrice()) * ADDITIONAL_FEED_PRECISION) * _amount) / PRECISION;
    }

    function _getwBTCDecimals() internal view returns (uint8 decimals) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(wBTCPriceFeed);
        return priceFeed.decimals();
    }

    function getUserHealthFactor(address user) external view returns (uint256) {
        return _checkHealthFactorForUser(user);
    }

    function getCollateralValueInUSD(address user) external view returns (uint256) {
        return _getUSDValue(collateralAmounts[user]);
    }

    function getCurrentwBTCPrice() external view returns (uint256) {
        return _getwBTCPrice();
    }

    function getAccountInformation(address user)
        external
        view
        returns (uint256 totalStableCoinMinted, uint256 collateralValueInUsd)
    {
        totalStableCoinMinted = mintedStablecoin[user];
        collateralValueInUsd = _getUSDValue(collateralAmounts[user]);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function emergencyWithdraw(address token, uint256 amount) external onlyOwner whenPaused {
        require(token != address(0), "Invalid token address");
        IERC20(token).transfer(owner(), amount);
    }
}
