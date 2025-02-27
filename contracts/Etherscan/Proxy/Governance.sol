/*
  Copyright 2019-2021 StarkWare Industries Ltd.

  Licensed under the Apache License, Version 2.0 (the "License").
  You may not use this file except in compliance with the License.
  You may obtain a copy of the License at

  https://www.starkware.co/open-source-license/

  Unless required by applicable law or agreed to in writing,
  software distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions
  and limitations under the License.
*/
// SPDX-License-Identifier: Apache-2.0.
pragma solidity ^0.8.24;

import "./MGovernance.sol";

/*
  Implements Generic Governance, applicable for both proxy and main contract, and possibly others.
  Notes:
   The use of the same function names by both the Proxy and a delegated implementation
   is not possible since calling the implementation functions is done via the default function
   of the Proxy. For this reason, for example, the implementation of MainContract (MainGovernance)
   exposes mainIsGovernor, which calls the internal isGovernor method.
*/
abstract contract Governance is MGovernance {
  event LogNominatedGovernor(address nominatedGovernor);
  event LogNewGovernorAccepted(address acceptedGovernor);
  event LogRemovedGovernor(address removedGovernor);
  event LogNominationCancelled();

  function getGovernanceInfo()
    internal
    view
    virtual
    returns (GovernanceInfoStruct storage);

  /*
      Current code intentionally prevents governance re-initialization.
      This may be a problem in an upgrade situation, in a case that the upgrade-to implementation
      performs an initialization (for real) and within that calls initGovernance().

      Possible workarounds:
      1. Clearing the governance info altogether by changing the MAIN_GOVERNANCE_INFO_TAG.
         This will remove existing main governance information.
      2. Modify the require part in this function, so that it will exit quietly
         when trying to re-initialize (uncomment the lines below).
    */
  function initGovernance() internal {
    GovernanceInfoStruct storage gub = getGovernanceInfo();
    require(!gub.initialized, "ALREADY_INITIALIZED");
    gub.initialized = true; // to ensure addGovernor() won't fail.
    // Add the initial governer.
    addGovernor(msg.sender);
  }

  function isGovernor(
    address testGovernor
  ) internal view override returns (bool) {
    GovernanceInfoStruct storage gub = getGovernanceInfo();
    return gub.effectiveGovernors[testGovernor];
  }

  /*
      Cancels the nomination of a governor candidate.
    */
  function cancelNomination() internal onlyGovernance {
    GovernanceInfoStruct storage gub = getGovernanceInfo();
    gub.candidateGovernor = address(0x0);
    emit LogNominationCancelled();
  }

  function nominateNewGovernor(address newGovernor) internal onlyGovernance {
    GovernanceInfoStruct storage gub = getGovernanceInfo();
    require(!isGovernor(newGovernor), "ALREADY_GOVERNOR");
    gub.candidateGovernor = newGovernor;
    emit LogNominatedGovernor(newGovernor);
  }

  /*
      The addGovernor is called in two cases:
      1. by acceptGovernance when a new governor accepts its role.
      2. by initGovernance to add the initial governor.
      The difference is that the init path skips the nominate step
      that would fail because of the onlyGovernance modifier.
    */
  function addGovernor(address newGovernor) private {
    require(!isGovernor(newGovernor), "ALREADY_GOVERNOR");
    GovernanceInfoStruct storage gub = getGovernanceInfo();
    gub.effectiveGovernors[newGovernor] = true;
  }

  function acceptGovernance() internal {
    // The new governor was proposed as a candidate by the current governor.
    GovernanceInfoStruct storage gub = getGovernanceInfo();
    require(msg.sender == gub.candidateGovernor, "ONLY_CANDIDATE_GOVERNOR");

    // Update state.
    addGovernor(gub.candidateGovernor);
    gub.candidateGovernor = address(0x0);

    // Send a notification about the change of governor.
    emit LogNewGovernorAccepted(msg.sender);
  }

  /*
      Remove a governor from office.
    */
  function removeGovernor(address governorForRemoval) internal onlyGovernance {
    require(msg.sender != governorForRemoval, "GOVERNOR_SELF_REMOVE");
    GovernanceInfoStruct storage gub = getGovernanceInfo();
    require(isGovernor(governorForRemoval), "NOT_GOVERNOR");
    gub.effectiveGovernors[governorForRemoval] = false;
    emit LogRemovedGovernor(governorForRemoval);
  }
}
