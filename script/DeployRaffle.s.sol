// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {Raffle} from "../src/Raffle.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

contract DeployRaffle is Script {
    function run() public returns (Raffle) {
        HelperConfig helperConfig = new HelperConfig();
        (
            uint256 _enteranceFee,
            uint256 _interval,
            address _vrfCoordinator,
            bytes32 _keyHash,
            uint32 _callbackGasLimit,
            uint64 _subscriptionId
        ) = helperConfig.activeConfig();

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

        return raffle;
    }
}
