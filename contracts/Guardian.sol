// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";

error Guardian__InvalidAmount(uint amount);
error Guardian__TransactionFailed();
error Guardian__DailyTransferLimitExceed(uint amount);

contract Guardian is Ownable {
    // * STATE VARIABLES
    uint256 private dailyTransferLimit;

    // * FUNCTIONS
    constructor() {
        dailyTransferLimit = 1 ether;
    }

    fallback() external payable {}

    receive() external payable {}

    function send(address to, uint amount) external onlyOwner {
        if (amount <= 0) {
            revert Guardian__InvalidAmount(amount);
        }

        if (amount > dailyTransferLimit) {
            revert Guardian__DailyTransferLimitExceed(amount);
        }

        (bool success, ) = to.call{value: amount}("");
        if (!success) {
            revert Guardian__TransactionFailed();
        }
    }

    function sendAll(address to) external onlyOwner {
        uint256 balance = address(this).balance;

        if (balance > dailyTransferLimit) {
            revert Guardian__DailyTransferLimitExceed(balance);
        }

        (bool success, ) = to.call{value: balance}("");
        if (!success) {
            revert Guardian__TransactionFailed();
        }
    }

    function getDailyTransferLimit() external view returns (uint256) {
        return dailyTransferLimit;
    }
}
