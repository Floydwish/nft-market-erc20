// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "../src/nft.sol";

contract MintNFT is Script {
    function run() external {
        // 从环境变量获取私钥和合约地址
        string memory privateKeyStr = vm.envString("PRIVATE_KEY");
        uint256 deployerPrivateKey = vm.parseUint(privateKeyStr);
        address nftContractAddress = vm.envAddress("NFT_CONTRACT_ADDRESS");
        
        // 开始广播交易
        vm.startBroadcast(deployerPrivateKey);
        
        // 获取 NFT 合约实例
        BaseERC721 nft = BaseERC721(nftContractAddress);
        
        // 铸造 NFT 给部署者
        address deployer = vm.addr(deployerPrivateKey);
        
        // 铸造 2 个 NFT
        for (uint256 i = 1; i <= 2; i++) {
            nft.mint(deployer, i);
            console.log("Minted NFT #%d to %s", i, deployer);
        }
        
        // 停止广播
        vm.stopBroadcast();
        
        console.log("Minting completed!");
        console.log("Minted 2 NFTs to:", deployer);
    }
}
