// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// 导入 ERC20 实现
import "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

// 导入权限管理
import "openzeppelin-contracts/contracts/access/Ownable.sol";

contract MyErc20 is ERC20, Ownable{

    constructor() ERC20("MyERC20Token", "METK") Ownable(msg.sender) {
        _mint(msg.sender, 10000000 * 10 ** 18);
    }

    function mint(address to, uint256 amount) public onlyOwner{
        _mint(to, amount);
    }

}

// 定义接口：回调方实现
interface ITokenReceiver {
    function tokenReceived(address from, address to, uint256 amount, bytes calldata data) external returns (bool);
}

contract MyErc20_V2 is ERC20, Ownable{

        constructor() ERC20("MyERC20TokenV2", "METK_V2") Ownable(msg.sender) {
        _mint(msg.sender, 10000000 * 10 ** 18);
    }

    function mint(address to, uint256 amount) public onlyOwner{
        _mint(to, amount);
    }

    function transferWithCallback(address to, uint256 amount, bytes calldata data) external {
        // 1.先标准转账
        bool success = transfer(to, amount);     
        require(success, "Transfer failed");

        // 2.根据接收地址类型做处理 (如果是合约地址，就调用)
        // 注：最新的 openzeppelin：Address.sol中 已不支持 isContract 判断地址是否为合约
        if(to.code.length > 0) { 
            try ITokenReceiver(to).tokenReceived(msg.sender, 
            to, amount, 
            data) returns (bool callSuccess)// 传递实际的 data 参数
            {
                // 检查回调函数是否执行成功
                require(callSuccess, "Callback failed");
            }
            catch{
                revert("Callback revert");
            }
        }        
    }
}