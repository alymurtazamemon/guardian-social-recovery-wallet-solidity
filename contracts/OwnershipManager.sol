// SPDX-License-Identifier: MIT

import "./GuardiansManager.sol";

pragma solidity ^0.8.17;

error OwnershipManager__AddressAlreadyAnOwner(address newOwner);
error OwnershipManager__GuardiansListIsEmpty();
error OwnershipManager__AddressNotFoundAsGuardian(address caller);
error OwnershipManager__UpdateNotRequested();
error OwnershipManager__AlreadyConfirmedByGuardian(address guardian);
error OwnershipManager__RequestTimeExpired();

contract OwnershipManager is GuardiansManager {
    // * STATE VARIABLES
    uint256 private lastOwnerUpdateRequestTime;
    uint256 private ownerUpdateConfirmationTime;
    uint256 private noOfConfirmations;

    bool private isOwnerUpdateRequested;

    address private tempAddress;

    mapping(address => bool) private isOwnershipConfimedByGuardian;

    // * FUNCTIONS
    constructor() {
        ownerUpdateConfirmationTime = 2 hours;
    }

    function requestToUpdateOwner(address newOwnerAddress) external {
        if (newOwnerAddress == owner()) {
            revert OwnershipManager__AddressAlreadyAnOwner(newOwnerAddress);
        }

        if (guardians.length <= 0) {
            revert OwnershipManager__GuardiansListIsEmpty();
        }

        if (!doesGuardianExist(msg.sender)) {
            revert OwnershipManager__AddressNotFoundAsGuardian(msg.sender);
        }

        lastOwnerUpdateRequestTime = block.timestamp;
        tempAddress = newOwnerAddress;
        isOwnerUpdateRequested = true;
    }

    function confirmUpdateOwnerRequest() external {
        if (guardians.length <= 0) {
            revert OwnershipManager__GuardiansListIsEmpty();
        }

        if (!isOwnerUpdateRequested) {
            revert OwnershipManager__UpdateNotRequested();
        }

        if (isOwnershipConfimedByGuardian[msg.sender]) {
            revert OwnershipManager__AlreadyConfirmedByGuardian(msg.sender);
        }

        if (
            block.timestamp >
            lastOwnerUpdateRequestTime + ownerUpdateConfirmationTime
        ) {
            resetOwnershipVariables();
            revert OwnershipManager__RequestTimeExpired();
        }

        if (!doesGuardianExist(msg.sender)) {
            revert OwnershipManager__AddressNotFoundAsGuardian(msg.sender);
        }

        isOwnershipConfimedByGuardian[msg.sender] = true;
        noOfConfirmations++;

        if (noOfConfirmations >= requiredConfirmations) {
            // * Ownable internal function without access restriction.
            _transferOwnership(tempAddress);
            resetOwnershipVariables();
        }
    }

    // * FUNCTION - PRIVATE
    function resetOwnershipVariables() private {
        isOwnerUpdateRequested = false;

        address[] memory guardiansCopy = guardians;

        for (uint256 i = 0; i < guardiansCopy.length; i++) {
            if (isOwnershipConfimedByGuardian[guardiansCopy[i]]) {
                isOwnershipConfimedByGuardian[guardiansCopy[i]] = false;
            }
        }
    }
}
