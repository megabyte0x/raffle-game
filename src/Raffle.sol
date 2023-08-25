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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";


/**
 * @title Raffle
 * @author Megabyte
 * @notice This contract is used to create a raffle
 * @dev This contract implements Chainlink VRF2
 */
contract Raffle {
    // Errors
    error Raffle__IncorrectEnteranceFee();


    // State variables
    uint256 private immutable i_enteranceFee;
    uint256 private immutable i_durationInSeconds;
    uint256 private s_lastTimeStamp;
    address payable[] private s_participants;


    // Events
    event Raffle__ParticipantEntered(address indexed participant);

    constructor(uint256 _enteranceFee, uint256 _durationInSeconds) {
        i_enteranceFee = _enteranceFee;
        i_durationInSeconds = _durationInSeconds;
        s_lastTimeStamp = block.timestamp;
    }

    function enterRaffle() external payable {
        if(msg.value < i_enteranceFee) revert Raffle__IncorrectEnteranceFee();
        
        s_participants.push(payable(msg.sender));
        emit Raffle__ParticipantEntered(msg.sender);
    }

    function pickWinner() external {
        if ((block.timestamp - s_lastTimeStamp) <  i_durationInSeconds) {
            revert();
        }
    }

    function getEnteranceFee() external view returns (uint256) {
        return i_enteranceFee;
    }
}
