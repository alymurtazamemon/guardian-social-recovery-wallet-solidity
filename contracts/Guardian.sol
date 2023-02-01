// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "hardhat/console.sol";

error Guardian__InvalidAmount(uint amount);
error Guardian__DailyTransferLimitExceed(uint amount);
error Guardian__TransactionFailed();
error Guardian__BalanceIsZero(uint balance);
error Guardian__InvalidGuardiansList(address[] addressesList);
error Guardian__CanOnlyChangeAfterDelayPeriod();
error Guardian__GuardianDoesNotExist();
error Guardian__GuardiansListIsEmpty();
error Guardian__CanOnlyRemoveAfterDelayPeriod();
error Guardian__InvalidLimit(uint256 limit);
error Guardian__UpdateNotRequestedByOwner();
error Guardian__RequestTimeExpired();
error Guardian__AlreadyConfirmedByAddress(address guardian);
error Guardian__AddressNotFoundAsGuardian(address caller);
error Guardian__NotConfirmedByAllGuardians();

contract Guardian is Ownable, ReentrancyGuard {
    // * STATE VARIABLES
    uint256 private dailyTransferLimit;
    uint256 private tempDailyTransferLimit;
    uint256 private lastDailyTransferUpdateRequestTime;
    uint256 private dailyTransferLimitUpdateConfirmationTime;
    uint256 private requiredConfirmations;

    uint256 private changeGuardianDelay;
    uint256 private lastGuardianChangeTime;
    uint256 private removeGuardianDelay;
    uint256 private lastGuardianRemovalTime;

    bool private isDailyTransferLimitUpdateRequested;

    address[] private guardians;

    mapping(address => bool) private isConfirmedByGuardian;

    // * FUNCTIONS
    constructor() {
        dailyTransferLimit = 1 ether;
        dailyTransferLimitUpdateConfirmationTime = 1 days;
        lastGuardianChangeTime = block.timestamp;
        changeGuardianDelay = 1 days;
        lastGuardianRemovalTime = block.timestamp;
        removeGuardianDelay = 3 days;
    }

    // * FUNCTIONS - EXTERNAL

    fallback() external payable {}

    receive() external payable {}

    function send(address to, uint amount) external onlyOwner nonReentrant {
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

    function sendAll(address to) external onlyOwner nonReentrant {
        uint256 balance = address(this).balance;

        if (balance <= 0) {
            revert Guardian__BalanceIsZero(balance);
        }

        if (balance > dailyTransferLimit) {
            revert Guardian__DailyTransferLimitExceed(balance);
        }

        (bool success, ) = to.call{value: balance}("");
        if (!success) {
            revert Guardian__TransactionFailed();
        }
    }

    function addGuardians(
        address[] memory newGuardians
    ) external onlyOwner nonReentrant {
        if (newGuardians.length <= 0) {
            revert Guardian__InvalidGuardiansList(newGuardians);
        }

        for (uint256 i = 0; i < newGuardians.length; i++) {
            guardians.push(newGuardians[i]);
        }
        updateRequiredConfirmations();
    }

    function addGuardian(address guardian) external onlyOwner nonReentrant {
        guardians.push(guardian);
        updateRequiredConfirmations();
    }

    function changeGuardian(
        address from,
        address to
    ) external onlyOwner nonReentrant {
        if (block.timestamp < lastGuardianChangeTime + changeGuardianDelay) {
            revert Guardian__CanOnlyChangeAfterDelayPeriod();
        }

        address[] memory guardiansCopy = guardians;

        // * using this variable so we should not update the state variable if address does not exits.
        bool exist = false;

        for (uint256 i = 0; i < guardiansCopy.length; i++) {
            if (guardiansCopy[i] == from) {
                exist = true;
                guardiansCopy[i] = to;
                break;
            }
        }

        if (exist) {
            guardians = guardiansCopy;
            lastGuardianChangeTime = block.timestamp;
        } else {
            revert Guardian__GuardianDoesNotExist();
        }
    }

    function removeGuardian(address guardian) external onlyOwner nonReentrant {
        if (guardians.length <= 0) {
            revert Guardian__GuardiansListIsEmpty();
        }

        if (block.timestamp < lastGuardianRemovalTime + removeGuardianDelay) {
            revert Guardian__CanOnlyRemoveAfterDelayPeriod();
        }

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
            } else if (i != updatedCopy.length) {
                updatedCopy[index] = guardiansCopy[i];
                index++;
            }
        }

        if (exist) {
            guardians = updatedCopy;
            lastGuardianRemovalTime = block.timestamp;
        } else {
            revert Guardian__GuardianDoesNotExist();
        }
    }

    function requestToUpdateDailyTransferLimit(
        uint256 limit
    ) external onlyOwner {
        if (limit <= 0) {
            revert Guardian__InvalidLimit(limit);
        }

        lastDailyTransferUpdateRequestTime = block.timestamp;
        tempDailyTransferLimit = limit;
        isDailyTransferLimitUpdateRequested = true;
    }

    function confirmDailyTransferLimitRequest() external {
        if (!isDailyTransferLimitUpdateRequested) {
            revert Guardian__UpdateNotRequestedByOwner();
        }

        if (
            block.timestamp >
            lastDailyTransferUpdateRequestTime +
                dailyTransferLimitUpdateConfirmationTime
        ) {
            resetDailyTransferLimitVariables();
            revert Guardian__RequestTimeExpired();
        }

        if (isConfirmedByGuardian[msg.sender]) {
            revert Guardian__AlreadyConfirmedByAddress(msg.sender);
        }

        // * if the length of guardians will be zero then the execution will not run the doesGuardianExist function and revert.
        if (guardians.length <= 0 || !doesGuardianExist(msg.sender)) {
            revert Guardian__AddressNotFoundAsGuardian(msg.sender);
        }

        isConfirmedByGuardian[msg.sender] = true;
    }

    function confirmAndUpdate() external onlyOwner {
        if (!isDailyTransferLimitUpdateRequested) {
            revert Guardian__UpdateNotRequestedByOwner();
        }

        if (
            block.timestamp >
            lastDailyTransferUpdateRequestTime +
                dailyTransferLimitUpdateConfirmationTime
        ) {
            resetDailyTransferLimitVariables();
            revert Guardian__RequestTimeExpired();
        }

        if (isConfirmedByGuardian[msg.sender]) {
            revert Guardian__AlreadyConfirmedByAddress(msg.sender);
        }

        address[] memory guardiansCopy = guardians;
        bool confirmed = true;

        for (uint256 i = 0; i < guardiansCopy.length; i++) {
            if (!isConfirmedByGuardian[guardiansCopy[i]]) {
                confirmed = false;
                break;
            }
        }

        if (!confirmed) {
            revert Guardian__NotConfirmedByAllGuardians();
        }

        dailyTransferLimit = tempDailyTransferLimit;

        resetDailyTransferLimitVariables();
    }

    // * FUNCTIONS - PRIVATE

    function updateRequiredConfirmations() private {
        requiredConfirmations = (guardians.length / 2) + 1;
    }

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

    function getLastGuardianChangeTime() external view returns (uint256) {
        return lastGuardianChangeTime;
    }

    function getChangeGuardianDelay() external view returns (uint256) {
        return changeGuardianDelay;
    }

    function getLastGuardianRemovalTime() external view returns (uint256) {
        return lastGuardianRemovalTime;
    }

    function getRemoveGuardianDelay() external view returns (uint256) {
        return removeGuardianDelay;
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

    function getGuardians() external view returns (address[] memory) {
        return guardians;
    }

    // * FUNCTIONS - VIEW & PURE - PRIVATE

    function doesGuardianExist(address caller) private view returns (bool) {
        address[] memory guardiansCopy = guardians;

        for (uint256 i = 0; i < guardiansCopy.length; i++) {
            if (caller == guardiansCopy[i]) {
                return true;
            }
        }

        return false;
    }
}
