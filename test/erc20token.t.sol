// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../src/ERC20Token.sol";

// 测试用的接收者合约
contract TestTokenReceiver is ITokenReceiver {
    bool public shouldRevert = false;
    bool public shouldReturnFalse = false;
    
    event TokenReceived(address from, address to, uint256 amount, bytes data);
    
    function tokenReceived(address from, address to, uint256 amount, bytes calldata data) external override returns (bool) {
        emit TokenReceived(from, to, amount, data);
        
        if (shouldRevert) {
            revert("Test revert");
        }
        
        if (shouldReturnFalse) {
            return false;
        }
        
        return true;
    }
    
    function setShouldRevert(bool _shouldRevert) external {
        shouldRevert = _shouldRevert;
    }
    
    function setShouldReturnFalse(bool _shouldReturnFalse) external {
        shouldReturnFalse = _shouldReturnFalse;
    }
}

contract ERC20TokenTest is Test {
    MyErc20 public token;
    MyErc20_V2 public tokenV2;
    TestTokenReceiver public receiver;
    
    address public owner;
    address public user1;
    address public user2;
    address public user3;
    
    uint256 constant INITIAL_SUPPLY = 10000000 * 10 ** 18;
    
    function setUp() public {
        owner = address(this);
        user1 = makeAddr("user1");
        user2 = makeAddr("user2");
        user3 = makeAddr("user3");
        
        // 部署合约
        token = new MyErc20();
        tokenV2 = new MyErc20_V2();
        receiver = new TestTokenReceiver();
        
        console.log("Setup completed");
        console.log("Token name:", token.name());
        console.log("Token symbol:", token.symbol());
        console.log("Token V2 name:", tokenV2.name());
        console.log("Token V2 symbol:", tokenV2.symbol());
    }
    
    // 测试1：基本信息和初始供应量
    function testBasicInfo() public {
        assertEq(token.name(), "MyERC20Token");
        assertEq(token.symbol(), "METK");
        assertEq(token.decimals(), 18);
        assertEq(token.totalSupply(), INITIAL_SUPPLY);
        assertEq(token.balanceOf(owner), INITIAL_SUPPLY);
        
        assertEq(tokenV2.name(), "MyERC20TokenV2");
        assertEq(tokenV2.symbol(), "METK_V2");
        assertEq(tokenV2.decimals(), 18);
        assertEq(tokenV2.totalSupply(), INITIAL_SUPPLY);
        assertEq(tokenV2.balanceOf(owner), INITIAL_SUPPLY);
        
        console.log("Basic info test passed");
    }
    
    // 测试2：所有者权限
    function testOwnership() public {
        assertEq(token.owner(), owner);
        assertEq(tokenV2.owner(), owner);
        console.log("Ownership test passed");
    }
    
    // 测试3：铸造功能
    function testMint() public {
        uint256 mintAmount = 1000 * 10 ** 18;
        
        // 铸造前检查
        assertEq(token.balanceOf(user1), 0);
        
        // 铸造
        token.mint(user1, mintAmount);
        
        // 铸造后检查
        assertEq(token.balanceOf(user1), mintAmount);
        assertEq(token.totalSupply(), INITIAL_SUPPLY + mintAmount);
        
        console.log("Mint test passed");
    }
    
    // 测试4：非所有者铸造（应该失败）
    function testMintByNonOwner() public {
        uint256 mintAmount = 1000 * 10 ** 18;
        
        vm.prank(user1);
        vm.expectRevert();
        token.mint(user2, mintAmount);
        
        console.log("Mint by non-owner test passed");
    }
    
    // 测试5：转账功能
    function testTransfer() public {
        uint256 transferAmount = 1000 * 10 ** 18;
        
        // 转账前检查
        assertEq(token.balanceOf(owner), INITIAL_SUPPLY);
        assertEq(token.balanceOf(user1), 0);
        
        // 执行转账
        bool success = token.transfer(user1, transferAmount);
        assertTrue(success);
        
        // 转账后检查
        assertEq(token.balanceOf(owner), INITIAL_SUPPLY - transferAmount);
        assertEq(token.balanceOf(user1), transferAmount);
        
        console.log("Transfer test passed");
    }
    
    // 测试6：转账到零地址（应该失败）
    function testTransferToZeroAddress() public {
        uint256 transferAmount = 1000 * 10 ** 18;
        
        vm.expectRevert();
        token.transfer(address(0), transferAmount);
        
        console.log("Transfer to zero address test passed");
    }
    
    // 测试7：余额不足转账（应该失败）
    function testTransferInsufficientBalance() public {
        uint256 transferAmount = INITIAL_SUPPLY + 1;
        
        vm.expectRevert();
        token.transfer(user1, transferAmount);
        
        console.log("Transfer insufficient balance test passed");
    }
    
    // 测试8：授权功能
    function testApprove() public {
        uint256 approveAmount = 1000 * 10 ** 18;
        
        // 授权前检查
        assertEq(token.allowance(owner, user1), 0);
        
        // 执行授权
        bool success = token.approve(user1, approveAmount);
        assertTrue(success);
        
        // 授权后检查
        assertEq(token.allowance(owner, user1), approveAmount);
        
        console.log("Approve test passed");
    }
    
    // 测试9：transferFrom 功能
    function testTransferFrom() public {
        uint256 approveAmount = 1000 * 10 ** 18;
        uint256 transferAmount = 500 * 10 ** 18;
        
        // 授权
        token.approve(user1, approveAmount);
        
        // 转账前检查
        assertEq(token.balanceOf(owner), INITIAL_SUPPLY);
        assertEq(token.balanceOf(user2), 0);
        assertEq(token.allowance(owner, user1), approveAmount);
        
        // 执行 transferFrom
        vm.prank(user1);
        bool success = token.transferFrom(owner, user2, transferAmount);
        assertTrue(success);
        
        // 转账后检查
        assertEq(token.balanceOf(owner), INITIAL_SUPPLY - transferAmount);
        assertEq(token.balanceOf(user2), transferAmount);
        assertEq(token.allowance(owner, user1), approveAmount - transferAmount);
        
        console.log("TransferFrom test passed");
    }
    
    // 测试10：transferWithCallback 到 EOA（应该成功）
    function testTransferWithCallbackToEOA() public {
        uint256 transferAmount = 1000 * 10 ** 18;
        
        // 转账前检查
        assertEq(tokenV2.balanceOf(owner), INITIAL_SUPPLY);
        assertEq(tokenV2.balanceOf(user1), 0);
        
        // 执行 transferWithCallback
        tokenV2.transferWithCallback(user1, transferAmount, "");
        
        // 转账后检查
        assertEq(tokenV2.balanceOf(owner), INITIAL_SUPPLY - transferAmount);
        assertEq(tokenV2.balanceOf(user1), transferAmount);
        
        console.log("TransferWithCallback to EOA test passed");
    }
    
    // 测试11：transferWithCallback 到合约（应该成功）
    function testTransferWithCallbackToContract() public {
        uint256 transferAmount = 1000 * 10 ** 18;
        
        // 转账前检查
        assertEq(tokenV2.balanceOf(owner), INITIAL_SUPPLY);
        assertEq(tokenV2.balanceOf(address(receiver)), 0);
        
        // 执行 transferWithCallback
        tokenV2.transferWithCallback(address(receiver), transferAmount, "test data");
        
        // 转账后检查
        assertEq(tokenV2.balanceOf(owner), INITIAL_SUPPLY - transferAmount);
        assertEq(tokenV2.balanceOf(address(receiver)), transferAmount);
        
        console.log("TransferWithCallback to contract test passed");
    }
    
    // 测试12：transferWithCallback 回调失败（应该失败）
    function testTransferWithCallbackCallbackFails() public {
        uint256 transferAmount = 1000 * 10 ** 18;
        
        // 设置接收者合约返回 false
        receiver.setShouldReturnFalse(true);
        
        vm.expectRevert("Callback failed");
        tokenV2.transferWithCallback(address(receiver), transferAmount, "");
        
        console.log("TransferWithCallback callback fails test passed");
    }
    
    // 测试13：transferWithCallback 回调异常（应该失败）
    function testTransferWithCallbackCallbackReverts() public {
        uint256 transferAmount = 1000 * 10 ** 18;
        
        // 设置接收者合约抛出异常
        receiver.setShouldRevert(true);
        
        vm.expectRevert("Callback revert");
        tokenV2.transferWithCallback(address(receiver), transferAmount, "");
        
        console.log("TransferWithCallback callback reverts test passed");
    }
    
    // 测试14：transferWithCallback 余额不足（应该失败）
    function testTransferWithCallbackInsufficientBalance() public {
        uint256 transferAmount = INITIAL_SUPPLY + 1;
        
        vm.expectRevert();
        tokenV2.transferWithCallback(user1, transferAmount, "");
        
        console.log("TransferWithCallback insufficient balance test passed");
    }
    
    // 测试15：事件测试
    function testEvents() public {
        uint256 transferAmount = 1000 * 10 ** 18;
        
        // 测试 Transfer 事件
        vm.expectEmit(true, true, true, true);
        emit IERC20.Transfer(owner, user1, transferAmount);
        token.transfer(user1, transferAmount);
        
        // 测试 Approval 事件
        vm.expectEmit(true, true, true, true);
        emit IERC20.Approval(owner, user1, transferAmount);
        token.approve(user1, transferAmount);
        
        console.log("Events test passed");
    }
    
    // 测试16：批量操作测试
    function testBatchOperations() public {
        uint256 amount = 100 * 10 ** 18;
        
        // 批量转账
        for (uint256 i = 0; i < 5; i++) {
            address user = makeAddr(string(abi.encodePacked("user", i)));
            token.transfer(user, amount);
            assertEq(token.balanceOf(user), amount);
        }
        
        // 检查所有者余额
        assertEq(token.balanceOf(owner), INITIAL_SUPPLY - (5 * amount));
        
        console.log("Batch operations test passed");
    }
    
    // 测试17：边界值测试
    function testBoundaryValues() public {
        // 测试最大授权值
        uint256 maxApproval = type(uint256).max;
        token.approve(user1, maxApproval);
        assertEq(token.allowance(owner, user1), maxApproval);
        
        // 测试零转账
        token.transfer(user1, 0);
        assertEq(token.balanceOf(user1), 0);
        
        console.log("Boundary values test passed");
    }
    
    // 测试18：V2 合约特有功能
    function testV2SpecificFeatures() public {
        uint256 transferAmount = 1000 * 10 ** 18;
        bytes memory testData = "test callback data";
        
        // 测试带数据的回调
        vm.expectEmit(true, true, true, true);
        emit TestTokenReceiver.TokenReceived(owner, address(receiver), transferAmount, testData);
        tokenV2.transferWithCallback(address(receiver), transferAmount, testData);
        
        console.log("V2 specific features test passed");
    }
}
