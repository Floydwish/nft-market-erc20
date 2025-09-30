// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import "../src/nft.sol";
import "../src/ERC20Token.sol";
import "../src/nftmarket.sol";

contract ExplainTokensReceived is Script {
    // 合约地址
    address constant NFT_ADDRESS = 0x5FbDB2315678afecb367f032d93F642f64180aa3;
    address constant TOKEN_ADDRESS = 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512;
    address constant MARKET_ADDRESS = 0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0;
    
    // 测试账户
    address constant DEPLOYER = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
    address constant BUYER = 0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC;
    
    uint256 constant NFT_ID = 4;
    uint256 constant PRICE = 100 * 10**18;
    
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        console.log("=== tokensReceived Interface Complete Usage Flow Demo ===");
        console.log("=========================================================");
        
        // 获取合约实例
        BaseERC721 nft = BaseERC721(NFT_ADDRESS);
        MyErc20_V2 token = MyErc20_V2(TOKEN_ADDRESS);
        myNFTMarket market = myNFTMarket(MARKET_ADDRESS);
        
        // 步骤1: 准备阶段
        console.log("\n[Step 1: Preparation Phase]");
        console.log("============================");
        
        // 1.1 给买家分配代币
        token.mint(BUYER, PRICE * 2);
        console.log("Allocated tokens to buyer:", token.balanceOf(BUYER));
        
        // 1.2 铸造 NFT
        nft.mint(DEPLOYER, NFT_ID);
        console.log("Minted NFT #", NFT_ID, "to seller");
        
        // 1.3 上架 NFT
        nft.approve(MARKET_ADDRESS, NFT_ID);
        market.listNFT(NFT_ADDRESS, NFT_ID, PRICE, TOKEN_ADDRESS);
        console.log("Listed NFT #", NFT_ID, "for 100 tokens");
        
        vm.stopBroadcast();
        
        // 步骤2: tokensReceived 购买流程
        console.log("\n[Step 2: tokensReceived Purchase Flow]");
        console.log("=======================================");
        _demonstrateTokensReceivedFlow();
        
        console.log("\n=== Flow Demo Completed ===");
    }
    
    function _demonstrateTokensReceivedFlow() internal {
        uint256 buyerPrivateKey = 0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a;
        vm.startBroadcast(buyerPrivateKey);
        
        BaseERC721 nft = BaseERC721(NFT_ADDRESS);
        MyErc20_V2 token = MyErc20_V2(TOKEN_ADDRESS);
        myNFTMarket market = myNFTMarket(MARKET_ADDRESS);
        
        console.log("\n2.1 Prepare Purchase Data");
        console.log("-------------------------");
        
        // 准备购买数据 - 这是关键！
        bytes memory data = abi.encode(NFT_ADDRESS, NFT_ID, PRICE);
        console.log("Encoded purchase data: abi.encode(nftAddress, nftId, price)");
        console.log("  - nftAddress:", NFT_ADDRESS);
        console.log("  - nftId:", NFT_ID);
        console.log("  - price: 100 tokens");
        
        console.log("\n2.2 Call transferWithCallback");
        console.log("-----------------------------");
        console.log("Call: token.transferWithCallback(market, amount, data)");
        console.log("  - Transfer amount: 100 tokens");
        console.log("  - Recipient: Market contract");
        console.log("  - Data: Purchase information");
        
        console.log("\n2.3 ERC20 Contract Internal Processing");
        console.log("--------------------------------------");
        console.log("Execute standard transfer: transfer(market, amount)");
        console.log("Detect recipient is a contract");
        console.log("Call: market.tokenReceived(buyer, market, amount, data)");
        
        console.log("\n2.4 Market Contract tokensReceived Processing");
        console.log("---------------------------------------------");
        console.log("Verify recipient: to == address(this)");
        console.log("Parse data: abi.decode(data, (address, uint256, uint256))");
        console.log("Verify NFT is listed");
        console.log("Verify price matches");
        console.log("Verify sufficient amount");
        console.log("Verify correct token contract");
        
        // 实际执行购买
        console.log("\n2.5 Execute Purchase");
        console.log("-------------------");
        console.log("Before execution:");
        console.log("  - NFT owner:", nft.ownerOf(NFT_ID));
        console.log("  - Buyer token balance:", token.balanceOf(BUYER));
        console.log("  - Seller token balance:", token.balanceOf(DEPLOYER));
        
        // 执行 transferWithCallback
        token.transferWithCallback(MARKET_ADDRESS, PRICE, data);
        
        console.log("\nAfter execution:");
        console.log("  - NFT owner:", nft.ownerOf(NFT_ID));
        console.log("  - Buyer token balance:", token.balanceOf(BUYER));
        console.log("  - Seller token balance:", token.balanceOf(DEPLOYER));
        
        console.log("\n2.6 Purchase Completed");
        console.log("---------------------");
        console.log("NFT transferred to buyer");
        console.log("Tokens transferred to seller");
        console.log("Listing information deleted");
        console.log("Return true for success");
        
        vm.stopBroadcast();
    }
}
