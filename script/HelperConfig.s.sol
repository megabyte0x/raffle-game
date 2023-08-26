// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {VRFCoordinatorV2Mock} from "@chainlink/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";
import {LinkToken} from "../test/mocks/LinkToken.sol";

contract HelperConfig is Script {
    struct NetworkConfig {
        uint256 _enteranceFee;
        uint256 _interval;
        address _vrfCoordinator;
        address _linkToken;
        bytes32 _keyHash;
        uint32 _callbackGasLimit;
        uint64 _subscriptionId;
        uint256 _deployerKey;
    }

    NetworkConfig public activeConfig;

    constructor() {
        if (block.chainid == 11155111) {
            activeConfig = getSepoliaETHConfig();
        } else {
            activeConfig = getOrCreateAnvilETHConfig();
        }
    }

    function getSepoliaETHConfig()
        public
        view
        returns (NetworkConfig memory sepoliaConfigs)
    {
        sepoliaConfigs = NetworkConfig({
            _enteranceFee: 0.01 ether,
            _interval: 30,
            _vrfCoordinator: 0x8103B0A8A00be2DDC778e6e7eaa21791Cd364625,
            _linkToken: 0x779877A7B0D9E8603169DdbD7836e478b4624789,
            _keyHash: 0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c,
            _callbackGasLimit: 200000,
            _subscriptionId: 4776,
            _deployerKey: vm.envUint("PRIVATE_KEY")
        });
    }

    function getOrCreateAnvilETHConfig()
        public
        returns (NetworkConfig memory anvilConfigs)
    {
        if (activeConfig._vrfCoordinator != address(0)) {
            return activeConfig;
        }

        uint96 baseFee = 0.25 ether; // 0.25 LINK
        uint96 gasPriceLink = 1e9; // 1 gwei

        vm.startBroadcast();

        VRFCoordinatorV2Mock vrfCoordinatorMock = new VRFCoordinatorV2Mock(
            baseFee,
            gasPriceLink
        );

        LinkToken linkToken = new LinkToken();

        vm.stopBroadcast();

        return
            NetworkConfig({
                _enteranceFee: 0.01 ether,
                _interval: 30,
                _vrfCoordinator: address(vrfCoordinatorMock),
                _linkToken: address(linkToken),
                _keyHash: 0x9d1f7f8c5d0e2d5bfae9362ebd1a2c401d0e9a0d14f5d9f0c0c0a4d9d9c5e7c7,
                _callbackGasLimit: 200000,
                _subscriptionId: 0,
                _deployerKey: 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
            });
    }
}
