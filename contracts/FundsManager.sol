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

    /**
     * @notice This function will be called by owner to update the daily transfer limit.
     * @dev Only user can call this function.
     * @param limit the value you want to set as a daily transfer limit in wei.
     */
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

    /**
     * @notice This function will be call by Guardians of this wallet to confirm the owner request to update the daily transfer limit.
     */
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

    /**
     * @notice This function will be call the owner to confirm and update the limit after the required no of confirmations by guardians.
     * @dev Only user can call this function.
     */
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

    /**
     * @notice This function will update the existing price feed address which is Chainlink's ETH/USD price feed address initially.
     * @dev This uses the Chainlink's AggregatorV3Interface.
     * @param _priceFeed the address of new price feed address.
     */
    function updateETHUSDPriceFeed(address _priceFeed) external onlyOwner {
        priceFeed = AggregatorV3Interface(_priceFeed);
    }

    // * FUNCTION - PUBLIC

    /**
     * @notice This function helps to reset the variables when the request gets expired.
     * @dev Only owner can call this function.
     * @dev You can use the Chainlink's Keepers to automatically reset the variables when the request gets expire but for now I am doing it manually.
     */
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

    /**
     * @notice This function returns the Chainlink's AggregatorV3Interface price feed address.
     * @return address of price feed.
     */
    function getPriceFeedAddress() external view returns (address) {
        return address(priceFeed);
    }

    /**
     * @notice This function return the balance of the smart contract.
     * @return uint256 value of balance.
     */
    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }

    /**
     * @notice This function returns the baalance of the smart contract in USD.
     * @return uint256 value of balance in usd.
     */
    function getBalanceInUSD() external view returns (uint256) {
        uint256 ethPrice = getPrice();
        uint256 balanceInUSD = (ethPrice * address(this).balance) /
            1000000000000000000;
        return balanceInUSD;
    }

    /**
     * @notice This function returns the daily transfer limit set value in wei.
     * @return uint256 value.
     */
    function getDailyTransferLimit() external view returns (uint256) {
        return dailyTransferLimit;
    }

    /**
     * @notice This function returns the daily transfer limit set value in usd.
     * @return uint256 value in usd.
     */
    function getDailyTransferLimitInUSD() external view returns (uint256) {
        uint256 ethPrice = getPrice();
        uint256 dailyTransferLimitInUSD = (ethPrice * dailyTransferLimit) /
            1000000000000000000;
        return dailyTransferLimitInUSD;
    }

    /**
     * @notice This function returns the no of confirmations required for any task.
     * @return uint256 value.
     */
    function getRequiredConfirmations() external view returns (uint256) {
        return requiredConfirmations;
    }

    /**
     * @notice This function returns the status of daily transfer limit request.
     * @return boolean value
     */
    function getDailyTransferLimitUpdateRequestStatus()
        external
        view
        returns (bool)
    {
        return isDailyTransferLimitUpdateRequested;
    }

    /**
     * @notice This function returns the time till guardian can confirm the request.
     * @return uint256 value.
     */
    function getDailyTransferLimitUpdateConfirmationTime()
        external
        view
        returns (uint256)
    {
        return dailyTransferLimitUpdateConfirmationTime;
    }

    /**
     * @notice This function returns the time when the owner request to update the daily transfer limit.
     * @return uint256 value.
     */
    function getLastDailyTransferUpdateRequestTime()
        external
        view
        returns (uint256)
    {
        return lastDailyTransferUpdateRequestTime;
    }

    /**
     * @notice This function returns the confirmation status of guardian.
     * @param guardian the address of guardian.
     * @return boolean value.
     */
    function getGuardianConfirmationStatus(
        address guardian
    ) external view returns (bool) {
        return isConfirmedByGuardian[guardian];
    }

    // * FUNCTIONS - VIEW & PURE - PUBLIC

    /**
     * @notice This function returns the current price of ETH/USD.
     * @dev Chainlink's AggregatorV3Interface price feed is used to get the current price of ETH/USD.
     * @return uint256 value.
     */
    function getPrice() public view returns (uint256) {
        (, int256 answer, , , ) = priceFeed.latestRoundData();
        // ETH/USD rate in 18 digit
        return uint256(answer * 10000000000);
    }
}
