const { createPublicClient, createWalletClient, http, parseAbi } = require('viem');
const { keccak256, toHex } = require('viem');
const { getNetworkConfig } = require('./config');

class NFTMarketEventListener {
  constructor() {
    this.networkConfig = getNetworkConfig();
    this.client = null;
    this.isListening = false;
    this.watchBlocks = null;
    
    // 事件签名
    this.eventSignatures = {
      ListNFT: keccak256(toHex('ListNFT(address,uint256,uint256,address)')),
      BuyNFT: keccak256(toHex('BuyNFT(address,uint256,uint256,address)'))
    };
    
    // 合约 ABI
    this.contractAbi = parseAbi([
      'event ListNFT(address indexed nftAddress, uint256 indexed nftId, uint256 price, address erc20Address)',
      'event BuyNFT(address indexed nftAddress, uint256 indexed nftId, uint256 price, address erc20Address)'
    ]);
  }

  // 初始化客户端
  async initialize() {
    try {
      this.client = createPublicClient({
        transport: http(this.networkConfig.rpcUrl)
      });
      
      // 测试连接
      const chainId = await this.client.getChainId();
      console.log(`✅ Connected to ${this.networkConfig.name} (Chain ID: ${chainId})`);
      
      if (chainId !== this.networkConfig.chainId) {
        console.warn(`⚠️  Chain ID mismatch. Expected: ${this.networkConfig.chainId}, Got: ${chainId}`);
      }
      
      return true;
    } catch (error) {
      console.error(`❌ Failed to connect to ${this.networkConfig.name}:`, error.message);
      return false;
    }
  }

  // 开始监听事件
  async startListening() {
    if (this.isListening) {
      console.log('⚠️  Already listening for events');
      return;
    }

    if (!this.networkConfig.contracts.marketAddress) {
      console.error('❌ Market contract address not configured');
      console.log('Please set MARKET_CONTRACT_ADDRESS environment variable');
      return;
    }

    try {
      console.log(`🎧 Starting to listen for events on ${this.networkConfig.name}...`);
      console.log(`📋 Market Contract: ${this.networkConfig.contracts.marketAddress}`);
      
      // 开始监听新区块
      this.watchBlocks = this.client.watchBlocks({
        onBlock: (block) => this.processBlock(block),
        onError: (error) => {
          console.error('❌ Block watching error:', error);
        }
      });
      
      this.isListening = true;
      console.log('✅ Event listener started successfully');
      
    } catch (error) {
      console.error('❌ Failed to start event listener:', error.message);
    }
  }

  // 停止监听
  async stopListening() {
    if (this.watchBlocks) {
      this.watchBlocks();
      this.watchBlocks = null;
    }
    this.isListening = false;
    console.log('🛑 Event listener stopped');
  }

  // 处理新区块
  async processBlock(block) {
    try {
      // 获取区块中的日志
      const logs = await this.client.getLogs({
        address: this.networkConfig.contracts.marketAddress,
        fromBlock: block.number,
        toBlock: block.number
      });

      // 处理每个日志
      for (const log of logs) {
        await this.processLog(log);
      }
    } catch (error) {
      console.error('❌ Error processing block:', error.message);
    }
  }

  // 处理单个日志
  async processLog(log) {
    try {
      const eventSignature = log.topics[0];
      
      if (eventSignature === this.eventSignatures.ListNFT) {
        await this.handleListNFTEvent(log);
      } else if (eventSignature === this.eventSignatures.BuyNFT) {
        await this.handleBuyNFTEvent(log);
      }
    } catch (error) {
      console.error('❌ Error processing log:', error.message);
    }
  }

  // 处理 ListNFT 事件
  async handleListNFTEvent(log) {
    try {
      // 解析事件数据
      const nftAddress = log.topics[1];
      const nftId = BigInt(log.topics[2]);
      
      // 解析 data 字段中的 price 和 erc20Address
      const data = log.data.slice(2); // 移除 0x 前缀
      const price = BigInt('0x' + data.slice(0, 64));
      const erc20Address = '0x' + data.slice(64, 104);
      
      // 格式化输出
      const timestamp = new Date().toISOString();
      const networkName = this.networkConfig.name.toUpperCase();
      
      console.log('\n' + '='.repeat(60));
      console.log(`[${timestamp}] [${networkName}] LIST NFT EVENT DETECTED`);
      console.log('='.repeat(60));
      console.log(`📋 Event Details:`);
      console.log(`  Network: ${this.networkConfig.name} (Chain ID: ${this.networkConfig.chainId})`);
      console.log(`  NFT Contract: ${nftAddress}`);
      console.log(`  NFT ID: ${nftId.toString()}`);
      console.log(`  Price: ${price.toString()} wei`);
      console.log(`  ERC20 Token: ${erc20Address}`);
      console.log(`  Block Number: ${log.blockNumber.toString()}`);
      console.log(`  Transaction Hash: ${log.transactionHash}`);
      console.log(`  Log Index: ${log.logIndex.toString()}`);
      console.log('✅ SUCCESS: An NFT has been listed for sale!');
      console.log('='.repeat(60) + '\n');
      
    } catch (error) {
      console.error('❌ Error parsing ListNFT event:', error.message);
    }
  }

  // 处理 BuyNFT 事件
  async handleBuyNFTEvent(log) {
    try {
      // 解析事件数据
      const nftAddress = log.topics[1];
      const nftId = BigInt(log.topics[2]);
      
      // 解析 data 字段中的 price 和 erc20Address
      const data = log.data.slice(2); // 移除 0x 前缀
      const price = BigInt('0x' + data.slice(0, 64));
      const erc20Address = '0x' + data.slice(64, 104);
      
      // 格式化输出
      const timestamp = new Date().toISOString();
      const networkName = this.networkConfig.name.toUpperCase();
      
      console.log('\n' + '='.repeat(60));
      console.log(`[${timestamp}] [${networkName}] BUY NFT EVENT DETECTED`);
      console.log('='.repeat(60));
      console.log(`🛒 Event Details:`);
      console.log(`  Network: ${this.networkConfig.name} (Chain ID: ${this.networkConfig.chainId})`);
      console.log(`  NFT Contract: ${nftAddress}`);
      console.log(`  NFT ID: ${nftId.toString()}`);
      console.log(`  Price Paid: ${price.toString()} wei`);
      console.log(`  ERC20 Token: ${erc20Address}`);
      console.log(`  Block Number: ${log.blockNumber.toString()}`);
      console.log(`  Transaction Hash: ${log.transactionHash}`);
      console.log(`  Log Index: ${log.logIndex.toString()}`);
      console.log('🎉 SUCCESS: An NFT has been purchased!');
      console.log('='.repeat(60) + '\n');
      
    } catch (error) {
      console.error('❌ Error parsing BuyNFT event:', error.message);
    }
  }

  // 获取当前状态
  getStatus() {
    return {
      isListening: this.isListening,
      network: this.networkConfig.name,
      chainId: this.networkConfig.chainId,
      marketAddress: this.networkConfig.contracts.marketAddress
    };
  }
}

module.exports = NFTMarketEventListener;
