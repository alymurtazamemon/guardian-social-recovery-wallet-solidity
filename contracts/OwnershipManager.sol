// SPDX-License-Identifier: MIT

import "./GuardiansManager.sol";

pragma solidity ^0.8.17;

error OwnershipManager__AddressAlreadyAnOwner(address newOwner);
error OwnershipManager__GuardiansListIsEmpty();
error OwnershipManager__AddressNotFoundAsGuardian(address caller);

contract OwnershipManager is GuardiansManager {
    // * STATE VARIABLES
    uint256 private lastOwnerUpdateRequestTime;
    uint256 private ownerUpdateConfirmationTime;

    bool private isOwnerUpdateRequested;

    address private owner;
    address private tempAddress;

    // * FUNCTIONS
    constructor() {
        owner = msg.sender;
        ownerUpdateConfirmationTime = 2 hours;
    }

    function requestToUpdateOwner(address newOwnerAddress) external {
        if (newOwnerAddress == owner) {
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
}
