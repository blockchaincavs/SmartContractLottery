// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

/**
 * @title A Lottery Smart Contract
 * @author Skyler Gonzalez
 * @notice This contract is for creating a sample Lottery
 * @dev Implements Chainlink VRFv2.5
 */
contract Raffle {

    error Raffle__NotEnoughEth();

    uint256 private immutable i_enteranceFee;
    uint256 private immutable i_interval;
    address[] private s_players;
    uint256 s_lastTimeStamp;

    event RaffleEnterd(address indexed player);

    constructor (uint256 enteranceFee, uint256 interval) {
        i_enteranceFee = enteranceFee;
        i_interval = interval;
        s_lastTimeStamp = block.timestamp;
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
}