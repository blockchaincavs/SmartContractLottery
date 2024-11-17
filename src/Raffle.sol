// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import { VRFConsumerBaseV2Plus } from "lib/chainlink-brownie-contracts/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import { VRFV2PlusClient } from "lib/chainlink-brownie-contracts/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";

/**
 * @title A Lottery Smart Contract
 * @author Skyler Gonzalez
 * @notice This contract is for creating a sample Lottery
 * @dev Implements Chainlink VRFv2.5
 */
contract Raffle is VRFConsumerBaseV2Plus {

    error Raffle__NotEnoughEth();
    error Raffle__TranserFailed();

    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private immutable NUM_WORDS = 1;
    uint256 private immutable i_enteranceFee;
    uint256 private immutable i_interval;
    bytes32 private immutable i_keyHash;
    uint256 private immutable i_subscriptionId;
    uint32 private immutable i_callbackGasLimit;
    address[] private s_players;
    uint256 private s_lastTimeStamp;
    address private s_recentWinner;

    event RaffleEnterd(address indexed player);

    constructor (uint256 enteranceFee, uint256 interval, address vrfCoordinator, bytes32 keyHash,
                    uint256 subscriptionId, uint32 callbackGasLimit) VRFConsumerBaseV2Plus(vrfCoordinator) {
        i_enteranceFee = enteranceFee;
        i_interval = interval;
        s_lastTimeStamp = block.timestamp;
        i_keyHash = keyHash;
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit = callbackGasLimit;
    }
    
    function enterRaffle() external payable {
        // require(msg.value >= i_enteranceFee, "Not enough ETH sent!");
        if (msg.value < i_enteranceFee) {
            revert Raffle__NotEnoughEth();
        }
        s_players.push(payable(msg.sender));

        // Emit event (write to logs) to indicate a new player was added
        emit RaffleEnterd(msg.sender);
    }

    function pickWinner() external {
        // check if enough time hass passed
        if ((block.timestamp - s_lastTimeStamp) < i_interval) {
            revert();
        }
        
        VRFV2PlusClient.RandomWordsRequest memory request = VRFV2PlusClient.RandomWordsRequest({
                keyHash: i_keyHash,
                subId: i_subscriptionId,
                requestConfirmations: REQUEST_CONFIRMATIONS,
                callbackGasLimit: i_callbackGasLimit,
                numWords: NUM_WORDS,
                extraArgs: VRFV2PlusClient._argsToBytes(VRFV2PlusClient.ExtraArgsV1({ nativePayment: false }))
            });
        // Will revert if subscription is not set and funded.
        uint256 requestId = s_vrfCoordinator.requestRandomWords(request);
    }

    function fulfillRandomWords(uint256 requestId, uint256[] calldata randomWords) internal override {
        uint256 indexOfWinner = randomWords[0] % s_players.length;
        s_recentWinner = s_players[indexOfWinner];
        (bool success, ) = s_recentWinner.call{value: address(this).balance}("");
        if (!success) {
            revert Raffle__TranserFailed();
        }

    }

    /** 
     * Getter Functions 
     */
    function getEnteranceFee() external view returns(uint256) {
        return i_enteranceFee;
    }

    function getPlayer(uint256 _playerIndex) external view returns(address) {
        return s_players[_playerIndex];
    }

    function getRecentWinner() external view returns(address) {
        return s_recentWinner;
    }
}