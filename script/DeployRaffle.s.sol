// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {Raffle} from "../src/Raffle.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {CreateSubscription, FundSubscription, AddConsumer} from "./Interactions.s.sol";

contract DeployRaffle is Script {
    function run() public returns (Raffle, HelperConfig) {
        HelperConfig helperConfig = new HelperConfig();
        (
            uint256 _enteranceFee,
            uint256 _interval,
            address _vrfCoordinator,
            address _linkToken,
            bytes32 _keyHash,
            uint32 _callbackGasLimit,
            uint64 _subscriptionId
        ) = helperConfig.activeConfig();

        if (_subscriptionId == 0) {
            //creating a subscription id
            CreateSubscription createSubscription = new CreateSubscription();
            _subscriptionId = createSubscription.createSubscription(
                _vrfCoordinator
            );

            //funding the subscription
            FundSubscription fundSubscription = new FundSubscription();
            fundSubscription.fundSubscription(
                _vrfCoordinator,
                _linkToken,
                _subscriptionId
            );
        }

        vm.startBroadcast();

        Raffle raffle = new Raffle(
            _enteranceFee,
            _interval,
            _vrfCoordinator,
            _keyHash,
            _callbackGasLimit,
            _subscriptionId
        );
        vm.stopBroadcast();

        //adding the consumer
        AddConsumer addConsumer = new AddConsumer();
        addConsumer.addConsumer(
            _vrfCoordinator,
            _subscriptionId,
            address(raffle)
        );

        return (raffle, helperConfig);
    }
}
