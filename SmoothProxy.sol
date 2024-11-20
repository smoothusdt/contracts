// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./IERC20.sol";

contract SmoothProxy  {
    address public immutable _admin;

    constructor() {
        _admin = msg.sender;
    }

    function transfer(address tokenAddress, address to, uint256 amount) public {
        require(msg.sender == _admin);
        IERC20(tokenAddress).transfer(to, amount);
    }
}
