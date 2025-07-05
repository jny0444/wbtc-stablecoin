// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

contract StableCoin is ERC20, ERC20Burnable {
    constructor() ERC20("Randi Coin", "RAND") {}

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}
