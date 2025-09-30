// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import "../src/nft.sol";
import "../src/ERC20Token.sol";
import "../src/nftmarket.sol";

contract TestAllFunctions is Script {
    // 合约地址 (从部署结果获取)
    address constant NFT_ADDRESS = 0x5FbDB2315678afecb367f032d93F642f64180aa3;
    address constant TOKEN_ADDRESS = 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512;
    address constant MARKET_ADDRESS = 0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0;
    
    // 测试账户
    address constant DEPLOYER = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
    address constant USER1 = 0x70997970C51812dc3A010C7d01b50e0d17dc79C8;
    address constant USER2 = 0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC;
    
    uint256 constant NFT_ID = 1;
    uint256 constant PRICE = 100 * 10**18; // 100 tokens
    
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        console.log("=== Starting Complete Test Flow ===");
        console.log("NFT Address:", NFT_ADDRESS);
        console.log("Token Address:", TOKEN_ADDRESS);
        console.log("Market Address:", MARKET_ADDRESS);
        
        // 获取合约实例
        BaseERC721 nft = BaseERC721(NFT_ADDRESS);
        MyErc20_V2 token = MyErc20_V2(TOKEN_ADDRESS);
        myNFTMarket market = myNFTMarket(MARKET_ADDRESS);
        
        // 测试1: 铸造 NFT
        console.log("\n=== Test 1: Mint NFT ===");
        nft.mint(DEPLOYER, NFT_ID);
        console.log("Minted NFT #", NFT_ID, "to", DEPLOYER);
        console.log("NFT owner:", nft.ownerOf(NFT_ID));
        
        // 测试2: 给用户分配代币
        console.log("\n=== Test 2: Distribute Tokens ===");
        token.mint(USER1, PRICE * 2);
        token.mint(USER2, PRICE * 2);
        console.log("USER1 token balance:", token.balanceOf(USER1));
        console.log("USER2 token balance:", token.balanceOf(USER2));
        
        // 测试3: NFT 上架
        console.log("\n=== Test 3: List NFT ===");
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
        
        // 测试4: 普通购买 NFT (使用 USER1)
        console.log("\n=== Test 4: Buy NFT (Normal Method) ===");
        _testNormalBuy();
        
        // 测试5: 使用 tokensReceived 购买 NFT (使用 USER2)
        console.log("\n=== Test 5: Buy NFT via tokensReceived ===");
        _testTokensReceivedBuy();
        
        console.log("\n=== All Tests Completed ===");
    }
    
    function _testNormalBuy() internal {
        uint256 user1PrivateKey = 0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d;
        vm.startBroadcast(user1PrivateKey);
        
        BaseERC721 nft = BaseERC721(NFT_ADDRESS);
        MyErc20_V2 token = MyErc20_V2(TOKEN_ADDRESS);
        myNFTMarket market = myNFTMarket(MARKET_ADDRESS);
        
        // 授权市场合约转移代币
        token.approve(MARKET_ADDRESS, PRICE);
        console.log("USER1 approved market to spend tokens");
        
        // 购买 NFT
        market.buyNFT(NFT_ADDRESS, NFT_ID, PRICE, TOKEN_ADDRESS);
        console.log("USER1 bought NFT #", NFT_ID);
        
        // 验证结果
        console.log("NFT owner after purchase:", nft.ownerOf(NFT_ID));
        console.log("USER1 token balance after purchase:", token.balanceOf(USER1));
        console.log("DEPLOYER token balance after purchase:", token.balanceOf(DEPLOYER));
        
        vm.stopBroadcast();
    }
    
    function _testTokensReceivedBuy() internal {
        // 首先需要重新上架一个 NFT
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        
        BaseERC721 nft = BaseERC721(NFT_ADDRESS);
        MyErc20_V2 token = MyErc20_V2(TOKEN_ADDRESS);
        myNFTMarket market = myNFTMarket(MARKET_ADDRESS);
        
        // 铸造新的 NFT
        uint256 newNFTId = 2;
        nft.mint(DEPLOYER, newNFTId);
        console.log("Minted NFT #", newNFTId, "for tokensReceived test");
        
        // 上架新 NFT
        nft.approve(MARKET_ADDRESS, newNFTId);
        market.listNFT(NFT_ADDRESS, newNFTId, PRICE, TOKEN_ADDRESS);
        console.log("Listed NFT #", newNFTId, "for tokensReceived test");
        
        vm.stopBroadcast();
        
        // 使用 USER2 通过 tokensReceived 购买
        uint256 user2PrivateKey = 0x5de4111daa5ba4e5b4a13833019b2772f5ad9a916f601d6e2102bf7f6c5cee7e;
        vm.startBroadcast(user2PrivateKey);
        
        // 准备购买数据
        bytes memory data = abi.encode(NFT_ADDRESS, newNFTId, PRICE);
        
        // 通过 transferWithCallback 购买
        token.transferWithCallback(MARKET_ADDRESS, PRICE, data);
        console.log("USER2 bought NFT #", newNFTId, "via tokensReceived");
        
        // 验证结果
        console.log("NFT owner after tokensReceived purchase:", nft.ownerOf(newNFTId));
        console.log("USER2 token balance after purchase:", token.balanceOf(USER2));
        console.log("DEPLOYER token balance after purchase:", token.balanceOf(DEPLOYER));
        
        vm.stopBroadcast();
    }
}
