// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "../src/nft.sol";

contract DeployNFTFixed is Script {
    function run() external {
        // 从环境变量获取私钥
        string memory privateKeyStr = vm.envString("PRIVATE_KEY");
        uint256 deployerPrivateKey = vm.parseUint(privateKeyStr);
        
        // 开始广播交易
        vm.startBroadcast(deployerPrivateKey);
        
        // NFT 参数直接设置在代码中
        string memory nftName = "XUBO";
        string memory nftSymbol = "XB";
        string memory baseURI = "https://gateway.pinata.cloud/ipfs/bafybeihv2kzbukjqqhwsvfz6ygct2na5dm5ah3dsk64wz3qrkzbek5wx2y/";
        
        // 部署 NFT 合约
        BaseERC721 nft = new BaseERC721(nftName, nftSymbol, baseURI);
        
        // 停止广播
        vm.stopBroadcast();
        
        // 输出部署信息
        console.log("=== NFT Contract Deployed to Base ===");
        console.log("Contract Address:", address(nft));
        console.log("NFT Name:", nftName);
        console.log("NFT Symbol:", nftSymbol);
        console.log("Base URI:", baseURI);
        console.log("Deployer:", vm.addr(deployerPrivateKey));
        console.log("Network: Base Mainnet");
        console.log("=====================================");
        
        // Output deployment info for manual saving
        console.log("=== Deployment Info (Save Manually) ===");
        console.log("NFT_CONTRACT_ADDRESS=", vm.toString(address(nft)));
        console.log("DEPLOYER_ADDRESS=", vm.toString(vm.addr(deployerPrivateKey)));
        console.log("NETWORK=Base");
        console.log("BASE_URI=", baseURI);
        console.log("=====================================");
    }
}
