// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./GuardiansManager.sol";
import "./Errors.sol";

/**
 * @title FundsManager - This is the part of Guardian smart contract which manages the Funds of the smart contract.
 * @author Ali Murtaza Memon
 * @notice This smart contract handles deposit, transfer, daily transfer update and guardians confirmations features for Guardian smart contract.
 * @custom:hackathon This project is for Alchemy University Hackathon.
 */
contract FundsManager is GuardiansManager {
    // * STATE VARIABLES
    uint256 private dailyTransferLimit;
    uint256 private tempDailyTransferLimit;
    uint256 private lastDailyTransferUpdateRequestTime;
    uint256 private dailyTransferLimitUpdateConfirmationTime;

    bool private isDailyTransferLimitUpdateRequested;

    mapping(address => bool) private isConfirmedByGuardian;

    AggregatorV3Interface private priceFeed;

    // * FUNCTIONS
    constructor(address _priceFeed) {
        priceFeed = AggregatorV3Interface(_priceFeed);
        dailyTransferLimit = 1 ether;
        dailyTransferLimitUpdateConfirmationTime = 1 days;
    }

    // * FUNCTIONS - EXTERNAL
    fallback() external payable {}

    receive() external payable {}

    /**
     * @notice This function transfers the fund to other address.
     * @dev Only owner can call this function.
     * @dev This uses the Reentrancy Guard.
     * @param to the address of user you want to send funds to.
     * @param amount the value in wei you want to send.
     */
    function send(address to, uint amount) external onlyOwner nonReentrant {
        if (amount <= 0) {
            revert Error__InvalidAmount("FundsManager", amount);
        }

        if (amount > dailyTransferLimit) {
            revert Error__DailyTransferLimitExceed("FundsManager", amount);
        }

        (bool success, ) = to.call{value: amount}("");
        if (!success) {
            revert Error__TransactionFailed("FundsManager");
        }
    }

    /**
     * @notice This function trnasfers all of the contract's funds to provided address.
     * @dev Only user can call this function.
     * @dev This uses the Reentrancy Guard.
     * @param to the address of the user you want to send funds to.
     */
    function sendAll(address to) external onlyOwner nonReentrant {
        uint256 balance = address(this).balance;

        if (balance <= 0) {
            revert Error__BalanceIsZero("FundsManager", balance);
        }

        if (balance > dailyTransferLimit) {
            revert Error__DailyTransferLimitExceed("FundsManager", balance);
        }

        (bool success, ) = to.call{value: balance}("");
        if (!success) {
            revert Error__TransactionFailed("FundsManager");
        }
    }

    function requestToUpdateDailyTransferLimit(
        uint256 limit
    ) external onlyOwner {
        if (limit <= 0) {
            revert Error__InvalidLimit("FundsManager", limit);
        }

        lastDailyTransferUpdateRequestTime = block.timestamp;
        tempDailyTransferLimit = limit;
        isDailyTransferLimitUpdateRequested = true;
    }

    function confirmDailyTransferLimitRequest() external {
        if (guardians.length <= 0) {
            revert Error__GuardiansListIsEmpty("FundsManager");
        }

        if (!isDailyTransferLimitUpdateRequested) {
            revert Error__UpdateNotRequestedByOwner("FundsManager");
        }

        if (
            block.timestamp >
            lastDailyTransferUpdateRequestTime +
                dailyTransferLimitUpdateConfirmationTime
        ) {
            revert Error__RequestTimeExpired("FundsManager");
        }

        if (isConfirmedByGuardian[msg.sender]) {
            revert Error__AlreadyConfirmedByGuardian(
                "FundsManager",
                msg.sender
            );
        }

        if (!doesGuardianExist(msg.sender)) {
            revert Error__AddressNotFoundAsGuardian("FundsManager", msg.sender);
        }

        isConfirmedByGuardian[msg.sender] = true;
    }

    function confirmAndUpdate() external onlyOwner {
        if (guardians.length <= 0) {
            revert Error__GuardiansListIsEmpty("FundsManager");
        }

        if (!isDailyTransferLimitUpdateRequested) {
            revert Error__UpdateNotRequestedByOwner("FundsManager");
        }

        if (
            block.timestamp >
            lastDailyTransferUpdateRequestTime +
                dailyTransferLimitUpdateConfirmationTime
        ) {
            revert Error__RequestTimeExpired("FundsManager");
        }

        address[] memory guardiansCopy = guardians;
        uint256 counter = 0;

        for (uint256 i = 0; i < guardiansCopy.length; i++) {
            if (isConfirmedByGuardian[guardiansCopy[i]]) {
                counter++;
            }
        }

        if (counter < requiredConfirmations) {
            revert Error__RequiredConfirmationsNotMet(
                "FundsManager",
                requiredConfirmations
            );
        }

        dailyTransferLimit = tempDailyTransferLimit;

        resetDailyTransferLimitVariables();
    }

    function updateETHUSDPriceFeed(address _priceFeed) external onlyOwner {
        priceFeed = AggregatorV3Interface(_priceFeed);
    }

    // * FUNCTION - PUBLIC

    function resetDailyTransferLimitVariables() public onlyOwner {
        isDailyTransferLimitUpdateRequested = false;

        address[] memory guardiansCopy = guardians;

        for (uint256 i = 0; i < guardiansCopy.length; i++) {
            if (isConfirmedByGuardian[guardiansCopy[i]]) {
                isConfirmedByGuardian[guardiansCopy[i]] = false;
            }
        }
    }

    // * FUNCTIONS - VIEW & PURE - EXTERNAL

    function getPriceFeedAddress() external view returns (address) {
        return address(priceFeed);
    }

    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }

    function getBalanceInUSD() external view returns (uint256) {
        uint256 ethPrice = getPrice();
        uint256 balanceInUSD = (ethPrice * address(this).balance) /
            1000000000000000000;
        return balanceInUSD;
    }

    function getDailyTransferLimit() external view returns (uint256) {
        return dailyTransferLimit;
    }

    function getDailyTransferLimitInUSD() external view returns (uint256) {
        uint256 ethPrice = getPrice();
        uint256 dailyTransferLimitInUSD = (ethPrice * dailyTransferLimit) /
            1000000000000000000;
        return dailyTransferLimitInUSD;
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

    // * FUNCTIONS - VIEW & PURE - PUBLIC

    function getPrice() public view returns (uint256) {
        (, int256 answer, , , ) = priceFeed.latestRoundData();
        // ETH/USD rate in 18 digit
        return uint256(answer * 10000000000);
    }
}
