# NFT Marketplace with ERC20 Integration

一个基于 Solidity 的去中心化 NFT 市场，支持 ERC20 代币支付和扩展转账购买功能。

## 📑 目录

- [📋 项目概述](#-项目概述)
- [🏗️ 合约结构与功能](#️-合约结构与功能)
  - [1. BaseERC721 (nft.sol)](#1-baseerc721-nftsol)
  - [2. MyErc20_V2 (erc20token.sol)](#2-myerc20_v2-erc20tokensol)
  - [3. myNFTMarket (nftmarket.sol)](#3-mynftmarket-nftmarketsol)
- [🔐 Keystore 管理](#-keystore-管理)
  - [创建多个 Keystore 文件](#创建多个-keystore-文件)
  - [Keystore 使用方式](#keystore-使用方式)
- [🧪 快速开始](#-快速开始)
- [📝 使用说明](#-使用说明)
- [🔗 相关链接](#-相关链接)
- [🎯 实际部署演示](#-实际部署演示)

## 📋 项目概述

本项目实现了一个完整的 NFT 交易平台，包含三个核心合约：
- **BaseERC721**: ERC721 NFT 合约
- **MyErc20_V2**: 扩展 ERC20 代币合约（支持回调功能）
- **myNFTMarket**: NFT 市场合约（支持两种购买方式）

## 🏗️ 合约结构与功能

### 1. BaseERC721 (nft.sol)

**功能**: 标准 ERC721 NFT 合约

**核心特性**:
- 完整的 ERC721 标准实现
- 支持元数据和 IPFS 集成
- 铸造、转移、授权等基础功能
- 可配置的 baseURI

**主要函数**:
```solidity
function mint(address to, uint256 tokenId) public onlyOwner
function tokenURI(uint256 tokenId) public view returns (string memory)
function setBaseURI(string memory newBaseURI) public onlyOwner
```

### 2. MyErc20_V2 (erc20token.sol)

**功能**: 扩展 ERC20 代币合约

**核心特性**:
- 标准 ERC20 功能
- 扩展的 `transferWithCallback` 方法
- 支持 `tokensReceived` 回调接口
- 自动回调机制

**主要函数**:
```solidity
function transferWithCallback(address to, uint256 amount, bytes calldata data) external
function mint(address to, uint256 amount) public onlyOwner
```

**接口定义**:
```solidity
interface ITokenReceiver {
    function tokenReceived(address from, address to, uint256 amount, bytes calldata data) external returns (bool);
}
```

### 3. myNFTMarket (nftmarket.sol)

**功能**: NFT 市场合约

**核心特性**:
- 支持任意 ERC721 NFT 和 ERC20 代币
- 两种购买方式：标准购买和扩展转账购买
- 自动退款机制
- 多重安全验证

**主要函数**:
```solidity
function listNFT(address nftAddress, uint256 nftId, uint256 price, address erc20Address) public
function buyNFT(address nftAddress, uint256 nftId, uint256 price, address erc20Address) public
function tokenReceived(address from, address to, uint256 amount, bytes calldata data) external returns (bool)
function getListedNft(address nftAddress, uint256 nftId) public view returns (listInfo memory)
```

**购买方式**:
1. **标准方式**: 先 `approve`，再调用 `buyNFT()`
2. **扩展方式**: 调用 `transferWithCallback()` 自动购买

## 🔐 Keystore 管理

### 创建多个 Keystore 文件

#### 方法 1: 使用 cast wallet import
```bash
# 创建新的 keystore 文件
cast wallet import --keystore-dir keystore/ account-name --private-key <PRIVATE_KEY>

# 示例：创建多个账户
cast wallet import --keystore-dir keystore/ deployer-wallet --private-key <DEPLOYER_PRIVATE_KEY>
cast wallet import --keystore-dir keystore/ user-wallet --private-key <USER_PRIVATE_KEY>
```

#### 方法 2: 复制现有 keystore
```bash
# 复制现有 keystore 文件
cp keystore/my-wallet keystore/account-2
cp keystore/my-wallet keystore/account-3
```

### Keystore 使用方式

#### 1. 环境变量设置
```bash
# 设置密码环境变量
export KEYSTORE_PASSWORD="your_keystore_password"

# 或者为不同账户设置不同密码
export KEYSTORE_PASSWORD_1="password_for_account_1"
export KEYSTORE_PASSWORD_2="password_for_account_2"
```

#### 2. 基本使用命令
```bash
# 查看 keystore 地址
cast wallet address --keystore keystore/my-wallet --password "$KEYSTORE_PASSWORD"

# 部署合约
forge script script/DeployERC20Token.sol \
  --rpc-url http://localhost:8545 \
  --keystore keystore/my-wallet \
  --password "$KEYSTORE_PASSWORD" \
  --broadcast

# 发送交易
cast send <CONTRACT_ADDRESS> "functionName()" \
  --rpc-url http://localhost:8545 \
  --keystore keystore/my-wallet \
  --password "$KEYSTORE_PASSWORD"

# 签名消息
cast wallet sign --keystore keystore/my-wallet --password "$KEYSTORE_PASSWORD" "message"
```

#### 3. 多个 Keystore 管理
```bash
# 使用不同的 keystore 文件
forge script script/DeployERC20Token.sol \
  --rpc-url http://localhost:8545 \
  --keystore keystore/deployer-wallet \
  --password "$KEYSTORE_PASSWORD_1" \
  --broadcast

# 使用第二个账户
forge script script/DeployERC20Token.sol \
  --rpc-url http://localhost:8545 \
  --keystore keystore/user-wallet \
  --password "$KEYSTORE_PASSWORD_2" \
  --broadcast
```

#### 4. 安全最佳实践
- 每个 keystore 文件使用不同的密码
- 使用环境变量管理密码，避免在命令历史中暴露
- 定期备份 keystore 文件
- 生产环境使用专业的密钥管理服务

## 🧪 快速开始

### 环境准备
```bash
# 1. 安装 Foundry
curl -L https://foundry.paradigm.xyz | bash && foundryup

# 2. 启动本地测试网络
anvil --port 8545

# 3. 设置环境变量
export KEYSTORE_PASSWORD="your_keystore_password"
```

### 基本测试
```bash
# 运行单元测试
forge test

# 部署合约
forge script script/DeployAllContracts.sol \
  --rpc-url http://localhost:8545 \
  --keystore keystore/my-wallet \
  --password "$KEYSTORE_PASSWORD" \
  --broadcast
```

## 📝 使用说明

### 1. 上架 NFT
```solidity
// 1. 授权市场合约
nft.approve(marketAddress, tokenId);

// 2. 上架 NFT
market.listNFT(nftAddress, tokenId, price, tokenAddress);
```

### 2. 标准购买
```solidity
// 1. 授权代币
token.approve(marketAddress, price);

// 2. 购买 NFT
market.buyNFT(nftAddress, tokenId, price, tokenAddress);
```

### 3. 扩展购买
```solidity
// 1. 编码购买数据
bytes memory data = abi.encode(nftAddress, tokenId, price);

// 2. 扩展转账购买
token.transferWithCallback(marketAddress, price, data);
```

## 🔗 相关链接

- **Foundry 文档**: [https://book.getfoundry.sh/](https://book.getfoundry.sh/)
- **OpenZeppelin 合约**: [https://docs.openzeppelin.com/contracts/](https://docs.openzeppelin.com/contracts/)

## 🎯 实际部署演示

### 完整的 Keystore 创建到部署流程

#### 1. 创建 Keystore 文件
```bash
# 使用 cast wallet import 创建新的 keystore
cast wallet import --keystore-dir keystore/ test-wallet --private-key <PRIVATE_KEY>

# 输出结果
# Enter password: [输入密码]
# `test-wallet` keystore was saved successfully. Address: 0x[YOUR_WALLET_ADDRESS]
```

#### 2. 设置环境变量
```bash
# 设置 keystore 密码环境变量
export KEYSTORE_PASSWORD="your_keystore_password"
```

#### 3. 验证 Keystore 地址
```bash
# 查看 keystore 对应的地址
cast wallet address --keystore keystore/test-wallet --password "$KEYSTORE_PASSWORD"

# 输出结果
# 0x[YOUR_WALLET_ADDRESS]
```

#### 4. 启动本地测试网络
```bash
# 启动 anvil 本地测试网络
anvil --port 8545
```

#### 5. 使用 Keystore 部署合约
```bash
# 使用 keystore 部署 ERC20 合约
forge script script/DeployERC20Token.sol \
  --rpc-url http://localhost:8545 \
  --keystore keystore/test-wallet \
  --password "$KEYSTORE_PASSWORD" \
  --broadcast
```

#### 6. 部署结果
```
Script ran successfully.

== Logs ==
  === Deploying ERC20 Token Contract ===
  Deployer address: 0x[DEPLOYER_ADDRESS]
  
2. Deploying MyErc20_V2 contract...
  MyErc20_V2 contract address: 0x[CONTRACT_ADDRESS]
  Token name: MyERC20TokenV2
  Token symbol: METK_V2
  Total supply: 10000000000000000000000000
  Deployer balance: 0
  
=== Deployment Completed ===
  MYERC20_V2_CONTRACT_ADDRESS= 0x[CONTRACT_ADDRESS]
  DEPLOYER_ADDRESS= 0x[DEPLOYER_ADDRESS]
  =============================

## Setting up 1 EVM.

==========================

Chain 31337

Estimated gas price: 2.000000001 gwei
Estimated total gas used for script: 1820650
Estimated amount required: 0.00364130000182065 ETH

==========================

##### anvil-hardhat
✅  [Success] Hash: 0x[TRANSACTION_HASH]
Contract Address: 0x[CONTRACT_ADDRESS]
Block: 1
Paid: 0.0014005000014005 ETH (1400500 gas * 1.000000001 gwei)

✅ Sequence #1 on anvil-hardhat | Total Paid: 0.0014005000014005 ETH (1400500 gas * avg 1.000000001 gwei)

==========================

ONCHAIN EXECUTION COMPLETE & SUCCESSFUL.

Transactions saved to: /Users/bobo/s8-projects/3.4/broadcast/DeployERC20Token.sol/31337/run-latest.json
Sensitive values saved to: /Users/bobo/s8-projects/3.4/cache/DeployERC20Token.sol/31337/run-latest.json
```

### 关键要点总结

1. **Keystore 创建成功**: 使用 `cast wallet import` 成功创建了 `test-wallet` keystore 文件
2. **地址验证正确**: keystore 对应的地址是 `0x[YOUR_WALLET_ADDRESS]`
3. **环境变量设置**: 通过 `export KEYSTORE_PASSWORD` 设置密码环境变量
4. **部署成功**: 合约成功部署到地址 `0x[CONTRACT_ADDRESS]`
5. **Gas 消耗**: 部署消耗了 1,400,500 gas，费用为 0.0014005000014005 ETH
6. **交易记录**: 交易哈希为 `0x[TRANSACTION_HASH]`

### 最佳实践验证

- ✅ **安全性**: 使用 keystore 而不是明文私钥
- ✅ **环境变量**: 密码通过环境变量管理，不在命令历史中暴露
- ✅ **本地测试**: 在 anvil 本地测试网络成功部署
- ✅ **交易记录**: 完整的交易记录和合约地址保存

## 📄 许可证

MIT License

---

**项目状态**: ✅ 开发完成，测试通过，功能验证成功，Keystore 部署流程验证完成