// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./StableCoin.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract StableEngine {
    IERC20 public wBTC;
    StableCoin public stableCoin;

    constructor(address _wBTC, address _stableCoin) {
        wBTC = IERC20(_wBTC);
        stableCoin = StableCoin(_stableCoin);
    }

    function depositCollateral() external {}

    function withdrawCollateral() external {}

    function liquidate() external {}

    function _checkHealthFactor() external view returns (uint256 healthFactor) {}
}
