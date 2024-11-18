// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import { Script } from "forge-std/Script.sol";



contract DeployConfig is Script {

    // read these in from an ENV
    
    uint256 internal constant ETH_SEPOLIA_CHAIN_ID = vm.envUint("ETH_SEPOLIA_CHAIN_ID");
    uint256 internal constant ANVIL_CHAIN_ID = vm.envUint("ANVIL_CHAIN_ID"); // Anvil chainOD

    error HelperConfig__InvalidChainId();

    struct NetworkConfig {
        uint256 enteranceFee; 
        uint256 interval; 
        address vrfCoordinator; 
        bytes32 gasLane; // keyHash
        uint256 subscriptionId;
        uint32 callbackGasLimit;
    }

    NetworkConfig public localNetworkConfig;
    mapping(uint256 chainId => NetworkConfig) public networkConfigs;

    constructor() {
        networkConfigs[ETH_SEPOLIA_CHAIN_ID] = getSepoliaEthConfig();
    }

    function getConfigChainByChainId(uint256 chainId) public view returns (NetworkConfig memory) {
        if (networkConfigs[chainId].vrfCoordinator != address(0)) {
            return networkConfigs[chainId];
        } else if (chainId == ANVIL_CHAIN_ID) {
            // getOrCreateAnvilEthConfig()
        } else {
            revert HelperConfig__InvalidChainId();
        }
    }

     function getSepoliaEthConfig() public pure returns(NetworkConfig memory) {
        return NetworkConfig({
            enteranceFee: 0.01 ether,
            interval: 30,
            vrfCoordinator: 0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B,
            gasLane: 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae,
            subscriptionId: 0,
            callbackGasLimit: 500000
        });
    }

    funciton getOrCreateAnvilEthConfig() public returns (NetworkConfig memory) {
        // check to see if we set an active network config
        if (localNetworkConfig.vrfCoordinator != address(0)) {
            return localNetworkConfig;
        }
    }

}