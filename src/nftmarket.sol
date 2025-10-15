// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/*
合约设计说明：

一、核心功能
1. listNFT() - 上架 NFT (任意符合 ERC721 标准的 NFT)
2. buyNFT() - 标准购买 NFT (任意符合 ERC20 标准的代币)
3. tokensReceived() - 扩展购买 NFT (通过 ERC20 转账回调自动购买)

二、购买方式
1. 标准方式：先 approve，再调用 buyNFT()
2. 扩展方式：调用 transferWithCallback() 自动购买

*/

import "@openzeppelin/token/ERC721/IERC721.sol";
import "@openzeppelin/token/ERC20/IERC20.sol";

import {console} from "forge-std/console.sol";

// 导入 ITokenReceiver 接口
import "../src/ERC20Token.sol";

contract myNFTMarket is ITokenReceiver {
    // 上架结构体
    /*struct listInfo {
        address nftAddress;  // NFT 合约地址
        address seller;      // 卖家地址
        uint256 nftId;       // NFT ID
        uint256 price;       // 价格
        address erc20Address; // 付款代币合约地址
    }*/

    // 存储优化（节省 gas)
    struct listInfo {
    address nftAddress;   // slot 0
    address seller;       // slot 1
    uint64 nftId;         // slot 2 (支持 184 亿个 NFT) 
    uint192 price;        // slot 2 (最大 6.27e39 ETH)
    address erc20Address; // slot 3
}


    mapping(address => mapping(uint256 => listInfo)) public listedNft;

    constructor(){}

    // 事件
    event ListNFT(address indexed nftAddress, uint256 indexed nftId, uint256 price, address erc20Address);
    event BuyNFT(address indexed nftAddress, uint256 indexed nftId, uint256 price, address erc20Address);

    // ==================== 自定义错误（Gas 优化）====================
    // Gas 优化：使用自定义错误比字符串错误节省约 5000-10000 gas
    
    // NFT 相关错误
    error InvalidNFTAddress();
    error NFTNotExists();
    error NotNFTOwner();
    error NFTAlreadyListed();
    error NFTNotApproved();
    error NFTNotListed();
    
    // ERC20 相关错误
    error InvalidERC20Address();
    error InvalidERC20Token();
    error InsufficientBalance();
    error InsufficientAllowance();
    
    // 价格相关错误
    error InvalidPrice();
    error PriceMismatch();
    error InsufficientPayment();
    
    // 交易相关错误
    error CannotBuyOwnNFT();
    error TransferFailed();
    error TokenTransferFailed();
    error RefundFailed();
    
    // 数据验证错误
    error InvalidReceiver();
    error InvalidDataLength();
    
    // 上架
    function listNFT(address nftAddress, uint256 nftId, uint256 price, address erc20Address) public {

        // 1. 检查 NFT 合约地址是否正常
        if(nftAddress == address(0)) revert InvalidNFTAddress();

        // 2. 检查 NFT 是否存在
        IERC721 nftContract = IERC721(nftAddress);
        if(nftContract.ownerOf(nftId) == address(0)) revert NFTNotExists();

        // 3. 检查 NFT 是否是卖家所有
        if(IERC721(nftAddress).ownerOf(nftId) != msg.sender) revert NotNFTOwner();


        // 4. 检查 NFT 是否已经上架
        if(listedNft[nftAddress][nftId].nftAddress != address(0)) revert NFTAlreadyListed();

        // 5. 检查 NFT 是否授权给市场合约
        if(nftContract.getApproved(nftId) != address(this)) revert NFTNotApproved();

        // 6. 检查代币合约地址是否正常
        if(erc20Address == address(0)) revert InvalidERC20Address();

        // 7. 检查价格是否大于0
        if(price == 0) revert InvalidPrice();

        // 8. 将 NFT 转移到市场合约
        nftContract.transferFrom(msg.sender, address(this), nftId);

        // 9. 上架（直接写入存储）
        listedNft[nftAddress][nftId] = listInfo({
            nftAddress: nftAddress, 
            seller: msg.sender, 
            nftId: uint64(nftId),
            price: uint192(price), 
            erc20Address: erc20Address
        });

        // 10. 触发上架事件
        emit ListNFT(nftAddress, nftId, price, erc20Address);
    }

    // 购买
    function buyNFT(address nftAddress, uint256 nftId, uint256 price, address erc20Address) public {
        // 1. 检查 NFT 合约地址是否正常
        //require(nftAddress != address(0), "NFT contract address is invalid");
        if(nftAddress == address(0)) revert InvalidNFTAddress();

        // 2. 检查 NFT 是否已经上架
        // 优化 gas: 一次性读取到内存
        listInfo memory listing = listedNft[nftAddress][nftId];
        if(listing.nftAddress == address(0)) revert NFTNotListed();

        // 3. 检查代币合约地址是否正常
        if(erc20Address == address(0)) revert InvalidERC20Address();

        // 4. 检查是否自己购买自己的 NFT
        if(msg.sender == listing.seller) revert CannotBuyOwnNFT();

        // 5. 检查买家代币余额是否充足
        IERC20 erc20Contract = IERC20(erc20Address);
        if(erc20Contract.balanceOf(msg.sender) < price) revert InsufficientBalance();

        // 7. 检查买家代币授权给市场合约的额度
        if(erc20Contract.allowance(msg.sender, address(this)) < price) revert InsufficientAllowance();

        // 8. 检查价格是否匹配
        // 防止买家通过支付错误价格来影响市场
        if(price != listing.price) revert PriceMismatch();

        // 9. 将代币从买家转移到卖家
        if(!erc20Contract.transferFrom(msg.sender, listing.seller, price)) revert TransferFailed();

        // 10. 将 NFT 从市场合约转移到买家
        IERC721 nftContract = IERC721(nftAddress);
        nftContract.transferFrom(address(this), msg.sender, nftId);
        
        // 11. 删除上架信息
        delete listedNft[nftAddress][nftId];
        
        // 12. 触发购买事件
        emit BuyNFT(nftAddress, nftId, price, erc20Address);
    }

    // 获取上架的 NFT 信息
    function getListedNft(address nftAddress, uint256 nftId) public view returns (listInfo memory) {
        return listedNft[nftAddress][nftId];
    }

    // ERC20 转账回调购买
    function tokenReceived(address from, address to, uint256 amount, bytes calldata data) external override returns (bool) {
        // 1. 检查调用者是否为 ERC20 合约
        if(to != address(this)) revert InvalidReceiver();
        
        // 2. 解析 data 参数获取购买信息
        // data 格式: abi.encode(nftAddress, nftId, price)
        if(data.length < 96) revert InvalidDataLength(); // 3 * 32 bytes
        
        (address nftAddress, uint256 nftId, uint256 price) = abi.decode(data, (address, uint256, uint256));
        
        // 3. 检查 NFT 是否已上架
        listInfo memory listing = listedNft[nftAddress][nftId];
        if(listing.nftAddress == address(0)) revert NFTNotListed();
        
        // 4. 检查价格是否匹配
        if(price !=  listing.price) revert PriceMismatch();
        
        // 5. 检查转账金额是否足够
        if(amount < price) revert InsufficientPayment();
        
        // 6. 检查调用者是否为 ERC20 合约
        if(msg.sender != listing.erc20Address) revert InvalidERC20Token();
        
        // 7. 执行 NFT 购买逻辑
        _executePurchase(nftAddress, nftId, from, price);
        
        // 8. 如果有剩余金额，退还给买家
        if (amount > price) {
            if(!IERC20(msg.sender).transfer(from, amount - price)) revert RefundFailed();
        }
        
        return true;
    }
    
    // 处理购买逻辑
    function _executePurchase(address nftAddress, uint256 nftId, address buyer, uint256 price) internal {
        // 1. 获取卖家地址和 ERC20 合约地址（在删除前获取）
        listInfo memory listing = listedNft[nftAddress][nftId];
        address seller = listing.seller;
        address erc20Address = listing.erc20Address;
        
        // 2. 将 NFT 从市场合约转移到买家
        IERC721 nftContract = IERC721(nftAddress);
        nftContract.transferFrom(address(this), buyer, nftId);
        
        // 3. 将代币从买家转移到卖家
        IERC20 erc20Contract = IERC20(erc20Address);
        if(!erc20Contract.transfer(seller, price)) revert TokenTransferFailed();
        
        // 4. 删除上架信息
        delete listedNft[nftAddress][nftId];
        
        // 5. 触发购买事件
        emit BuyNFT(nftAddress, nftId, price, erc20Address);
    }

}