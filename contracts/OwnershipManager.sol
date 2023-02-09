// SPDX-License-Identifier: MIT

import "./GuardiansManager.sol";
import "./Errors.sol";
import "./GuardianFactory.sol";

pragma solidity ^0.8.17;

/**
 * @title OwnershipManager - This is the part of Guardian smart contract which handles the Ownership Management.
 * @author Ali Murtaza Memon
 * @notice This smart contract handles the request and guardians confirmations about updating the owner features for Guardian smart contract.
 * @custom:hackathon This project is for Alchemy University Hackathon.
 */
contract OwnershipManager is GuardiansManager {
    // * STATE VARIABLES
    uint256 private lastOwnerUpdateRequestTime;
    uint256 private ownerUpdateConfirmationTime;
    uint256 private noOfConfirmations;

    bool private isOwnerUpdateRequested;

    address private tempAddress;
    address payable private guardianFactoryAddress;

    mapping(address => bool) private isOwnershipConfimedByGuardian;

    // * FUNCTIONS
    constructor(address _guardianFactoryAddress) {
        ownerUpdateConfirmationTime = 2 hours;
        guardianFactoryAddress = payable(_guardianFactoryAddress);
    }

    /**
     * @notice This function will be used by one of guardian of this wallet to request to update the owner of the wallet.
     * @param newOwnerAddress the address of new owner for this wallet.
     */
    function requestToUpdateOwner(address newOwnerAddress) external {
        if (newOwnerAddress == owner()) {
            revert Error__AddressAlreadyAnOwner(
                "OwnershipManager",
                newOwnerAddress
            );
        }

        if (guardians.length <= 0) {
            revert Error__GuardiansListIsEmpty("OwnershipManager");
        }

        if (!doesGuardianExist(msg.sender)) {
            revert Error__AddressNotFoundAsGuardian(
                "OwnershipManager",
                msg.sender
            );
        }

        lastOwnerUpdateRequestTime = block.timestamp;
        tempAddress = newOwnerAddress;
        isOwnershipConfimedByGuardian[msg.sender] = true;
        noOfConfirmations++;
        isOwnerUpdateRequested = true;
    }

    /**
     * @notice This function will be used by other guardians to confirm the request to update the owner by one of the guardians.
     */
    function confirmUpdateOwnerRequest() external {
        if (guardians.length <= 0) {
            revert Error__GuardiansListIsEmpty("OwnershipManager");
        }

        if (!isOwnerUpdateRequested) {
            revert Error__UpdateNotRequested("OwnershipManager");
        }

        if (isOwnershipConfimedByGuardian[msg.sender]) {
            revert Error__AlreadyConfirmedByGuardian(
                "OwnershipManager",
                msg.sender
            );
        }

        if (
            block.timestamp >
            lastOwnerUpdateRequestTime + ownerUpdateConfirmationTime
        ) {
            revert Error__RequestTimeExpired("OwnershipManager");
        }

        if (!doesGuardianExist(msg.sender)) {
            revert Error__AddressNotFoundAsGuardian(
                "OwnershipManager",
                msg.sender
            );
        }

        isOwnershipConfimedByGuardian[msg.sender] = true;
        noOfConfirmations++;

        if (noOfConfirmations >= requiredConfirmations) {
            // * Ownable internal function without access restriction.
            _transferOwnership(tempAddress);
            GuardianFactory(payable(guardianFactoryAddress)).updateWalletOwner(
                address(this),
                tempAddress
            );
            resetOwnershipVariables();
        }
    }

    // * FUNCTION - PUBLIC
    /**
     * @notice This function helps to reset the variables when the request gets expired.
     * @dev You can use the Chainlink's Keepers to automatically reset the variables when the request gets expire but for now I am doing it manually.
     */
    function resetOwnershipVariables() public {
        if (!doesGuardianExist(msg.sender)) {
            revert Error__AddressNotFoundAsGuardian(
                "OwnershipManager",
                msg.sender
            );
        }

        isOwnerUpdateRequested = false;
        noOfConfirmations = 0;

        address[] memory guardiansCopy = guardians;

        for (uint256 i = 0; i < guardiansCopy.length; i++) {
            if (isOwnershipConfimedByGuardian[guardiansCopy[i]]) {
                isOwnershipConfimedByGuardian[guardiansCopy[i]] = false;
            }
        }
    }

    // * FUNCTION - VIEW & PURE
    /**
     * @notice This function the status of owner update request.
     * @return boolean value.
     */
    function getIsOwnerUpdateRequested() external view returns (bool) {
        return isOwnerUpdateRequested;
    }

    /**
     * @notice This function will return the status of guardian confirmation.
     * @param guardian the address of guardian.
     * @return boolean value
     */
    function getIsOwnershipConfimedByGuardian(
        address guardian
    ) external view returns (bool) {
        return isOwnershipConfimedByGuardian[guardian];
    }

    /**
     * @notice This function returns the time when last owner update requested.
     * @return uint256 value.
     */
    function getLastOwnerUpdateRequestTime() external view returns (uint256) {
        return lastOwnerUpdateRequestTime;
    }

    /**
     * @notice This fuction returns the time till guarians can confirm the request.
     * @return uint256 value.
     */
    function getOwnerUpdateConfirmationTime() external view returns (uint256) {
        return ownerUpdateConfirmationTime;
    }

    /**
     * @notice This functin returns the no of confirmation required to perform any task.
     * @return uint256 value
     */
    function getNoOfConfirmations() external view returns (uint256) {
        return noOfConfirmations;
    }
}
