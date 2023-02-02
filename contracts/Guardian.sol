// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "./FundsManager.sol";

error Guardian__AddressAlreadyAnOwner(address newOwner);
error Guardian__GuardiansListIsEmpty();
error Guardian__AddressNotFoundAsGuardian(address caller);

contract Guardian is FundsManager {
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
            revert Guardian__AddressAlreadyAnOwner(newOwnerAddress);
        }

        if (guardians.length <= 0) {
            revert Guardian__GuardiansListIsEmpty();
        }

        if (!doesGuardianExist(msg.sender)) {
            revert Guardian__AddressNotFoundAsGuardian(msg.sender);
        }

        lastOwnerUpdateRequestTime = block.timestamp;
        tempAddress = newOwnerAddress;
        isOwnerUpdateRequested = true;
    }
}
