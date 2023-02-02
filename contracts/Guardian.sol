// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "./FundsManager.sol";
import "./OwnershipManager.sol";

contract Guardian is FundsManager, OwnershipManager {}
