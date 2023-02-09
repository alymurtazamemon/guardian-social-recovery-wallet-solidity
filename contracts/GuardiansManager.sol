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

    /**
     * @notice This function change the existing guardian with new guardian after delay period.
     * @dev Only owner can call this function.
     * @dev This uses the Reentrancy Guard.
     * @param from the address of existing guardian.
     * @param to the address of new guardian.
     */
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

    /**
     * @notice This function removes the existing guardian from the guardians list.
     * @dev Only user can call this function.
     * @dev This uses the Reentrancy Guard.
     * @param guardian the address of existing guardian.
     */
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
    /**
     * @dev this function updates the required confirmations based on No Of Guardians.
     */
    function updateRequiredConfirmations() private {
        requiredConfirmations = (guardians.length / 2) + 1;
    }

    // * FUNCTIONS - VIEW & PURE - EXTERNAL

    /**
     * @notice This function returns the time when last guardian added in the list. The return value will be zero if no any guardian added.
     * @return uint256 value
     */
    function getLastGuardianAddTime() external view returns (uint256) {
        return
            lastGuardianAddTime == contractDeployTime ? 0 : lastGuardianAddTime;
    }

    /**
     * @notice This function will return the delay time required between adding guadians. Initially it is set to 1 day.
     * @return uint256 value.
     */
    function getAddGuardianDelay() external view returns (uint256) {
        return addGuardianDelay;
    }

    /**
     * @notice This function will return the time when the last guardian changed. The return value will be zero if guardians are never changed.
     * @return uint256 value
     */
    function getLastGuardianChangeTime() external view returns (uint256) {
        return
            lastGuardianChangeTime == contractDeployTime
                ? 0
                : lastGuardianChangeTime;
    }

    /**
     * @notice This function will return the delay time required between changing guardians. Initially it is set to 1 day.
     * @return uint256 value.
     */
    function getChangeGuardianDelay() external view returns (uint256) {
        return changeGuardianDelay;
    }

    /**
     * @notice This function will return the time when the last guardian was removed. The return value will be zero is guardians are never removed.
     * @return uint256 value.
     */
    function getLastGuardianRemovalTime() external view returns (uint256) {
        return
            lastGuardianRemovalTime == contractDeployTime
                ? 0
                : lastGuardianRemovalTime;
    }

    /**
     * @notice This function will return the delay time required to remove between guardians. Initially it is set to 3 days.
     * @return uint256 value
     */
    function getRemoveGuardianDelay() external view returns (uint256) {
        return removeGuardianDelay;
    }

    /**
     * @notice This function returns the list of guardians of the wallet.
     * @return array of addresses.
     */
    function getGuardians() external view returns (address[] memory) {
        return guardians;
    }

    // * FUNCTIONS - VIEW & PURE - PUBLIC

    /**
     * @notice This function checks whether the address exist as a guardian or not.
     * @param caller the address which you want to check for guardian.
     * @return boolean value
     */
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
