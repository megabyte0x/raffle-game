// Layout of Contract:
// version
// imports
// interfaces, libraries, contracts
// errors
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// view & pure functions

// CEI: Checks, Effects, Interactions

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {VRFCoordinatorV2Interface} from "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import {VRFConsumerBaseV2} from "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import {AutomationRegistryInterface, State, Config} from "@chainlink/contracts/src/v0.8/interfaces/AutomationRegistryInterface1_2.sol";

/**
 * @title Raffle
 * @author Megabyte
 * @notice This contract is used to create a raffle
 * @dev This contract implements Chainlink VRF2
 */
contract Raffle is VRFConsumerBaseV2 {
    // Errors
    error Raffle__IncorrectEnteranceFee();
    error Raffle__TransferFailed();
    error Raffle__NotOpen();
    error Raffle__UpkeepNotNeeded(
        uint256 balance,
        uint256 state,
        uint256 participantsLength
    );

    /** Type Declarations */
    enum RaffleState {
        OPEN,
        CALCULATING_WINNER
    }

    // State variables
    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
    bytes32 private immutable i_keyHash;
    uint32 private immutable i_callbackGasLimit;
    uint64 private immutable i_subscriptionId;
    uint256 private immutable i_enteranceFee;
    uint256 private immutable i_interval;

    uint256 private s_lastTimeStamp;
    address payable[] private s_participants;
    address payable private s_recentWinner;
    RaffleState private s_raffleState;

    uint32 private constant NUM_WORDS = 1;
    uint16 private constant REQUEST_CONFIRMATIONS = 3;

    // Events
    event Raffle__ParticipantEntered(address indexed participant);
    event Raffle__WinnerPicked(address indexed winner);

    constructor(
        uint256 _enteranceFee,
        uint256 _interval,
        address _vrfCoordinator,
        bytes32 _keyHash,
        uint32 _callbackGasLimit,
        uint64 _subscriptionId
    ) VRFConsumerBaseV2(_vrfCoordinator) {
        i_enteranceFee = _enteranceFee;
        i_interval = _interval;
        i_vrfCoordinator = VRFCoordinatorV2Interface(_vrfCoordinator);
        i_keyHash = _keyHash;
        i_callbackGasLimit = _callbackGasLimit;
        i_subscriptionId = _subscriptionId;

        s_lastTimeStamp = block.timestamp;
    }

    function enterRaffle() external payable {
        if (msg.value < i_enteranceFee) revert Raffle__IncorrectEnteranceFee();
        if (s_raffleState != RaffleState.OPEN) revert Raffle__NotOpen();
        s_participants.push(payable(msg.sender));
        emit Raffle__ParticipantEntered(msg.sender);
    }

    function checkUpkeep(
        bytes memory /* checkData */
    ) public view returns (bool upkeepNeeded, bytes memory /** performData */) {
        bool timeHasPassed = (block.timestamp - s_lastTimeStamp) > i_interval;
        bool hasParticipants = s_participants.length > 0;
        bool isOpen = s_raffleState == RaffleState.OPEN;
        bool balance = address(this).balance > 0;

        upkeepNeeded = (timeHasPassed && hasParticipants && isOpen && balance);

        return (upkeepNeeded, "");
    }

    function performUpkeep(bytes calldata /* performData */) external {
        (bool upkeepNeeded, ) = checkUpkeep("");
        if (!upkeepNeeded) {
            revert Raffle__UpkeepNotNeeded(
                address(this).balance,
                uint256(s_raffleState),
                s_participants.length
            );
        }

        s_raffleState = RaffleState.CALCULATING_WINNER;
        i_vrfCoordinator.requestRandomWords(
            i_keyHash,
            i_subscriptionId,
            REQUEST_CONFIRMATIONS,
            i_callbackGasLimit,
            NUM_WORDS
        );
    }

    function getEnteranceFee() external view returns (uint256) {
        return i_enteranceFee;
    }

    function fulfillRandomWords(
        uint256 _requestId,
        uint256[] memory _randomWords
    ) internal override {
        uint256 indexOfWinner = _randomWords[0] % s_participants.length;
        address payable winner = s_participants[indexOfWinner];
        s_recentWinner = winner;
        s_raffleState = RaffleState.OPEN;

        s_participants = new address payable[](0);
        s_lastTimeStamp = block.timestamp;

        (bool success, ) = winner.call{value: address(this).balance}("");
        if (!success) revert Raffle__TransferFailed();

        emit Raffle__WinnerPicked(winner);
    }

    function getRaffleState() public view returns (RaffleState) {
        return s_raffleState;
    }
}
