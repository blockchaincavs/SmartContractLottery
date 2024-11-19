// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {Script} from "forge-std/Script.sol";
import {Raffle} from "../src/Raffle.sol";
import {DeployConfig} from "./DeployConfig.s.sol";
import { CreateSubscription } from "./interactions.s.sol";

contract DeployRaffle is Script {

    function run() public {

    }

    function deployContract() public returns(Raffle, DeployConfig) {

        DeployConfig deployConfig = new DeployConfig();

        // Deploy mocks and get network config for Anvil. If on sepolia we get sepolia config
        DeployConfig.NetworkConfig memory config = deployConfig.getConfig();

        if (config.subscriptionId == 0) {
            // create subscription
            CreateSubscription subscription = new CreateSubscription();

            (config.subscriptionId, config.vrfCoordinator) = 
                subscription.createSubscription(config.vrfCoordinator);
        }

        vm.startBroadcast();

        Raffle raffle = new Raffle(
                config.enteranceFee, config.interval, 
                config.vrfCoordinator, config.gasLane, 
                config.subscriptionId, config.callbackGasLimit
            );

        vm.stopBroadcast();

        return (raffle, deployConfig);
    }
}


