// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./Errors.sol";

contract GuardiansManager is Ownable, ReentrancyGuard {
    // * STATE VARIABLES
    uint256 private addGuardianDelay;
    uint256 private lastGuardianAddTime;
    uint256 private changeGuardianDelay;
    uint256 private lastGuardianChangeTime;
    uint256 private removeGuardianDelay;
    uint256 private lastGuardianRemovalTime;

    uint256 internal requiredConfirmations;

    address[] internal guardians;

    // * FUNCTIONS
    constructor() {
        lastGuardianAddTime = block.timestamp;
        addGuardianDelay = 1 days;
        lastGuardianChangeTime = block.timestamp;
        changeGuardianDelay = 1 days;
        lastGuardianRemovalTime = block.timestamp;
        removeGuardianDelay = 3 days;
    }

    // * FUNCTIONS - EXTERNAL
    function addGuardian(address guardian) external onlyOwner nonReentrant {
        if (block.timestamp < lastGuardianAddTime + addGuardianDelay) {
            revert Error__CanOnlyAddAfterDelayPeriod("GuardiansManager");
        }

        guardians.push(guardian);
        lastGuardianAddTime = block.timestamp;
        updateRequiredConfirmations();
    }

    function changeGuardian(
        address from,
        address to
    ) external onlyOwner nonReentrant {
        if (block.timestamp < lastGuardianChangeTime + changeGuardianDelay) {
            revert Error__CanOnlyChangeAfterDelayPeriod("GuardiansManager");
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
            revert Error__GuardianDoesNotExist("GuardiansManager");
        }
    }

    function removeGuardian(address guardian) external onlyOwner nonReentrant {
        if (guardians.length <= 0) {
            revert Error__GuardiansListIsEmpty("GuardiansManager");
        }

        if (block.timestamp < lastGuardianRemovalTime + removeGuardianDelay) {
            revert Error__CanOnlyRemoveAfterDelayPeriod("GuardiansManager");
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
            revert Error__GuardianDoesNotExist("GuardiansManager");
        }
    }

    // * FUNCTION - PRIVATE

    function updateRequiredConfirmations() private {
        requiredConfirmations = (guardians.length / 2) + 1;
    }

    // * FUNCTIONS - VIEW & PURE - EXTERNAL

    function getLastGuardianAddTime() external view returns (uint256) {
        return lastGuardianAddTime;
    }

    function getAddGuardianDelay() external view returns (uint256) {
        return addGuardianDelay;
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

    function getGuardians() external view returns (address[] memory) {
        return guardians;
    }

    // * FUNCTIONS - VIEW & PURE - INTERNAL

    function doesGuardianExist(address caller) internal view returns (bool) {
        address[] memory guardiansCopy = guardians;

        for (uint256 i = 0; i < guardiansCopy.length; i++) {
            if (caller == guardiansCopy[i]) {
                return true;
            }
        }

        return false;
    }
}
