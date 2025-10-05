# NFT Market Event Listener

基于 Viem.sh 的 NFT 市场事件监听服务，支持监听链上的上架（list）和买卖（buy）事件。

## 功能特性

- 🎧 **实时事件监听**：使用 Viem.sh 监听链上事件
- 🌐 **多网络支持**：支持本地测试网（anvil）和 Sepolia 测试网
- 📋 **事件解析**：自动解析 ListNFT 和 BuyNFT 事件
- 📝 **详细日志**：打印事件详细信息
- 🔄 **自动重连**：网络异常时自动重连
- 🛡️ **错误处理**：完善的错误处理机制

## 快速开始

### 1. 安装依赖

```bash
cd backend
npm install
```

### 2. 配置环境变量

复制环境变量示例文件：
```bash
cp .env.example .env
```

编辑 `.env` 文件，设置必要的配置：
```bash
# 网络配置
NETWORK=local  # 或 sepolia

# Infura API Key (用于 Sepolia)
INFURA_API_KEY=your_infura_api_key

# 合约地址 (部署后更新)
MARKET_CONTRACT_ADDRESS=0x...
NFT_CONTRACT_ADDRESS=0x...
TOKEN_CONTRACT_ADDRESS=0x...
```

### 3. 启动服务

**本地测试网 (anvil)**：
```bash
# 1. 启动 anvil 本地测试网
anvil --port 8545

# 2. 部署合约 (在另一个终端)
cd ../
forge script script/DeployAllContracts.sol --rpc-url http://localhost:8545 --broadcast

# 3. 更新 .env 文件中的合约地址

# 4. 启动事件监听
cd backend
npm start
```

**Sepolia 测试网**：
```bash
# 1. 部署合约到 Sepolia
cd ../
forge script script/DeployAllContracts.sol --rpc-url https://sepolia.infura.io/v3/YOUR_KEY --broadcast

# 2. 更新 .env 文件中的网络和合约地址
NETWORK=sepolia
MARKET_CONTRACT_ADDRESS=0x...

# 3. 启动事件监听
cd backend
npm start
```

## 网络配置

### 本地测试网 (Anvil)
- **RPC URL**: `http://localhost:8545`
- **Chain ID**: `31337`
- **用途**: 本地开发和测试

### Sepolia 测试网
- **RPC URL**: `https://sepolia.infura.io/v3/YOUR_KEY`
- **Chain ID**: `11155111`
- **用途**: 测试网部署和测试

## 事件监听

### ListNFT 事件
当 NFT 被上架时触发：
```
[2024-01-20T10:30:15.123Z] [LOCAL] LIST NFT EVENT DETECTED
============================================================
📋 Event Details:
  Network: Anvil Local (Chain ID: 31337)
  NFT Contract: 0x1234...
  NFT ID: 1
  Price: 100000000000000000000 wei
  ERC20 Token: 0x5678...
  Block Number: 12345
  Transaction Hash: 0xabcd...
  Log Index: 0
✅ SUCCESS: An NFT has been listed for sale!
============================================================
```

### BuyNFT 事件
当 NFT 被购买时触发：
```
[2024-01-20T10:31:20.456Z] [LOCAL] BUY NFT EVENT DETECTED
============================================================
🛒 Event Details:
  Network: Anvil Local (Chain ID: 31337)
  NFT Contract: 0x1234...
  NFT ID: 1
  Price Paid: 100000000000000000000 wei
  ERC20 Token: 0x5678...
  Block Number: 12346
  Transaction Hash: 0xefgh...
  Log Index: 0
🎉 SUCCESS: An NFT has been purchased!
============================================================
```

## 命令行选项

### 环境变量

| 变量名 | 描述 | 默认值 | 必需 |
|--------|------|--------|------|
| `NETWORK` | 网络类型 | `local` | 否 |
| `INFURA_API_KEY` | Infura API Key | - | Sepolia 必需 |
| `MARKET_CONTRACT_ADDRESS` | 市场合约地址 | - | 是 |
| `NFT_CONTRACT_ADDRESS` | NFT 合约地址 | - | 否 |
| `TOKEN_CONTRACT_ADDRESS` | 代币合约地址 | - | 否 |

### 启动命令

```bash
# 使用默认配置启动
npm start

# 指定网络启动
NETWORK=sepolia npm start

# 开发模式（自动重启）
npm run dev
```

## 故障排除

### 常见问题

1. **连接失败**
   ```
   ❌ Failed to connect to Anvil Local
   ```
   - 检查 anvil 是否正在运行
   - 确认 RPC URL 是否正确

2. **合约地址未配置**
   ```
   ❌ Market contract address not configured
   ```
   - 检查 `.env` 文件中的 `MARKET_CONTRACT_ADDRESS`
   - 确保已部署合约并获取正确地址

3. **网络不匹配**
   ```
   ⚠️ Chain ID mismatch. Expected: 31337, Got: 11155111
   ```
   - 检查 `NETWORK` 环境变量设置
   - 确认 RPC URL 指向正确的网络

### 调试模式

设置详细日志：
```bash
LOG_LEVEL=debug npm start
```

## 开发

### 项目结构
```
backend/
├── package.json          # 依赖配置
├── config.js             # 网络和合约配置
├── eventListener.js      # 事件监听逻辑
├── index.js              # 主服务文件
├── .env.example          # 环境变量示例
└── README.md             # 使用说明
```

### 添加新事件

1. 在 `eventListener.js` 中添加事件签名
2. 实现事件处理函数
3. 在 `processLog` 方法中添加事件分发逻辑

