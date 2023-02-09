// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "./FundsManager.sol";
import "./OwnershipManager.sol";

/**
 * @title Guardian - A Social Recovery Wallet.
 * @author Ali Murtaza Memon
 * @notice This wallet has additional features compared to a regular wallet, which can prevent the loss of ownership in the event of a private key loss and protect funds from theft.
 * @dev This contract takes Chainlink's Goerli ETH/USD price feed address and GuardianFactory contract address in the constructor.
 */
contract Guardian is FundsManager, OwnershipManager {
    constructor(
        address priceFeed,
        address guardianFactoryAddress
    ) FundsManager(priceFeed) OwnershipManager(guardianFactoryAddress) {}
}
