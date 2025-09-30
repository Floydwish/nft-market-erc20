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
        nft = new BaseERC721("TestNFT", "TNFT", "https://example.com/");
        token = new MyErc20();
        
        // 给卖家铸造 NFT
        nft.mint(seller, NFT_ID);
        
        // 给买家铸造代币
        token.mint(buyer, 1000 * 10**18);
    }

    function testListNFT() public {
        // 卖家授权市场合约转移 NFT
        vm.prank(seller);
        nft.approve(address(market), NFT_ID);
        
        // 卖家上架 NFT
        vm.prank(seller);
        market.listNFT(address(nft), NFT_ID, PRICE, address(token));
        
        // 检查上架信息
        myNFTMarket.listInfo memory listedInfo = market.getListedNft(address(nft), NFT_ID);
        assertEq(listedInfo.nftAddress, address(nft));
        assertEq(listedInfo.seller, seller);
        assertEq(listedInfo.nftId, NFT_ID);
        assertEq(listedInfo.price, PRICE);
        assertEq(listedInfo.erc20Address, address(token));
        
        // 检查 NFT 所有权已转移到市场合约
        assertEq(nft.ownerOf(NFT_ID), address(market));
    }

    function testListNFTInvalidAddress() public {
        // 测试无效的 NFT 合约地址
        vm.prank(seller);
        vm.expectRevert("NFT contract address is invalid");
        market.listNFT(address(0), NFT_ID, PRICE, address(token));
    }

    function testListNFTNotOwner() public {
        // 测试非 NFT 拥有者上架
        vm.prank(buyer);
        vm.expectRevert("You are not the owner of this NFT");
        market.listNFT(address(nft), NFT_ID, PRICE, address(token));
    }

    function testListNFTNotApproved() public {
        // 测试未授权市场合约转移 NFT
        vm.prank(seller);
        vm.expectRevert("NFT not approved");
        market.listNFT(address(nft), NFT_ID, PRICE, address(token));
    }

    function testListNFTAlreadyListed() public {
        // 先上架一次
        vm.prank(seller);
        nft.approve(address(market), NFT_ID);
        vm.prank(seller);
        market.listNFT(address(nft), NFT_ID, PRICE, address(token));
        
        // 再次上架同一个 NFT（需要从市场合约的角度来测试）
        // 由于 NFT 已经转移到市场合约，我们需要用市场合约作为调用者
        vm.prank(address(market));
        vm.expectRevert("NFT already listed");
        market.listNFT(address(nft), NFT_ID, PRICE, address(token));
    }

    function testListNFTInvalidERC20Address() public {
        vm.prank(seller);
        nft.approve(address(market), NFT_ID);
        
        vm.prank(seller);
        vm.expectRevert("ERC20 contract address is invalid");
        market.listNFT(address(nft), NFT_ID, PRICE, address(0));
    }

    function testListNFTZeroPrice() public {
        vm.prank(seller);
        nft.approve(address(market), NFT_ID);
        
        vm.prank(seller);
        vm.expectRevert("Price must be greater than 0");
        market.listNFT(address(nft), NFT_ID, 0, address(token));
    }

    function testBuyNFT() public {
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

    function testBuyNFTNotListed() public {
        // 测试购买未上架的 NFT
        vm.prank(buyer);
        vm.expectRevert("NFT not listed");
        market.buyNFT(address(nft), NFT_ID, PRICE, address(token));
    }

    function testBuyNFTInsufficientBalance() public {
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

    function testBuyNFTInsufficientAllowance() public {
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

    function testBuyNFTInvalidAddress() public {
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

    function testBuyNFTInvalidERC20Address() public {
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

    function testBuyNFTZeroPrice() public {
        // 先上架 NFT
        vm.prank(seller);
        nft.approve(address(market), NFT_ID);
        vm.prank(seller);
        market.listNFT(address(nft), NFT_ID, PRICE, address(token));
        
        // 测试零价格购买
        vm.prank(buyer);
        vm.expectRevert("Price must be greater than 0");
        market.buyNFT(address(nft), NFT_ID, 0, address(token));
    }

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
}
