// SPDX-License-Identifier: MIT

import "./GuardiansManager.sol";
import "./Errors.sol";

pragma solidity ^0.8.17;

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
        isOwnerUpdateRequested = true;
    }

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
            resetOwnershipVariables();
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
            resetOwnershipVariables();
        }
    }

    // * FUNCTION - PRIVATE
    function resetOwnershipVariables() private {
        isOwnerUpdateRequested = false;
        noOfConfirmations = 0;

        address[] memory guardiansCopy = guardians;

        for (uint256 i = 0; i < guardiansCopy.length; i++) {
            if (isOwnershipConfimedByGuardian[guardiansCopy[i]]) {
                isOwnershipConfimedByGuardian[guardiansCopy[i]] = false;
            }
        }
    }
}
