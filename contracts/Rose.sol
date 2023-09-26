//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Rose is ERC20, Ownable {
    constructor() ERC20("Rose", "ROSE") {}

    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }
}