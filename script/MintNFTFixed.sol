// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "../src/nft.sol";

contract MintNFTFixed is Script {
    function run() external {
        // 从环境变量获取私钥
        string memory privateKeyStr = vm.envString("PRIVATE_KEY");
        uint256 deployerPrivateKey = vm.parseUint(privateKeyStr);
        
        // 合约地址直接设置在代码中（部署后需要更新这个地址）
        address nftContractAddress = 0x0000000000000000000000000000000000000000; // 请替换为实际部署的合约地址
        
        // 开始广播交易
        vm.startBroadcast(deployerPrivateKey);
        
        // 获取 NFT 合约实例
        BaseERC721 nft = BaseERC721(nftContractAddress);
        
        // 铸造 NFT 给部署者
        address deployer = vm.addr(deployerPrivateKey);
        
        // 铸造多个 NFT（你可以根据需要修改数量）
        for (uint256 i = 1; i <= 10; i++) {
            nft.mint(deployer, i);
            console.log("Minted NFT #%d to %s", i, deployer);
        }
        
        // 停止广播
        vm.stopBroadcast();
        
        console.log("=== Minting Completed Successfully ===");
        console.log("Minted 10 NFTs to:", deployer);
        console.log("Contract Address:", nftContractAddress);
        console.log("Owner balance:", nft.balanceOf(deployer));
    }
}
