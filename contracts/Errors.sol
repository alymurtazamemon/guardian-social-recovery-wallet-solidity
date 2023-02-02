// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

error Error__AddressAlreadyAnOwner(string location, address addr);
error Error__GuardiansListIsEmpty(string location);
error Error__AddressNotFoundAsGuardian(string location, address addr);
error Error__UpdateNotRequested(string location);
error Error__AlreadyConfirmedByGuardian(string location, address guardian);
error Error__RequestTimeExpired(string location);
error Error__InvalidAmount(string location, uint amount);
error Error__DailyTransferLimitExceed(string location, uint amount);
error Error__TransactionFailed(string location);
error Error__BalanceIsZero(string location, uint balance);
error Error__InvalidLimit(string location, uint256 limit);
error Error__UpdateNotRequestedByOwner(string location);
error Error__RequiredConfirmationsNotMet(
    string location,
    uint256 confirmations
);
error Error__InvalidGuardiansList(string location, address[] addressesList);
error Error__CanOnlyChangeAfterDelayPeriod(string location);
error Error__GuardianDoesNotExist(string location);
error Error__CanOnlyRemoveAfterDelayPeriod(string location);
error Error__CanOnlyAddAfterDelayPeriod(string location);
