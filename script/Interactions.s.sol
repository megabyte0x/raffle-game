// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script, console} from "forge-std/Script.sol";
import {DevOpsTools} from "foundry-devops/src/DevOpsTools.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {VRFCoordinatorV2Mock} from "@chainlink/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";
import {LinkToken} from "../test/mocks/LinkToken.sol";

contract CreateSubscription is Script {
    function createSubscriptionUsingConfigs() public returns (uint64) {
        HelperConfig helperConfig = new HelperConfig();
        (,, address _vrfCoordinator,,,,, uint256 _deployerKey) = helperConfig.activeConfig();
        return createSubscription(_vrfCoordinator, _deployerKey);
    }

    function createSubscription(address _vrfCoordinator, uint256 _deployerKey) public returns (uint64) {
        console.log("Creating subscription for chainId:", block.chainid);

        vm.startBroadcast(_deployerKey);
        uint64 subId = VRFCoordinatorV2Mock(_vrfCoordinator).createSubscription();
        vm.stopBroadcast();

        console.log("Sub ID is:", subId);
        return subId;
    }

    function run() external returns (uint64) {
        return createSubscriptionUsingConfigs();
    }
}

contract FundSubscription is Script {
    uint96 public constant FUND_AMOUNT = 3 ether;

    function fundSubscription(address _vrfCoordinator, address _linkToken, uint64 _subId, uint256 _deployerKey)
        public
        payable
    {
        console.log("Funding subscription for chainId:", block.chainid);
        console.log("Funding subscription id:", _subId);

        if (block.chainid == 31337) {
            vm.startBroadcast();
            VRFCoordinatorV2Mock(_vrfCoordinator).fundSubscription(_subId, FUND_AMOUNT);
            vm.stopBroadcast();
        } else {
            vm.startBroadcast(_deployerKey);
            LinkToken(_linkToken).transferAndCall(_vrfCoordinator, FUND_AMOUNT, abi.encode(_subId));
            vm.stopBroadcast();
        }
    }

    function fundSubscriptionUsingConfigs() public payable {
        HelperConfig helperConfig = new HelperConfig();
        (,, address _vrfCoordinator, address _linkToken,,, uint64 _subId, uint256 _deployerKey) =
            helperConfig.activeConfig();

        fundSubscription(_vrfCoordinator, _linkToken, _subId, _deployerKey);
    }

    function run() external {
        fundSubscriptionUsingConfigs();
    }
}

contract AddConsumer is Script {
    function addConsumer(address _vrfCoordinator, uint64 _subId, address _raffle, uint256 _deployerKey) public {
        console.log("Adding consumer for chainId:", block.chainid);
        console.log("Adding consumer for subscription id:", _subId);

        vm.startBroadcast(_deployerKey);
        VRFCoordinatorV2Mock(_vrfCoordinator).addConsumer(_subId, _raffle);
        vm.stopBroadcast();
    }

    function addConsumerUsingConfigs(address _raffle) public {
        HelperConfig helperConfig = new HelperConfig();
        (,, address _vrfCoordinator,,,, uint64 _subId, uint256 _deployerKey) = helperConfig.activeConfig();

        addConsumer(_vrfCoordinator, _subId, _raffle, _deployerKey);
    }

    function run() external {
        address mostRecentlyDeployedRaffle = DevOpsTools.get_most_recent_deployment("Raffle", block.chainid);
        addConsumerUsingConfigs(mostRecentlyDeployedRaffle);
    }
}
