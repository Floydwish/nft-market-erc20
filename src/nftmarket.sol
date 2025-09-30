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
    struct listInfo {
        address nftAddress;  // NFT 合约地址
        address seller;      // 卖家地址
        uint256 nftId;       // NFT ID
        uint256 price;       // 价格
        address erc20Address; // 付款代币合约地址
    }


    mapping(address => mapping(uint256 => listInfo)) public listedNft;

    constructor(){}

    // 事件
    event ListNFT(address indexed nftAddress, uint256 indexed nftId, uint256 price, address erc20Address);
    event BuyNFT(address indexed nftAddress, uint256 indexed nftId, uint256 price, address erc20Address);

    // 上架
    function listNFT(address nftAddress, uint256 nftId, uint256 price, address erc20Address) public {

        console.log("nftAddress", nftAddress);
        console.log("nftId", nftId);
        console.log("msg.sender", msg.sender);

        // 1. 检查 NFT 合约地址是否正常
        console.log("address(0)", address(0));
        require(nftAddress != address(0), "NFT contract address is invalid");
        console.log("11111111");

        // 2. 检查 NFT 是否存在
        IERC721 nftContract = IERC721(nftAddress);
        console.log("89999999", nftContract.ownerOf(nftId));
        require(nftContract.ownerOf(nftId) != address(0), "NFT not exists");

        // 3. 检查 NFT 是否是卖家所有
        require(IERC721(nftAddress).ownerOf(nftId) == msg.sender, "You are not the owner of this NFT");


        // 4. 检查 NFT 是否已经上架
        require(listedNft[nftAddress][nftId].nftAddress == address(0), "NFT already listed");

        // 5. 检查 NFT 是否授权给市场合约
        require(nftContract.getApproved(nftId) == address(this), "NFT not approved");

        // 6. 检查代币合约地址是否正常
        require(erc20Address != address(0), "ERC20 contract address is invalid");

        // 7. 检查价格是否大于0
        require(price > 0, "Price must be greater than 0");

        // 8. 将 NFT 转移到市场合约
        nftContract.transferFrom(msg.sender, address(this), nftId);

        // 9. 上架
        listedNft[nftAddress][nftId] = listInfo(nftAddress, msg.sender,nftId, price, erc20Address);

        // 10. 触发上架事件
        emit ListNFT(nftAddress, nftId, price, erc20Address);
    }

    // 购买
    function buyNFT(address nftAddress, uint256 nftId, uint256 price, address erc20Address) public {
        // 1. 检查 NFT 合约地址是否正常
        require(nftAddress != address(0), "NFT contract address is invalid");

        // 3. 检查 NFT 是否已经上架
        require(listedNft[nftAddress][nftId].nftAddress != address(0), "NFT not listed");

        // 4. 检查代币合约地址是否正常
        require(erc20Address != address(0), "ERC20 contract address is invalid");

        // 5. 检查买家代币余额是否充足
        IERC20 erc20Contract = IERC20(erc20Address);
        require(erc20Contract.balanceOf(msg.sender) >= price, "Insufficient balance");

        // 7. 检查买家代币授权给市场合约的额度
        require(erc20Contract.allowance(msg.sender, address(this)) >= price ,"Insufficient allowance");

        // 8. 检查价格是否大于0
        require(price > 0, "Price must be greater than 0");

        // 9. 将代币从买家转移到卖家
        require(erc20Contract.transferFrom(msg.sender, listedNft[nftAddress][nftId].seller, price), "Transfer failed");

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
        require(to == address(this), "Invalid receiver");
        
        // 2. 解析 data 参数获取购买信息
        // data 格式: abi.encode(nftAddress, nftId, price)
        require(data.length >= 96, "Invalid data length"); // 3 * 32 bytes
        
        (address nftAddress, uint256 nftId, uint256 price) = abi.decode(data, (address, uint256, uint256));
        
        // 3. 检查 NFT 是否已上架
        require(listedNft[nftAddress][nftId].nftAddress != address(0), "NFT not listed");
        
        // 4. 检查价格是否匹配
        require(price == listedNft[nftAddress][nftId].price, "Price mismatch");
        
        // 5. 检查转账金额是否足够
        require(amount >= price, "Insufficient payment");
        
        // 6. 检查调用者是否为 ERC20 合约
        require(msg.sender == listedNft[nftAddress][nftId].erc20Address, "Invalid ERC20 token");
        
        // 7. 执行 NFT 购买逻辑
        _executePurchase(nftAddress, nftId, from, price);
        
        // 8. 如果有剩余金额，退还给买家
        if (amount > price) {
            require(IERC20(msg.sender).transfer(from, amount - price), "Refund failed");
        }
        
        return true;
    }
    
    // 处理购买逻辑
    function _executePurchase(address nftAddress, uint256 nftId, address buyer, uint256 price) internal {
        // 1. 获取卖家地址和 ERC20 合约地址（在删除前获取）
        address seller = listedNft[nftAddress][nftId].seller;
        address erc20Address = listedNft[nftAddress][nftId].erc20Address;
        
        // 2. 将 NFT 从市场合约转移到买家
        IERC721 nftContract = IERC721(nftAddress);
        nftContract.transferFrom(address(this), buyer, nftId);
        
        // 3. 将代币从买家转移到卖家
        IERC20 erc20Contract = IERC20(erc20Address);
        require(erc20Contract.transfer(seller, price), "Token transfer to seller failed");
        
        // 4. 删除上架信息
        delete listedNft[nftAddress][nftId];
        
        // 5. 触发购买事件
        emit BuyNFT(nftAddress, nftId, price, erc20Address);
    }

}