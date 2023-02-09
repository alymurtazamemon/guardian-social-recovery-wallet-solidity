// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "./Guardian.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

error GuardianFactory__WalletAlreadyExist();
error GuardianFactory__OwnerContractNotFound();
error GuardianFactory__AddressNotFoundAsGuardian(address caller);

/**
 * @title GuardianFactory - Is a factory which handles the creation of new Guardian smart contract and storage of these contracts.
 * @author Ali Murtaza Memon
 * @notice This smart contract creates new Guardian smart contract and transfer the ownership to caller and update the ownership later on request.
 * @dev Ownership of contract here will not affect the Guardian individual ownership, here we are working as a marketplace for Guardian wallets.
 * @dev This smart contract take Chainlink's Goerli ETH/USD price feed as a parameter in the constructor and pass it to Guardian smart contract.
 * @custom:hackathon This project is for Alchemy University Hackathon.
 */
contract GuardianFactory {
    // * STATE VARIABLES
    struct Wallet {
        address owner;
        address contractAddress;
    }

    Wallet[] public wallets;

    AggregatorV3Interface private priceFeed;

    constructor(address _priceFeed) {
        priceFeed = AggregatorV3Interface(_priceFeed);
    }

    fallback() external payable {}

    receive() external payable {}

    /**
     * @notice This function creates a new Guardian wallet and transfer its ownership to caller.
     */
    function createWallet() external {
        // * if already created then revert.
        if (getWallet() != address(0)) {
            revert GuardianFactory__WalletAlreadyExist();
        }

        Guardian guardian = new Guardian(address(priceFeed), address(this));
        guardian.transferOwnership(msg.sender);
        wallets.push(Wallet(guardian.owner(), address(guardian)));
    }

    function updateWalletOwner(
        address contractAddress,
        address newOwner
    ) external {
        Wallet[] memory walletsCopy = wallets;

        for (uint i = 0; i < walletsCopy.length; i++) {
            if (contractAddress == walletsCopy[i].contractAddress) {
                Guardian guardian = Guardian(payable(contractAddress));

                if (guardian.owner() == newOwner) {
                    wallets[i].owner = newOwner;
                }
            }
        }
    }

    function getContractAddressByGuardian(
        address ownerAddress
    ) external view returns (address) {
        Wallet[] memory walletsCopy = wallets;

        address contractAddress;

        for (uint i = 0; i < walletsCopy.length; i++) {
            if (ownerAddress == walletsCopy[i].owner) {
                contractAddress = walletsCopy[i].contractAddress;
            }
        }

        if (contractAddress == address(0)) {
            revert GuardianFactory__OwnerContractNotFound();
        } else {
            Guardian guardian = Guardian(payable(contractAddress));

            if (guardian.doesGuardianExist(msg.sender)) {
                return contractAddress;
            } else {
                revert GuardianFactory__AddressNotFoundAsGuardian(msg.sender);
            }
        }
    }

    function getWallet() public view returns (address) {
        Wallet[] memory walletsCopy = wallets;

        for (uint i = 0; i < walletsCopy.length; i++) {
            if (msg.sender == walletsCopy[i].owner) {
                return walletsCopy[i].contractAddress;
            }
        }

        return address(0);
    }

    function getWalletsLength() external view returns (uint256) {
        return wallets.length;
    }
}
