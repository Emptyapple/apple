/*
    Copyright 2021 Empty Apple Dev <bigemptyapple@protonmail.com>

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

pragma solidity ^0.5.17;
pragma experimental ABIEncoderV2;

import "./external/Decimal.sol";

library Constants {
    /* Chain */
    uint256 private constant CHAIN_ID = 1; // Mainnet

    /* Bootstrapping */
    uint256 private constant BOOTSTRAPPING_PERIOD = 48;
    uint256 private constant BOOTSTRAPPING_PRICE = 12e17; // 1.20 USDC
    uint256 private constant BOOTSTRAPPING_SPEEDUP_FACTOR = 2; // 8 days @ 4 hours

    // /* Oracle */ 
    address private constant USDC = address(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    address private constant WETH = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    // address private constant USDC = address(0x07865c6E87B9F70255377e024ace6630C1Eaa37F);
    // address private constant WETH = address(0xc778417E063141139Fce010982780140Aa0cD5Ab);
    uint256 private constant ORACLE_RESERVE_MINIMUM = 1e10; // 10,000 USDC

    /* Bonding */
    uint256 private constant INITIAL_STAKE_MULTIPLE = 1e6; // 100 BEA -> 100M BEAS

    /* Epoch */
    uint256 private constant EPOCH_PERIOD = 86400/3; // 1/3 day

    /* Governance */
    uint256 private constant GOVERNANCE_PERIOD = 9;
    uint256 private constant GOVERNANCE_QUORUM = 20e16; // 20%
    uint256 private constant GOVERNANCE_PROPOSAL_THRESHOLD = 5e15; // 0.5%
    uint256 private constant GOVERNANCE_SUPER_MAJORITY = 66e16; // 66%
    uint256 private constant GOVERNANCE_EMERGENCY_DELAY = 6; // 6 epochs

    /* DAO */
    uint256 private constant ADVANCE_INCENTIVE = 1e20; // 100 BEA
    uint256 private constant DAO_EXIT_LOCKUP_EPOCHS = 9; // 9 pochs fluid
    /* Pool */
    uint256 private constant POOL_EXIT_LOCKUP_EPOCHS = 3; // 3 epochs fluid
    /* Market */
    uint256 private constant COUPON_EXPIRATION = 48;
    uint256 private constant DEBT_RATIO_CAP = 35e16; // 35%

    /* Regulator */
    uint256 private constant SUPPLY_CHANGE_LIMIT = 2e17; // 20%
    uint256 private constant ORACLE_POOL_RATIO_BOOTSTRAPING = 15; // 15%
    uint256 private constant ORACLE_POOL_RATIO = 30; // 30%
    uint256 private constant COUPON_SUPPLY_CHANGE_LIMIT = 10e16; // 10%


    /**
     * Getters
     */

    function getUsdc() internal pure returns (address) {
        return USDC;
    }
    function getWeth() internal pure returns (address) {
        return WETH;
    }
    function getOracleReserveMinimum() internal pure returns (uint256) {
        return ORACLE_RESERVE_MINIMUM;
    }

    function getEpochPeriod() internal pure returns (uint256) {
        return EPOCH_PERIOD;
    }

    function getInitialStakeMultiple() internal pure returns (uint256) {
        return INITIAL_STAKE_MULTIPLE;
    }

    function getBootstrappingPeriod() internal pure returns (uint256) {
        return BOOTSTRAPPING_PERIOD;
    }

    function getBootstrappingPrice() internal pure returns (Decimal.D256 memory) {
        return Decimal.D256({value: BOOTSTRAPPING_PRICE});
    }

    function getBootstrappingSpeedupFactor() internal pure returns (uint256) {
        return BOOTSTRAPPING_SPEEDUP_FACTOR;
    }

    function getGovernancePeriod() internal pure returns (uint256) {
        return GOVERNANCE_PERIOD;
    }

    function getGovernanceQuorum() internal pure returns (Decimal.D256 memory) {
        return Decimal.D256({value: GOVERNANCE_QUORUM});
    }

    function getAdvanceIncentive() internal pure returns (uint256) {
        return ADVANCE_INCENTIVE;
    }

    function getCouponExpiration() internal pure returns (uint256) {
        return COUPON_EXPIRATION;
    }

    function getSupplyChangeLimit() internal pure returns (Decimal.D256 memory) {
        return Decimal.D256({value: SUPPLY_CHANGE_LIMIT});
    }

    function getOraclePoolRatio() internal pure returns (uint256) {
        return ORACLE_POOL_RATIO;
    }
    function getOraclePoolRatioBoot() internal pure returns (uint256) {
        return ORACLE_POOL_RATIO_BOOTSTRAPING;
    }
    function getChainId() internal pure returns (uint256) {
        return CHAIN_ID;
    }
    function getDAOExitLockupEpochs() internal pure returns (uint256) {
        return DAO_EXIT_LOCKUP_EPOCHS;
    }
    function getPoolExitLockupEpochs() internal pure returns (uint256) {
        return POOL_EXIT_LOCKUP_EPOCHS;
    }
    function getGovernanceProposalThreshold() internal pure returns (Decimal.D256 memory) {
        return Decimal.D256({value: GOVERNANCE_PROPOSAL_THRESHOLD});
    }
    function getGovernanceEmergencyDelay() internal pure returns (uint256) {
        return GOVERNANCE_EMERGENCY_DELAY;
    }
    function getGovernanceSuperMajority() internal pure returns (Decimal.D256 memory) {
        return Decimal.D256({value: GOVERNANCE_SUPER_MAJORITY});
    }
    function getDebtRatioCap() internal pure returns (Decimal.D256 memory) {
        return Decimal.D256({value: DEBT_RATIO_CAP});
    }
    function getCouponSupplyChangeLimit() internal pure returns (Decimal.D256 memory) {
        return Decimal.D256({value: COUPON_SUPPLY_CHANGE_LIMIT});
    }
}
