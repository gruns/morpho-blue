// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

import "src/libraries/ErrorsLib.sol";
import {IERC20, SafeTransferLib} from "src/libraries/SafeTransferLib.sol";

/// @dev Token not returning any boolean on transfer and transferFrom.
contract ERC20Fake1 {
    mapping(address => uint256) public balanceOf;

    function transfer(address to, uint256 amount) public {
        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;
    }

    function transferFrom(address from, address to, uint256 amount) public {
        // Skip allowance check.
        balanceOf[from] -= amount;
        balanceOf[to] += amount;
    }

    function setBalance(address account, uint256 amount) public {
        balanceOf[account] = amount;
    }
}

/// @dev Token returning false on transfer and transferFrom.
contract ERC20Fake2 {
    mapping(address => uint256) public balanceOf;

    function transfer(address to, uint256 amount) public returns (bool failure) {
        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;
        failure = false; // To silence warning.
    }

    function transferFrom(address from, address to, uint256 amount) public returns (bool failure) {
        // Skip allowance check.
        balanceOf[from] -= amount;
        balanceOf[to] += amount;
        failure = false; // To silence warning.
    }

    function setBalance(address account, uint256 amount) public {
        balanceOf[account] = amount;
    }
}

contract SafeTransferLibTest is Test {
    using SafeTransferLib for *;

    ERC20Fake1 public token1;
    ERC20Fake2 public token2;

    function setUp() public {
        token1 = new ERC20Fake1();
        token2 = new ERC20Fake2();
    }

    function testSafeTransferShouldRevertOnTokenWithEmptyCode(address noCode) public {
        vm.assume(noCode.code.length == 0);

        vm.expectRevert(bytes(ErrorsLib.TRANSFER_FAILED));
        this.safeTransfer(noCode, address(0), 0);
    }

    function testSafeTransfer(address to, uint256 amount) public {
        token1.setBalance(address(this), amount);

        this.safeTransfer(address(token1), to, amount);
    }

    function testSafeTransferFrom(address from, address to, uint256 amount) public {
        token1.setBalance(from, amount);

        this.safeTransferFrom(address(token1), from, to, amount);
    }

    function testSafeTransferWithBoolFalse(address to, uint256 amount) public {
        token2.setBalance(address(this), amount);

        vm.expectRevert(bytes(ErrorsLib.TRANSFER_FAILED));
        this.safeTransfer(address(token2), to, amount);
    }

    function testSafeTransferFromWithBoolFalse(address from, address to, uint256 amount) public {
        token2.setBalance(from, amount);

        vm.expectRevert(bytes(ErrorsLib.TRANSFER_FROM_FAILED));
        this.safeTransferFrom(address(token2), from, to, amount);
    }

    function safeTransfer(address token, address to, uint256 amount) external {
        IERC20(token).safeTransfer(to, amount);
    }

    function safeTransferFrom(address token, address from, address to, uint256 amount) external {
        IERC20(token).safeTransferFrom(from, to, amount);
    }
}
