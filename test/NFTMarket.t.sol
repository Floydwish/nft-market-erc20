// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/nftmarket.sol";
import "../src/nft.sol";
import "../src/ERC20Token.sol";

contract NFTMarketTest is Test {
    myNFTMarket public market;
    BaseERC721 public nft;
    MyErc20 public token;
    
    address public owner;
    address public seller;
    address public buyer;
    
    uint256 public constant NFT_ID = 1;
    uint256 public constant PRICE = 100 * 10**18;

    function setUp() public {
        owner = address(this);
        seller = makeAddr("seller");
        buyer = makeAddr("buyer");
        
        // 部署合约
        market = new myNFTMarket();
        nft = new BaseERC721("TestNFT", "TNFT", "https://baidu.com/");
        token = new MyErc20();
        
        // 给卖家铸造 NFT
        nft.mint(seller, NFT_ID);
        
        // 给卖家和买家铸造代币
        token.mint(seller, 1000 * 10**18);
        token.mint(buyer, 1000 * 10**18);
    }

    // 测试上架成功：发出上架事件
    function testListNFT_Success() public {
        // 卖家授权市场合约转移 NFT
        vm.prank(seller);
        nft.approve(address(market), NFT_ID);
        
        // 设置期待出现上架事件（在上架之前）
        vm.expectEmit(true, true, false, true);
        emit myNFTMarket.ListNFT(address(nft), NFT_ID, PRICE, address(token));
        
        // 卖家上架 NFT
        vm.prank(seller);
        market.listNFT(address(nft), NFT_ID, PRICE, address(token));
        
        // 检查上架信息 (结构体中数据)
        myNFTMarket.listInfo memory listedInfo = market.getListedNft(address(nft), NFT_ID);
        assertEq(listedInfo.nftAddress, address(nft));
        assertEq(listedInfo.seller, seller);
        assertEq(listedInfo.nftId, NFT_ID);
        assertEq(listedInfo.price, PRICE);
        assertEq(listedInfo.erc20Address, address(token));
        
        // 检查 NFT 所有权已转移到市场合约
        assertEq(nft.ownerOf(NFT_ID), address(market));
    }

    // 测试上架失败：NTF 合约地址为 0
    function testListNFT_Failed_InvalidAddress() public {
        vm.prank(seller);
        vm.expectRevert("NFT contract address is invalid");
        market.listNFT(address(0), NFT_ID, PRICE, address(token));
    }

    // 测试上架失败：非所有者上架
    function testListNFT_Failed_NotOwner() public {
        // 用 buyer 上架 NFT
        vm.prank(buyer);
        vm.expectRevert("You are not the owner of this NFT");
        market.listNFT(address(nft), NFT_ID, PRICE, address(token));
    }

    // 测试上架失败：未授权 NFT 给市场合约
    function testListNFT_NotApproved() public {
        vm.prank(seller);
        vm.expectRevert("NFT not approved");
        market.listNFT(address(nft), NFT_ID, PRICE, address(token));
    }

    // 测试上架失败：重复上架
    function testListNFT_Failed_AlreadyListed() public {
        // 1.先上架一次
        vm.prank(seller);
        nft.approve(address(market), NFT_ID);
        vm.prank(seller);
        market.listNFT(address(nft), NFT_ID, PRICE, address(token));
        
        // 2.再次上架同一个 NFT
        // 由于 NFT 已经转移到市场合约，我们需要用市场合约作为调用者
        vm.prank(address(market));
        vm.expectRevert("NFT already listed");
        market.listNFT(address(nft), NFT_ID, PRICE, address(token));
    }

    // 测试上架失败：ERC20 Token 地址为 0
    function testListNFT_Failed_InvalidERC20Address() public {
        vm.prank(seller);
        nft.approve(address(market), NFT_ID);
        
        vm.prank(seller);
        vm.expectRevert("ERC20 contract address is invalid");
        market.listNFT(address(nft), NFT_ID, PRICE, address(0));
    }

    // 测试上架失败：价格为 0
    function testListNFTZeroPrice() public {
        vm.prank(seller);
        nft.approve(address(market), NFT_ID);
        
        vm.prank(seller);
        vm.expectRevert("Price must be greater than 0");
        market.listNFT(address(nft), NFT_ID, 0, address(token));
    }

    // 测试购买成功：发出购买事件
    function testBuyNFT_Success() public {
        // 先上架 NFT
        vm.prank(seller);
        nft.approve(address(market), NFT_ID);
        vm.prank(seller);
        market.listNFT(address(nft), NFT_ID, PRICE, address(token));
        
        // 买家授权市场合约转移代币
        vm.prank(buyer);
        token.approve(address(market), PRICE);
        
        uint256 sellerBalanceBefore = token.balanceOf(seller);
        uint256 buyerBalanceBefore = token.balanceOf(buyer);
        
        // 设置期待出现购买事件（在购买之前）
        // buyNFT(address nftAddress, uint256 nftId, uint256 price, address erc20Address)
        //emit myNFTMarket.ListNFT(address(nft), NFT_ID, PRICE, address(token));

         vm.expectEmit(true, true, false, true);
         emit myNFTMarket.BuyNFT(address(nft), NFT_ID, PRICE, address(token));

        // 买家购买 NFT
        vm.prank(buyer);
        market.buyNFT(address(nft), NFT_ID, PRICE, address(token));
        
        // 检查 NFT 所有权已转移到买家
        assertEq(nft.ownerOf(NFT_ID), buyer);
        
        // 检查代币转账
        assertEq(token.balanceOf(seller), sellerBalanceBefore + PRICE);
        assertEq(token.balanceOf(buyer), buyerBalanceBefore - PRICE);
        
        // 检查上架信息已删除
        myNFTMarket.listInfo memory listedInfo = market.getListedNft(address(nft), NFT_ID);
        assertEq(listedInfo.nftAddress, address(0));
    }

    // 测试购买失败：自己购买自己的 NFT
    function testBuyNFT_Failed_Buy_Owner_NFT() public {
        // seller 上架 NFT
        vm.startPrank(seller);
        nft.approve(address(market), NFT_ID);
        market.listNFT(address(nft), NFT_ID, PRICE, address(token));
        
        // seller 授权市场合约转移代币
        token.approve(address(market), PRICE);

        vm.expectRevert("Buy your owner NFT");
        market.buyNFT(address(nft), NFT_ID, PRICE, address(token));

        vm.stopPrank();
    }

    // 测试购买失败：重复购买
    function testBuyNFT_Failed_Buy_Twice() public {
        // seller 上架 NFT
        vm.startPrank(seller);
        nft.approve(address(market), NFT_ID);
        market.listNFT(address(nft), NFT_ID, PRICE, address(token));
        vm.stopPrank();

        // 买家授权市场合约转移代币
        vm.startPrank(buyer);
        token.approve(address(market), PRICE);

        // 买家购买 NFT
        market.buyNFT(address(nft), NFT_ID, PRICE, address(token));

        // 已经被购买了，因此市场已经下架
        vm.expectRevert("NFT not listed");
        market.buyNFT(address(nft), NFT_ID, PRICE, address(token));

        vm.stopPrank();
    }

    // 测试购买失败：支付Token过多
    function testBuyNFT_Failed_PayTooMuch() public {
        // 先上架 NFT
        vm.prank(seller);
        nft.approve(address(market), NFT_ID);
        vm.prank(seller);
        market.listNFT(address(nft), NFT_ID, PRICE, address(token));
        
        // 买家授权市场合约转移更多代币
        vm.prank(buyer);
        token.approve(address(market), PRICE + 10);
        
        // 测试支付过多价格购买
        vm.prank(buyer);
        vm.expectRevert("Price mismatch");
        market.buyNFT(address(nft), NFT_ID, PRICE + 10, address(token));
    }

    // 测试购买失败：支付Token过少
    function testBuyNFT_Failed_PayTooLittle() public {
        // 先上架 NFT
        vm.prank(seller);
        nft.approve(address(market), NFT_ID);
        vm.prank(seller);
        market.listNFT(address(nft), NFT_ID, PRICE, address(token));
        
        // 买家授权市场合约转移更少代币
        vm.prank(buyer);
        token.approve(address(market), PRICE - 10);
        
        // 测试支付过少价格购买
        vm.prank(buyer);
        vm.expectRevert("Price mismatch");
        market.buyNFT(address(nft), NFT_ID, PRICE - 10, address(token));
    }

    // 测试购买失败：未上架
    function testBuyNFT_Failed_NotListed() public {
        // 测试购买未上架的 NFT
        vm.prank(buyer);
        vm.expectRevert("NFT not listed");
        market.buyNFT(address(nft), NFT_ID, PRICE, address(token));
    }

    // 测试购买失败：余额不足
    function testBuyNFT_Failed_InsufficientBalance() public {
        // 先上架 NFT
        vm.prank(seller);
        nft.approve(address(market), NFT_ID);
        vm.prank(seller);
        market.listNFT(address(nft), NFT_ID, PRICE, address(token));
        
        // 创建一个余额不足的买家
        address poorBuyer = makeAddr("poorBuyer");
        token.mint(poorBuyer, PRICE / 2); // 只给一半的余额
        
        // 买家授权市场合约转移代币
        vm.prank(poorBuyer);
        token.approve(address(market), PRICE);
        
        vm.prank(poorBuyer);
        vm.expectRevert("Insufficient balance");
        market.buyNFT(address(nft), NFT_ID, PRICE, address(token));
    }

    // 测试购买失败：授权额度不足
    function testBuyNFT_Failed_InsufficientAllowance() public {
        // 先上架 NFT
        vm.prank(seller);
        nft.approve(address(market), NFT_ID);
        vm.prank(seller);
        market.listNFT(address(nft), NFT_ID, PRICE, address(token));
        
        // 买家授权额度不足
        vm.prank(buyer);
        token.approve(address(market), PRICE / 2);
        
        vm.prank(buyer);
        vm.expectRevert("Insufficient allowance");
        market.buyNFT(address(nft), NFT_ID, PRICE, address(token));
    }

    // 测试购买失败：NFT 地址无效
    function testBuyNFT_Failed_InvalidAddress() public {
        // 先上架 NFT
        vm.prank(seller);
        nft.approve(address(market), NFT_ID);
        vm.prank(seller);
        market.listNFT(address(nft), NFT_ID, PRICE, address(token));
        
        // 测试无效的 NFT 合约地址
        vm.prank(buyer);
        vm.expectRevert("NFT contract address is invalid");
        market.buyNFT(address(0), NFT_ID, PRICE, address(token));
    }

    // 测试购买失败：ERC20 地址无效
    function testBuyNFT_Failed_InvalidERC20Address() public {
        // 先上架 NFT
        vm.prank(seller);
        nft.approve(address(market), NFT_ID);
        vm.prank(seller);
        market.listNFT(address(nft), NFT_ID, PRICE, address(token));
        
        // 测试无效的 ERC20 合约地址
        vm.prank(buyer);
        vm.expectRevert("ERC20 contract address is invalid");
        market.buyNFT(address(nft), NFT_ID, PRICE, address(0));
    }

    // 测试购买失败：0 价格
    function testBuyNFT_Failed_ZeroPrice() public {
        // 先上架 NFT
        vm.prank(seller);
        nft.approve(address(market), NFT_ID);
        vm.prank(seller);
        market.listNFT(address(nft), NFT_ID, PRICE, address(token));
        
        // 测试零价格购买
        vm.prank(buyer);
        vm.expectRevert("Price mismatch");
        market.buyNFT(address(nft), NFT_ID, 0, address(token));
    }

    // 测试事件：上架事件、购买事件
    function testEvents() public {
        // 测试上架事件
        vm.prank(seller);
        nft.approve(address(market), NFT_ID);
        
        vm.expectEmit(true, true, false, true);
        emit myNFTMarket.ListNFT(address(nft), NFT_ID, PRICE, address(token));
        vm.prank(seller);
        market.listNFT(address(nft), NFT_ID, PRICE, address(token));
        
        // 测试购买事件
        vm.prank(buyer);
        token.approve(address(market), PRICE);
        
        vm.expectEmit(true, true, false, true);
        emit myNFTMarket.BuyNFT(address(nft), NFT_ID, PRICE, address(token));
        vm.prank(buyer);
        market.buyNFT(address(nft), NFT_ID, PRICE, address(token));
    }

    
    // ==================== 模糊测试 ==================== 
    // 随机条件：1.随机价格 2.随机地址
    // 模糊测试：随机价格上架NFT
    // 随机价格：Foundry 自动生成（应用时：限定范围）
    // 随机地址：Foundry 自动生成（应用时：排除特定地址）

    // Foundry 的模糊测试：自动组合价格和地址；256次测试随机组合；包括边界值和特殊值
    // 扩展使用：在testFuzz开头的接口中，参数为基本类型，Foundry 会自动生成随机值
    function testFuzz_ListNFT_Random_Price_Address(uint256 price, address randomSeller, address randomBuyer, uint256 randomNFTID) public {
        // 随机范围：0.01 ether 到 10000 ether
        vm.assume(price >= 0.01 ether && price <= 10000 ether);
        
        // 排除零地址
        vm.assume(randomSeller != address(0));
        vm.assume(randomBuyer != address(0));
        vm.assume(randomBuyer != randomSeller);

        // 排除合约地址
        vm.assume(randomSeller.code.length == 0);
        vm.assume(randomBuyer.code.length == 0);
    
        // 排除已铸造的 NFT
        vm.assume(randomNFTID !=  NFT_ID);
        
        // 给随机用户铸造NFT和代币
        nft.mint(randomSeller, randomNFTID);
        token.mint(randomSeller, price + 1000 ether); // 确保有足够余额
        token.mint(randomBuyer, price + 1000 ether); // 确保有足够余额
        
        vm.startPrank(randomSeller);

        // 授权 NFT 给市场合约
        nft.approve(address(market), randomNFTID);
        
        // 设置事件期望
        vm.expectEmit(true, true, false, true);
        emit myNFTMarket.ListNFT(address(nft), randomNFTID, price, address(token));
        
        // 上架
        market.listNFT(address(nft), randomNFTID, price, address(token));
        vm.stopPrank();
        
        // 验证上架信息
        myNFTMarket.listInfo memory listedInfo = market.getListedNft(address(nft), randomNFTID);
        assertEq(listedInfo.nftAddress, address(nft));
        assertEq(listedInfo.seller, randomSeller);
        assertEq(listedInfo.nftId, randomNFTID);
        assertEq(listedInfo.price, price);
        assertEq(listedInfo.erc20Address, address(token));
        
        // 验证NFT所有权转移
        assertEq(nft.ownerOf(randomNFTID), address(market));

        // 设置 buyer 为交易发起者
        vm.startPrank(randomBuyer);

        // 授权代币给市场合约
        token.approve(address(market), price);

        // 设置事件期望
        vm.expectEmit(true, true, false, true);
        emit myNFTMarket.BuyNFT(address(nft), randomNFTID, price, address(token));

        // 购买 NFT
        market.buyNFT(address(nft), randomNFTID, price, address(token));
        vm.stopPrank();

        // 检查 NFT 所有权已转移到买家
        assertEq(nft.ownerOf(randomNFTID), randomBuyer);
    }

    // ==================== 不可变测试 ====================
    
    // 不可变测试：测试无论如何买卖，NFTMarket合约中都不可能有Token持仓

/*
    [PASS] invariant_NoTokenBalance() (runs: 256, calls: 128000, reverts: 102753)
    // 测试合约，测试接口次数，回滚次数（正常回滚）
    // 失败次数为0：说明不可变条件（从未改变）

    ╭-------------+-------------------+-------+---------+----------╮
    | Contract    | Selector          | Calls | Reverts | Discards |
    +==============================================================+
    | MyErc20     | approve           | 8461  | 17      | 0        |
    |-------------+-------------------+-------+---------+----------|
    | MyErc20     | mint              | 8545  | 8544    | 0        |
    |-------------+-------------------+-------+---------+----------|
    | MyErc20     | renounceOwnership | 8457  | 8456    | 0        |
    |-------------+-------------------+-------+---------+----------|
    | MyErc20     | transfer          | 8705  | 8606    | 0        |
    |-------------+-------------------+-------+---------+----------|
    | MyErc20     | transferFrom      | 8587  | 8477    | 0        |
    |-------------+-------------------+-------+---------+----------|
    | MyErc20     | transferOwnership | 8653  | 8652    | 0        |
    |-------------+-------------------+-------+---------+----------|
    | BaseERC721  | approve           | 8617  | 8617    | 0        |
    |-------------+-------------------+-------+---------+----------|
    | BaseERC721  | mint              | 8376  | 197     | 0        |
    |-------------+-------------------+-------+---------+----------|
    | BaseERC721  | safeTransferFrom  | 17115 | 17115   | 0        |
    |-------------+-------------------+-------+---------+----------|
    | BaseERC721  | setApprovalForAll | 8413  | 1       | 0        |
    |-------------+-------------------+-------+---------+----------|
    | BaseERC721  | transferFrom      | 8470  | 8470    | 0        |
    |-------------+-------------------+-------+---------+----------|
    | myNFTMarket | buyNFT            | 8582  | 8582    | 0        |
    |-------------+-------------------+-------+---------+----------|
    | myNFTMarket | listNFT           | 8525  | 8525    | 0        |
    |-------------+-------------------+-------+---------+----------|
    | myNFTMarket | tokenReceived     | 8494  | 8494    | 0        |
    ╰-------------+-------------------+-------+---------+----------╯
    */
    function invariant_NoTokenBalance() public view {
        // 检查NFTMarket合约中的Token余额始终为0
        assertEq(token.balanceOf(address(market)), 0, "NFTMarket should never hold tokens");
    }

}


/*
编写 NFTMarket 合约：

支持设定任意ERC20价格来上架NFT
支持支付ERC20购买指定的NFT
要求测试内容：

上架NFT：测试上架成功和失败情况，要求断言错误信息和上架事件。
购买NFT：测试购买成功、自己购买自己的NFT、NFT被重复购买、支付Token过多或者过少情况，要求断言错误信息和购买事件。
模糊测试：测试随机使用 0.01-10000 Token价格上架NFT，并随机使用任意Address购买NFT
「可选」不可变测试：测试无论如何买卖，NFTMarket合约中都不可能有 Token 持仓
提交内容要求

使用 foundry 测试和管理合约；
提交 Github 仓库链接到挑战中；
提交 foge test 测试执行结果txt到挑战中；
查看批注


*/
