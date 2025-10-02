#!/usr/bin/env node

require('dotenv').config();
const NFTMarketEventListener = require('./eventListener');

// 退出处理
let eventListener = null;

const gracefulShutdown = async (signal) => {
  console.log(`\n🛑 Received ${signal}. Shutting down gracefully...`);
  
  if (eventListener) {
    await eventListener.stopListening();
  }
  
  console.log('✅ Shutdown complete');
  process.exit(0);
};

// 注册信号处理器
process.on('SIGINT', () => gracefulShutdown('SIGINT'));
process.on('SIGTERM', () => gracefulShutdown('SIGTERM'));

// 未捕获异常处理
process.on('uncaughtException', (error) => {
  console.error('❌ Uncaught Exception:', error);
  gracefulShutdown('UNCAUGHT_EXCEPTION');
});

process.on('unhandledRejection', (reason, promise) => {
  console.error('❌ Unhandled Rejection at:', promise, 'reason:', reason);
  gracefulShutdown('UNHANDLED_REJECTION');
});

// 主函数
async function main() {
  console.log('🚀 NFT Market Event Listener Starting...');
  console.log('='.repeat(50));
  
  try {
    // 显示配置信息
    const network = process.env.NETWORK || 'local';
    console.log(`📡 Network: ${network}`);
    console.log(`🔗 RPC URL: ${network === 'local' ? 'http://localhost:8545' : 'Sepolia Testnet'}`);
    
    if (process.env.MARKET_CONTRACT_ADDRESS) {
      console.log(`📋 Market Contract: ${process.env.MARKET_CONTRACT_ADDRESS}`);
    } else {
      console.log('⚠️  MARKET_CONTRACT_ADDRESS not set');
    }
    
    if (process.env.NFT_CONTRACT_ADDRESS) {
      console.log(`🖼️  NFT Contract: ${process.env.NFT_CONTRACT_ADDRESS}`);
    }
    
    if (process.env.TOKEN_CONTRACT_ADDRESS) {
      console.log(`🪙 Token Contract: ${process.env.TOKEN_CONTRACT_ADDRESS}`);
    }
    
    console.log('='.repeat(50));
    
    // 创建事件监听器
    eventListener = new NFTMarketEventListener();
    
    // 初始化连接
    const connected = await eventListener.initialize();
    if (!connected) {
      console.error('❌ Failed to initialize event listener');
      process.exit(1);
    }
    
    // 开始监听事件
    await eventListener.startListening();
    
    // 显示状态
    const status = eventListener.getStatus();
    console.log('\n📊 Event Listener Status:');
    console.log(`  Listening: ${status.isListening ? '✅ Yes' : '❌ No'}`);
    console.log(`  Network: ${status.network}`);
    console.log(`  Chain ID: ${status.chainId}`);
    console.log(`  Market Contract: ${status.marketAddress || 'Not configured'}`);
    
    console.log('\n🎧 Event listener is now running...');
    console.log('Press Ctrl+C to stop');
    console.log('='.repeat(50));
    
    // 定期显示状态（每5分钟）
    setInterval(() => {
      const now = new Date().toISOString();
      console.log(`[${now}] 💓 Event listener is still running...`);
    }, 5 * 60 * 1000); // 5分钟
    
  } catch (error) {
    console.error('❌ Fatal error:', error.message);
    console.error(error.stack);
    process.exit(1);
  }
}

// 启动应用
if (require.main === module) {
  main().catch((error) => {
    console.error('❌ Startup failed:', error.message);
    process.exit(1);
  });
}

module.exports = { NFTMarketEventListener };
