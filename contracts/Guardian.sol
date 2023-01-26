// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Guardian is Ownable {
    // * FUNCTIONS
    fallback() external payable {}

    receive() external payable {}
}
