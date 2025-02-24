// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "utils/BaseScript.sol";
import {LockingMultiRewards} from "staking/LockingMultiRewards.sol";

contract MIMSavingRateScript is BaseScript {
    function deploy() public returns (LockingMultiRewards staking) {
        address safe = toolkit.getAddress(block.chainid, "safe.ops");
        address gelatoProxy = toolkit.getAddress(block.chainid, "safe.devOps.gelatoProxy");
        address mim = toolkit.getAddress(block.chainid, "mim");
        address arb = toolkit.getAddress(block.chainid, "arb");
        address spell = toolkit.getAddress(block.chainid, "spell");

        vm.startBroadcast();
        staking = deployWithParameters(mim, 30_000, 7 days, 13 weeks, tx.origin);
        staking.addReward(arb);
        staking.addReward(spell);
        staking.addReward(mim);

        staking.setMinLockAmount(100 ether);
        staking.setOperator(toolkit.getAddress(block.chainid, "rewardDistributors.epochBased"), true); // allows distributor to call notifyRewardAmount
        staking.setOperator(gelatoProxy, true); // allows gelato to call processExpiredLocks

        if (!testing()) {
            staking.transferOwnership(safe);
        }

        vm.stopBroadcast();
    }

    function deployWithParameters(
        address stakingToken,
        uint256 boost,
        uint256 rewardDuration,
        uint256 lockDuration,
        address origin
    ) public returns (LockingMultiRewards staking) {
        if (block.chainid != ChainId.Arbitrum) {
            revert("unsupported chain");
        }

        bytes memory params = abi.encode(stakingToken, boost, rewardDuration, lockDuration, origin);
        staking = LockingMultiRewards(deploy("MimSavingRateStaking", "LockingMultiRewards.sol:LockingMultiRewards", params));
    }
}
