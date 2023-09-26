//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Seed is ERC20, Ownable {
    mapping (address => bool) hasFauceted;
    constructor() ERC20("Seed", "SEED") {}

    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }

    function faucet(uint256 amount) public {
        require(amount < 1000000000000000000000, "You can only have 10000 SEED for free.");
        require(hasFauceted[msg.sender] != true, "You can only use faucet once.");
        _mint(msg.sender, amount);
        hasFauceted[msg.sender] = true;
    }
}