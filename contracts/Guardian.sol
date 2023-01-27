// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";

error Guardian__InvalidAmount(uint amount);
error Guardian__TransactionFailed();
error Guardian__DailyTransferLimitExceed(uint amount);

contract Guardian is Ownable {
    // * STATE VARIABLES
    uint256 private dailyTransferLimit;

    address[] private guardians;

    // * FUNCTIONS
    constructor() {
        dailyTransferLimit = 1 ether;
    }

    fallback() external payable {}

    receive() external payable {}

    function addGuardians(address[] memory newGuardians) external onlyOwner {
        for (uint256 i = 0; i < newGuardians.length; i++) {
            guardians.push(newGuardians[i]);
        }
    }

    function addGuardian(address guardian) external onlyOwner {
        guardians.push(guardian);
    }

    function removeGuardian(address guardian) external onlyOwner {
        address[] memory guardiansCopy = guardians;

        // * for local arrays we need to declare the size at the initialization time.
        // * we are removing the 1 guardian so the updated array will be less than 1 the length of existing array.
        address[] memory updatedCopy = new address[](guardiansCopy.length - 1);
        uint256 index = 0;

        // * using this variable so we should not update the state variable if address does not exits.
        bool exist = false;

        for (uint256 i = 0; i < guardiansCopy.length; i++) {
            if (guardiansCopy[i] == guardian) {
                exist = true;
                continue;
            } else {
                updatedCopy[index] = guardiansCopy[i];
                index++;
            }
        }

        if (exist) {
            guardians = updatedCopy;
        }
    }

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

    function getGuardians() external view returns (address[] memory) {
        return guardians;
    }
}
