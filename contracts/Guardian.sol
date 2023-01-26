// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";

error Guardian__InvalidAmount(uint amount);
error Guardian__TransactionFailed();

contract Guardian is Ownable {
    // * FUNCTIONS
    fallback() external payable {}

    receive() external payable {}

    function send(address to, uint amount) external {
        if (amount <= 0) {
            revert Guardian__InvalidAmount(amount);
        }

        (bool success, ) = to.call{value: amount}("");
        if (!success) {
            revert Guardian__TransactionFailed();
        }
    }
}
