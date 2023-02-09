// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./Errors.sol";
import "hardhat/console.sol";

/**
 * @title GuardiansManager - This is the part of Guardian smart contract which handles Guardians Management.
 * @author Ali Murtaza Memon
 * @notice This smart contract handles add, change and remove guardians features for Guardian smart contract.
 * @custom:hackathon This project is for Alchemy University Hackathon.
 */
contract GuardiansManager is Ownable, ReentrancyGuard {
    // * STATE VARIABLES
    uint256 private addGuardianDelay;
    uint256 private lastGuardianAddTime;
    uint256 private changeGuardianDelay;
    uint256 private lastGuardianChangeTime;
    uint256 private removeGuardianDelay;
    uint256 private lastGuardianRemovalTime;
    uint256 private contractDeployTime;

    uint256 public requiredConfirmations;

    address[] internal guardians;

    // * FUNCTIONS
    constructor() {
        contractDeployTime = block.timestamp;
        lastGuardianAddTime = block.timestamp;
        addGuardianDelay = 1 days;
        lastGuardianChangeTime = block.timestamp;
        changeGuardianDelay = 1 days;
        lastGuardianRemovalTime = block.timestamp;
        removeGuardianDelay = 3 days;
    }

    // * FUNCTIONS - EXTERNAL
    /**
     * @notice This function add new guardian after delay period and update the required confirmations.
     * @dev Only owner can call this function.
     * @dev This uses the Reentrancy Guard.
     * @param guardian will be the address of new guardian.
     */
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
        if (block.timestamp < lastGuardianRemovalTime + removeGuardianDelay) {
            revert Error__CanOnlyRemoveAfterDelayPeriod("GuardiansManager");
        }

        if (guardians.length <= 0) {
            revert Error__GuardiansListIsEmpty("GuardiansManager");
        }

        if (!doesGuardianExist(guardian)) {
            revert Error__GuardianDoesNotExist("GuardiansManager");
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
            } else {
                updatedCopy[index] = guardiansCopy[i];
                index++;
            }
        }

        if (exist) {
            guardians = updatedCopy;
            lastGuardianRemovalTime = block.timestamp;
        }
    }

    // * FUNCTION - PRIVATE

    function updateRequiredConfirmations() private {
        requiredConfirmations = (guardians.length / 2) + 1;
    }

    // * FUNCTIONS - VIEW & PURE - EXTERNAL

    function getLastGuardianAddTime() external view returns (uint256) {
        return
            lastGuardianAddTime == contractDeployTime ? 0 : lastGuardianAddTime;
    }

    function getAddGuardianDelay() external view returns (uint256) {
        return addGuardianDelay;
    }

    function getLastGuardianChangeTime() external view returns (uint256) {
        return
            lastGuardianChangeTime == contractDeployTime
                ? 0
                : lastGuardianChangeTime;
    }

    function getChangeGuardianDelay() external view returns (uint256) {
        return changeGuardianDelay;
    }

    function getLastGuardianRemovalTime() external view returns (uint256) {
        return
            lastGuardianRemovalTime == contractDeployTime
                ? 0
                : lastGuardianRemovalTime;
    }

    function getRemoveGuardianDelay() external view returns (uint256) {
        return removeGuardianDelay;
    }

    function getGuardians() external view returns (address[] memory) {
        return guardians;
    }

    // * FUNCTIONS - VIEW & PURE - PUBLIC

    function doesGuardianExist(address caller) public view returns (bool) {
        address[] memory guardiansCopy = guardians;

        for (uint256 i = 0; i < guardiansCopy.length; i++) {
            if (caller == guardiansCopy[i]) {
                return true;
            }
        }

        return false;
    }
}
