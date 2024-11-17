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

    // errors
    error Raffle__NotEnoughEth();
    error Raffle__TranserFailed();
    error Raffle__RaffleNotOpen();
    error Raffle__UpkeepNotNeeded(uint256 balance, uint256 playersLength, uint256 raffleState);

    // type declarations
    enum RaffleState {
        OPEN,
        CALCULATING
    }

    // State variables
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
    RaffleState private s_raffleState;

    // events
    event RaffleEnterd(address indexed player);
    event WinnerPicked(address indexed winner);

    constructor (uint256 enteranceFee, uint256 interval, address vrfCoordinator, bytes32 keyHash,
                    uint256 subscriptionId, uint32 callbackGasLimit) VRFConsumerBaseV2Plus(vrfCoordinator) {
        i_enteranceFee = enteranceFee;
        i_interval = interval;
        i_keyHash = keyHash;
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit = callbackGasLimit;

        s_lastTimeStamp = block.timestamp;
        s_raffleState = RaffleState.OPEN;
    }
    
    function enterRaffle() external payable {
        // require(msg.value >= i_enteranceFee, "Not enough ETH sent!");
        if (msg.value < i_enteranceFee) {
            revert Raffle__NotEnoughEth();
        }
        if (s_raffleState != RaffleState.OPEN) {
            revert Raffle__RaffleNotOpen();
        }
        s_players.push(payable(msg.sender));

        // Emit event (write to logs) to indicate a new player was added
        emit RaffleEnterd(msg.sender);
    }

    /**
     * @dev This is the function Chanlink nodes will call to se if lotter is ready to have a winner picked.
     * The following should be true in order of upKeepNeeded to be true:
     *      1. The time interval has passed between raffle runs.
     *      2. The lottery is open
     *      3. The contract has ETH
     *      4. Implicitly, your subscription has LINK
     * @param - checkData is ignored
     * @return upKeepNeeded true if it is time to restart the lottery
     * @return 
    */
    function checkUpkeep(bytes memory /* checkData */) public view returns (bool upKeepNeeded, bytes memory /* performData */ ) {
            bool timeHasPassed = ((block.timestamp - s_lastTimeStamp) >= i_interval);
            bool isOpen = s_raffleState == RaffleState.OPEN;
            bool hasBalance = address(this).balance > 0;
            bool hasPlayers = s_players.length > 0;

            upKeepNeeded = timeHasPassed && isOpen && hasBalance && hasPlayers;
            return (upKeepNeeded, "");
    }

    function performUpKeep(bytes calldata /* performData */) external {
        // check if enough time hass passed
        (bool upKeepNeeded, ) = checkUpkeep("");
        if (!upKeepNeeded)
            revert Raffle__UpkeepNotNeeded(address(this).balance, s_players.length, uint256(s_raffleState));
        
        s_raffleState = RaffleState.CALCULATING;
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
        s_raffleState = RaffleState.OPEN;
        s_players = new address payable[](0);
        s_lastTimeStamp = block.timestamp;
        emit WinnerPicked(s_recentWinner);

        (bool success, ) = s_recentWinner.call{value: address(this).balance}("");
        if (!success) {
            revert Raffle__TranserFailed();
        }
    }

    // Getters
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