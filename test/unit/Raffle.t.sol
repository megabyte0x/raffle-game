// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {Raffle} from "../../src/Raffle.sol";
import {DeployRaffle} from "../../script/DeployRaffle.s.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";

contract RaffleTest is Test {
    Raffle raffle;
    HelperConfig helperConfig;

    address public JIM = makeAddr("JIM");
    uint256 public constant JIM_INITIAL_BALANCE = 10 ether;

    uint256 _enteranceFee;
    uint256 _interval;
    address _vrfCoordinator;
    bytes32 _keyHash;
    uint32 _callbackGasLimit;
    uint64 _subscriptionId;

    function setUp() external {
        DeployRaffle deployer = new DeployRaffle();
        (raffle, helperConfig) = deployer.run();
        (
            _enteranceFee,
            _interval,
            _vrfCoordinator,
            _keyHash,
            _callbackGasLimit,
            _subscriptionId
        ) = helperConfig.activeConfig();
    }

    function testInitialisesAtOpenState() public view {
        assert(raffle.getRaffleState() == Raffle.RaffleState.OPEN);
    }
}
