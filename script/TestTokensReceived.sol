// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import "../src/nft.sol";
import "../src/ERC20Token.sol";
import "../src/nftmarket.sol";

contract TestTokensReceived is Script {
    // 合约地址 (从部署结果获取)
    address constant NFT_ADDRESS = 0x5FbDB2315678afecb367f032d93F642f64180aa3;
    address constant TOKEN_ADDRESS = 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512;
    address constant MARKET_ADDRESS = 0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0;
    
    // 测试账户
    address constant DEPLOYER = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
    address constant USER2 = 0x43ad15c207cE38A1EE359e779Bb4F840c67DA4e5;
    
    uint256 constant NFT_ID = 3;
    uint256 constant PRICE = 100 * 10**18; // 100 tokens
    
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        console.log("=== Testing tokensReceived Function ===");
        console.log("NFT Address:", NFT_ADDRESS);
        console.log("Token Address:", TOKEN_ADDRESS);
        console.log("Market Address:", MARKET_ADDRESS);
        console.log("USER2 Address:", USER2);
        
        // 获取合约实例
        BaseERC721 nft = BaseERC721(NFT_ADDRESS);
        MyErc20_V2 token = MyErc20_V2(TOKEN_ADDRESS);
        myNFTMarket market = myNFTMarket(MARKET_ADDRESS);
        
        // 1. 给 USER2 分配代币
        console.log("\n=== Step 1: Give USER2 Tokens ===");
        token.mint(USER2, PRICE * 2);
        console.log("USER2 token balance:", token.balanceOf(USER2));
        
        // 2. 铸造新的 NFT
        console.log("\n=== Step 2: Mint New NFT ===");
        nft.mint(DEPLOYER, NFT_ID);
        console.log("Minted NFT #", NFT_ID, "to", DEPLOYER);
        console.log("NFT owner:", nft.ownerOf(NFT_ID));
        
        // 3. 上架 NFT
        console.log("\n=== Step 3: List NFT ===");
        nft.approve(MARKET_ADDRESS, NFT_ID);
        console.log("Approved market to transfer NFT");
        
        market.listNFT(NFT_ADDRESS, NFT_ID, PRICE, TOKEN_ADDRESS);
        console.log("Listed NFT #", NFT_ID, "for 100 tokens");
        
        // 检查上架信息
        myNFTMarket.listInfo memory listedInfo = market.getListedNft(NFT_ADDRESS, NFT_ID);
        console.log("Listed info - seller:", listedInfo.seller);
        console.log("Listed info - price:", listedInfo.price);
        console.log("Listed info - erc20:", listedInfo.erc20Address);
        
        vm.stopBroadcast();
        
        // 4. 使用 USER2 通过 tokensReceived 购买
        console.log("\n=== Step 4: Buy NFT via tokensReceived ===");
        _testTokensReceivedBuy();
        
        console.log("\n=== tokensReceived Test Completed ===");
    }
    
    function _testTokensReceivedBuy() internal {
        uint256 user2PrivateKey = 0x5de4111daa5ba4e5b4a13833019b2772f5ad9a916f601d6e2102bf7f6c5cee7e;
        vm.startBroadcast(user2PrivateKey);
        
        BaseERC721 nft = BaseERC721(NFT_ADDRESS);
        MyErc20_V2 token = MyErc20_V2(TOKEN_ADDRESS);
        myNFTMarket market = myNFTMarket(MARKET_ADDRESS);
        
        console.log("USER2 balance before purchase:", token.balanceOf(USER2));
        console.log("NFT owner before purchase:", nft.ownerOf(NFT_ID));
        
        // 准备购买数据
        bytes memory data = abi.encode(NFT_ADDRESS, NFT_ID, PRICE);
        console.log("Prepared purchase data");
        
        // 通过 transferWithCallback 购买
        token.transferWithCallback(MARKET_ADDRESS, PRICE, data);
        console.log("USER2 bought NFT #", NFT_ID, "via tokensReceived");
        
        // 验证结果
        console.log("NFT owner after tokensReceived purchase:", nft.ownerOf(NFT_ID));
        console.log("USER2 token balance after purchase:", token.balanceOf(USER2));
        console.log("DEPLOYER token balance after purchase:", token.balanceOf(DEPLOYER));
        
        // 检查上架信息是否已删除
        myNFTMarket.listInfo memory listedInfo = market.getListedNft(NFT_ADDRESS, NFT_ID);
        console.log("Listed info after purchase - nftAddress:", listedInfo.nftAddress);
        
        vm.stopBroadcast();
    }
}
