// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "../src/nft.sol";

contract DeployNFT is Script {
    function run() external {
        // 从环境变量获取私钥
        string memory privateKeyStr = vm.envString("PRIVATE_KEY");
        uint256 deployerPrivateKey = vm.parseUint(privateKeyStr);
        
        // 开始广播交易
        vm.startBroadcast(deployerPrivateKey);
        
        // 部署 NFT 合约到 Base
        // 请根据你的实际情况修改这些参数
        string memory nftName = "XUBO";
        string memory nftSymbol = "XB";
        // 请将下面的 CID 替换为你上传 metadata 文件夹后得到的 CID
        string memory baseURI = "https://gateway.pinata.cloud/ipfs/bafybeihv2kzbukjqqhwsvfz6ygct2na5dm5ah3dsk64wz3qrkzbek5wx2y/";
        
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
        console.log("=====================================");
    }
}
