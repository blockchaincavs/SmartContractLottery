// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import { Test, console } from "lib/forge-std/src/Test.sol";
import {DeployRaffle} from "script/DeployRaffle.s.sol";
import { Raffle } from "../../src/Raffle.sol";
import { DeployConfig } from "../../script/DeployConfig.s.sol";

contract RaffleTest is Test {
    
    Raffle public raffleContract;
    DeployConfig public deployConfig;

    address public PLAYER = makeAddr("player");
    uint256 public constant STARTING_PLAYER_BALANCE = 10 ether;

    event RaffleEntered(address indexed player);
    event WinnerPicked(address indexed winner);

    uint256 enteranceFee; 
    uint256 interval; 
    address vrfCoordinator; 
    bytes32 gasLane; // keyHash
    uint256 subscriptionId;
    uint32 callbackGasLimit;

    function setUp() external {
        DeployRaffle deployer = new DeployRaffle();
        (raffleContract, deployConfig) = deployer.deployContract();

        DeployConfig.NetworkConfig memory config = deployConfig.getConfig();
        enteranceFee = config.enteranceFee;
        interval = config.interval;
        vrfCoordinator = config.vrfCoordinator;
        gasLane = config.gasLane;
        subscriptionId = config.subscriptionId;
        callbackGasLimit = config.callbackGasLimit;

        vm.deal(PLAYER, STARTING_PLAYER_BALANCE);
    }

    function testRaffleInitializedState() public view {
        assert(raffleContract.getRaffleState() == Raffle.RaffleState.OPEN);
        
    }
    
    function testRaffleEntranceFee() public {
        // Arrange
        vm.prank(PLAYER);

        // Act / Assert
        vm.expectRevert(Raffle.Raffle__NotEnoughEth.selector);
        raffleContract.enterRaffle();
    }

    function testPlayersEntered() public {
        // Arrange
        vm.prank(PLAYER);
        
        // Act
        raffleContract.enterRaffle{value: enteranceFee}();
        address playerEntered = raffleContract.getPlayer(0);

        // Assert
        assertEq(playerEntered, PLAYER);
    }

    function testRaffleEnteredEvent() public {
        // Arrange
        vm.prank(PLAYER);

        // Act
        vm.expectEmit(true, false, false, false, address(raffleContract));
        emit RaffleEntered(PLAYER);

        // Assert
        raffleContract.enterRaffle{value: enteranceFee}();
    }

    function testRaffleCalculatingState() public {
        // Arrange
        startHoax(PLAYER); // perpetual prank
        raffleContract.enterRaffle{value: enteranceFee}();
        vm.warp(block.timestamp + interval + 1); // past raffle entry time
        vm.roll(block.number + 1); // moving to the next block
        raffleContract.performUpKeep("");

        // Act / Assert
        vm.expectRevert(Raffle.Raffle__RaffleNotOpen.selector);
        raffleContract.enterRaffle{value: enteranceFee}();
    }
}