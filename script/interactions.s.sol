// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import { Script, console } from "forge-std/Script.sol";
import { DeployConfig } from "./DeployConfig.s.sol";
import { VRFCoordinatorV2_5Mock } from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import { LinkToken } from "test/mocks/LinkToken.sol";

contract CreateSubscription is Script {

    function run() public {
        createSubscriptionFromConfig();
    }

    function createSubscriptionFromConfig() public returns(uint256, address) {
        DeployConfig deployConfig = new DeployConfig();
        address vrfCoordinator = deployConfig.getConfig().vrfCoordinator;

        (uint256 subId, ) = createSubscription(vrfCoordinator);
        return (subId, vrfCoordinator);
    }

    function createSubscription(address _vrfCoordinator) public returns(uint256, address) {
        console.log("Creating Subscription on chain id: ", block.chainid);
        
        // send transaction to blockchain
        vm.startBroadcast();
        uint256 subId = VRFCoordinatorV2_5Mock(_vrfCoordinator).createSubscription();
        vm.stopBroadcast();

        console.log("Subscription created with id: ", subId);

        return (subId, _vrfCoordinator);
    }
}

contract FundSubscription is Script {
    uint256 public constant FUND_AMOUNT = 3 ether; // 3 LINK

    // read these in from an ENV
    uint256 public ETH_SEPOLIA_CHAIN_ID = vm.envUint("ETH_SEPOLIA_CHAIN_ID");
    uint256 public ANVIL_CHAIN_ID = vm.envUint("ANVIL_CHAIN_ID"); // Anvil chainid

    function run() public {
        fundSubscriptionUsingConfig();
    }

    function fundSubscriptionUsingConfig() public {
        DeployConfig deployConfig = new DeployConfig();
        DeployConfig.NetworkConfig memory networkConfig = deployConfig.getConfig();
        address vrfCoordinator = networkConfig.vrfCoordinator;
        uint256 subscriptionId = networkConfig.subscriptionId;
        address linkToken = networkConfig.link;

        fundSubscription(vrfCoordinator, subscriptionId, linkToken);
    }

    function fundSubscription(address _vrfCoordinator, uint256 _subscriptionId, address _linkToken) public {
        console.log("Funding subscription: ", _subscriptionId);
        console.log("Using vrfCoordinator: ", _vrfCoordinator);
        console.log("On ChainId: ", block.chainid);

        if (block.chainid == ANVIL_CHAIN_ID) {
            vm.startBroadcast();
            VRFCoordinatorV2_5Mock(_vrfCoordinator).fundSubscription(_subscriptionId, FUND_AMOUNT);
            vm.stopBroadcast();
        } else {
            vm.startBroadcast();
            LinkToken(_linkToken).transferAndCall(_vrfCoordinator, FUND_AMOUNT, abi.encode(_subscriptionId));
            vm.stopBroadcast();
        }
    }
}