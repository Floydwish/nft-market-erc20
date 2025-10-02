#!/bin/bash

# NFT Market Event Listener 启动脚本

echo "🚀 Starting NFT Market Event Listener..."

# 检查是否安装了 Node.js
if ! command -v node &> /dev/null; then
    echo "❌ Node.js is not installed. Please install Node.js 18+ first."
    exit 1
fi

# 检查是否安装了 npm
if ! command -v npm &> /dev/null; then
    echo "❌ npm is not installed. Please install npm first."
    exit 1
fi

# 检查是否安装了依赖
if [ ! -d "node_modules" ]; then
    echo "📦 Installing dependencies..."
    npm install
fi

# 设置默认环境变量
export NETWORK=${NETWORK:-local}

echo "📡 Network: $NETWORK"

# 启动服务
echo "🎧 Starting event listener..."
node index.js
