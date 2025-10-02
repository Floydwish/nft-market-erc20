// 网络配置
const networks = {
  // 本地测试网 (anvil)
  local: {
    rpcUrl: 'http://localhost:8545',
    chainId: 31337,
    name: 'Anvil Local'
  },
  // Sepolia 测试网
  sepolia: {
    rpcUrl: 'https://sepolia.infura.io/v3/YOUR_INFURA_KEY', // 需要替换为实际的 Infura Key
    chainId: 11155111,
    name: 'Sepolia Testnet'
  }
};

// 合约配置
const contracts = {
  marketAddress: process.env.MARKET_CONTRACT_ADDRESS,
  nftAddress: process.env.NFT_CONTRACT_ADDRESS,
  tokenAddress: process.env.TOKEN_CONTRACT_ADDRESS
};

// 获取当前网络配置
const getNetworkConfig = () => {
  const network = process.env.NETWORK || 'local';
  
  if (!networks[network]) {
    console.warn(`Unknown network: ${network}, falling back to local`);
    return networks.local;
  }
  
  return {
    ...networks[network],
    contracts: contracts
  };
};

// 事件签名配置
const eventSignatures = {
  ListNFT: '0x...', // 将在运行时计算
  BuyNFT: '0x...'   // 将在运行时计算
};

module.exports = {
  networks,
  contracts,
  getNetworkConfig,
  eventSignatures
};
