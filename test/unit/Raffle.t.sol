// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {Raffle} from "../../src/Raffle.sol";
import {DeployRaffle} from "../../script/DeployRaffle.s.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";

contract RaffleTest is Test {
    // Events
    event Raffle__ParticipantEntered(address indexed participant);

    Raffle raffle;
    HelperConfig helperConfig;

    address public JIM = makeAddr("JIM");
    uint256 public constant JIM_INITIAL_BALANCE = 10 ether;

    uint256 _enteranceFee;
    uint256 _interval;
    address _vrfCoordinator;
    address _linkToken;
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
            _linkToken,
            _keyHash,
            _callbackGasLimit,
            _subscriptionId
        ) = helperConfig.activeConfig();
        vm.deal(JIM, JIM_INITIAL_BALANCE);
    }

    function testInitialisesAtOpenState() public view {
        assert(raffle.getRaffleState() == Raffle.RaffleState.OPEN);
    }

    ////////////////////////////////
    //////////Enter Raffle Tests////
    ////////////////////////////////

    function testRaffleRevertsWhenNotEnoughFundsProvided() public {
        vm.prank(JIM);
        vm.expectRevert(Raffle.Raffle__IncorrectEnteranceFee.selector);
        raffle.enterRaffle{value: 0.0001 ether}();
    }

    function testRaffleRecordsWhenPlayerEnter() public {
        vm.prank(JIM);
        raffle.enterRaffle{value: _enteranceFee}();
        assert(raffle.getParticipantsLength() == 1);
        assert(raffle.getParticipant(0) == JIM);
    }

    function testEmitsEventWhenEnter() public {
        vm.prank(JIM);
        vm.expectEmit(true, false, false, false, address(raffle));
        emit Raffle__ParticipantEntered(JIM);
        raffle.enterRaffle{value: _enteranceFee}();
    }

    function testCantEnterWhenPickingWinner() public {
        vm.prank(JIM);
        raffle.enterRaffle{value: _enteranceFee}();
        vm.warp(block.timestamp + _interval + 1);
        vm.roll(block.number + 1);
        raffle.performUpkeep("");

        vm.expectRevert(Raffle.Raffle__NotOpen.selector);
        vm.prank(JIM);
        raffle.enterRaffle{value: _enteranceFee}();
    }
}
