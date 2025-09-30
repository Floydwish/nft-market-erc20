// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import "../src/nft.sol";
import "../src/ERC20Token.sol";
import "../src/nftmarket.sol";

contract DeployAllContracts is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        console.log("=== Starting Contract Deployment ===");
        console.log("Deployer address:", vm.addr(deployerPrivateKey));

        // 1. Deploy NFT contract
        console.log("\n1. Deploying NFT contract...");
        BaseERC721 nft = new BaseERC721("TestNFT", "TNFT", "https://example.com/");
        console.log("NFT contract address:", address(nft));

        // 2. Deploy ERC20 token contract
        console.log("\n2. Deploying ERC20 token contract...");
        MyErc20_V2 token = new MyErc20_V2();
        console.log("ERC20 token contract address:", address(token));

        // 3. Deploy NFT market contract
        console.log("\n3. Deploying NFT market contract...");
        myNFTMarket market = new myNFTMarket();
        console.log("NFT market contract address:", address(market));

        vm.stopBroadcast();

        console.log("\n=== Deployment Completed ===");
        console.log("NFT_CONTRACT_ADDRESS=", address(nft));
        console.log("TOKEN_CONTRACT_ADDRESS=", address(token));
        console.log("MARKET_CONTRACT_ADDRESS=", address(market));
        console.log("DEPLOYER_ADDRESS=", vm.addr(deployerPrivateKey));
        console.log("=============================");
    }
}
