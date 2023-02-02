// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "./GuardiansManager.sol";

error FundsManager__InvalidAmount(uint amount);
error FundsManager__DailyTransferLimitExceed(uint amount);
error FundsManager__TransactionFailed();
error FundsManager__BalanceIsZero(uint balance);
error FundsManager__InvalidLimit(uint256 limit);
error FundsManager__UpdateNotRequestedByOwner();
error FundsManager__RequestTimeExpired();
error FundsManager__AlreadyConfirmedByAddress(address guardian);
error FundsManager__AddressNotFoundAsGuardian(address caller);
error FundsManager__RequiredConfirmationsNotMet(uint256 confirmations);

contract FundsManager is GuardiansManager {
    // * STATE VARIABLES
    uint256 private dailyTransferLimit;
    uint256 private tempDailyTransferLimit;
    uint256 private lastDailyTransferUpdateRequestTime;
    uint256 private dailyTransferLimitUpdateConfirmationTime;

    bool private isDailyTransferLimitUpdateRequested;

    mapping(address => bool) private isConfirmedByGuardian;

    // * FUNCTIONS
    constructor() {
        dailyTransferLimit = 1 ether;
        dailyTransferLimitUpdateConfirmationTime = 1 days;
    }

    // * FUNCTIONS - EXTERNAL
    fallback() external payable {}

    receive() external payable {}

    function send(address to, uint amount) external onlyOwner nonReentrant {
        if (amount <= 0) {
            revert FundsManager__InvalidAmount(amount);
        }

        if (amount > dailyTransferLimit) {
            revert FundsManager__DailyTransferLimitExceed(amount);
        }

        (bool success, ) = to.call{value: amount}("");
        if (!success) {
            revert FundsManager__TransactionFailed();
        }
    }

    function sendAll(address to) external onlyOwner nonReentrant {
        uint256 balance = address(this).balance;

        if (balance <= 0) {
            revert FundsManager__BalanceIsZero(balance);
        }

        if (balance > dailyTransferLimit) {
            revert FundsManager__DailyTransferLimitExceed(balance);
        }

        (bool success, ) = to.call{value: balance}("");
        if (!success) {
            revert FundsManager__TransactionFailed();
        }
    }

    function requestToUpdateDailyTransferLimit(
        uint256 limit
    ) external onlyOwner {
        if (limit <= 0) {
            revert FundsManager__InvalidLimit(limit);
        }

        lastDailyTransferUpdateRequestTime = block.timestamp;
        tempDailyTransferLimit = limit;
        isDailyTransferLimitUpdateRequested = true;
    }

    function confirmDailyTransferLimitRequest() external {
        if (guardians.length <= 0) {
            revert GuardiansManager__GuardiansListIsEmpty();
        }

        if (!isDailyTransferLimitUpdateRequested) {
            revert FundsManager__UpdateNotRequestedByOwner();
        }

        if (
            block.timestamp >
            lastDailyTransferUpdateRequestTime +
                dailyTransferLimitUpdateConfirmationTime
        ) {
            resetDailyTransferLimitVariables();
            revert FundsManager__RequestTimeExpired();
        }

        if (isConfirmedByGuardian[msg.sender]) {
            revert FundsManager__AlreadyConfirmedByAddress(msg.sender);
        }

        if (!doesGuardianExist(msg.sender)) {
            revert FundsManager__AddressNotFoundAsGuardian(msg.sender);
        }

        isConfirmedByGuardian[msg.sender] = true;
    }

    function confirmAndUpdate() external onlyOwner {
        if (guardians.length <= 0) {
            revert GuardiansManager__GuardiansListIsEmpty();
        }

        if (!isDailyTransferLimitUpdateRequested) {
            revert FundsManager__UpdateNotRequestedByOwner();
        }

        if (
            block.timestamp >
            lastDailyTransferUpdateRequestTime +
                dailyTransferLimitUpdateConfirmationTime
        ) {
            resetDailyTransferLimitVariables();
            revert FundsManager__RequestTimeExpired();
        }

        address[] memory guardiansCopy = guardians;
        uint256 counter = 0;

        for (uint256 i = 0; i < guardiansCopy.length; i++) {
            if (isConfirmedByGuardian[guardiansCopy[i]]) {
                counter++;
            }
        }

        if (counter < requiredConfirmations) {
            revert FundsManager__RequiredConfirmationsNotMet(
                requiredConfirmations
            );
        }

        dailyTransferLimit = tempDailyTransferLimit;

        resetDailyTransferLimitVariables();
    }

    // * FUNCTIONS - PRIVATE

    function resetDailyTransferLimitVariables() private {
        isDailyTransferLimitUpdateRequested = false;

        address[] memory guardiansCopy = guardians;

        for (uint256 i = 0; i < guardiansCopy.length; i++) {
            if (isConfirmedByGuardian[guardiansCopy[i]]) {
                isConfirmedByGuardian[guardiansCopy[i]] = false;
            }
        }
    }

    // * FUNCTIONS - VIEW & PURE - EXTERNAL

    function getDailyTransferLimit() external view returns (uint256) {
        return dailyTransferLimit;
    }

    function getRequiredConfirmations() external view returns (uint256) {
        return requiredConfirmations;
    }

    function getDailyTransferLimitUpdateRequestStatus()
        external
        view
        returns (bool)
    {
        return isDailyTransferLimitUpdateRequested;
    }

    function getDailyTransferLimitUpdateConfirmationTime()
        external
        view
        returns (uint256)
    {
        return dailyTransferLimitUpdateConfirmationTime;
    }

    function getLastDailyTransferUpdateRequestTime()
        external
        view
        returns (uint256)
    {
        return lastDailyTransferUpdateRequestTime;
    }

    function getGuardianConfirmationStatus(
        address guardian
    ) external view returns (bool) {
        return isConfirmedByGuardian[guardian];
    }
}
