// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;

import "forge-std/Test.sol";
import "../contracts/KipuBank.sol";

contract KipuBankTest is Test {
    KipuBank public kipuBank;
    address public user = address(0x1);
    uint256 public initialBalance = 15 ether;
    uint256 public constant BANK_CAP = 10 ether;
    uint256 public constant WITHDRAW_LIMIT = 1 ether;

    function setUp() public {
        kipuBank = new KipuBank(user, BANK_CAP);
        vm.deal(user, initialBalance);
    }

    function testDeposit() public {
        uint256 _deposit = 2 ether;

        vm.startPrank(user);

        vm.expectEmit(true, true, true, true);
        emit KipuBank.KipuBank_DepositSuccessful(user, _deposit);
        kipuBank.deposit{value: _deposit}();

        vm.stopPrank();

        assertEq(kipuBank.s_userBank(user), _deposit);
        assertEq(address(kipuBank).balance, _deposit);
    }

    function testMultipleDeposits() public {
        uint256 _deposit1 = 3 ether;
        uint256 _deposit2 = 4 ether;

        vm.startPrank(user);

        kipuBank.deposit{value: _deposit1}();
        kipuBank.deposit{value: _deposit2}();

        vm.stopPrank();

        uint256 totalDeposit = _deposit1 + _deposit2;
        assertEq(kipuBank.s_userBank(user), totalDeposit);
        assertEq(address(kipuBank).balance, totalDeposit);
    }

    function testDepositExceedsBankCap() public {
        uint256 _depositExceeded = 12 ether;
        uint256 _depositRight = 2 ether;

        vm.startPrank(user);

        vm.expectRevert(
            abi.encodeWithSelector(
                KipuBank.KipuBank_AmountExceedsBankCap.selector,
                "Bank Cap: ",
                BANK_CAP,
                "Limit Exceeds: ",
                _depositExceeded
            )
        );
        kipuBank.deposit{value: _depositExceeded}();

        vm.expectEmit(true, true, true, true);
        emit KipuBank.KipuBank_DepositSuccessful(user, _depositRight);
        kipuBank.deposit{value: _depositRight}();

        vm.stopPrank();

        assertEq(kipuBank.s_userBank(user), _depositRight);
        assertEq(address(kipuBank).balance, _depositRight);
    }

    function testWithdrawSuccess() public {
        uint256 _deposit = 2 ether;
        uint256 _withdraw = 1 ether;

        vm.startPrank(user);

        vm.expectEmit(true, true, true, true);
        emit KipuBank.KipuBank_DepositSuccessful(user, _deposit);
        kipuBank.deposit{value: _deposit}();

        vm.expectEmit(true, true, true, true);
        emit KipuBank.KipuBank_WithdrawSuccessful(user, _withdraw);
        kipuBank.withdraw(_withdraw);

        vm.stopPrank();

        assertEq(kipuBank.s_userBank(user), _deposit - _withdraw);
        assertEq(user.balance, initialBalance - _deposit + _withdraw);
    }

    function testMultipleWithdrawalsWithinLimit() public {
        uint256 _deposit = 5 ether;
        uint256 _withdraw1 = 1 ether;
        uint256 _withdraw2 = 1 ether;

        vm.startPrank(user);

        kipuBank.deposit{value: _deposit}();

        kipuBank.withdraw(_withdraw1);
        kipuBank.withdraw(_withdraw2);

        vm.stopPrank();

        uint256 remainingBalance = _deposit - (_withdraw1 + _withdraw2);
        assertEq(kipuBank.s_userBank(user), remainingBalance);
        assertEq(user.balance, initialBalance - remainingBalance);
    }

    function testWithdrawFailsExceedsUserBalance() public {
        uint256 _deposit = 0.5 ether;
        uint256 _withdraw = 1 ether;

        vm.startPrank(user);

        vm.expectEmit(true, true, true, true);
        emit KipuBank.KipuBank_DepositSuccessful(user, _deposit);
        kipuBank.deposit{value: _deposit}();

        vm.expectRevert(
            abi.encodeWithSelector(
                KipuBank.KipuBank_AmountExceedsUserBalance.selector,
                "Amount Exceeds: ",
                _withdraw,
                "Current User Balance: ",
                _deposit
            )
        );
        kipuBank.withdraw(_withdraw);
        
        vm.stopPrank();

        assertEq(kipuBank.s_userBank(user), _deposit);
        assertEq(user.balance, initialBalance - _deposit);
    }

    function testWithdrawFailsExceedsWithdrawLimit() public {
        uint256 _deposit = 5 ether;
        uint256 _withdraw = 2 ether;

        vm.startPrank(user);

        vm.expectEmit(true, true, true, true);
        emit KipuBank.KipuBank_DepositSuccessful(user, _deposit);
        kipuBank.deposit{value: _deposit}();

        vm.expectRevert(
            abi.encodeWithSelector(
                KipuBank.KipuBank_AmountExceedsWithdrawLimit.selector,
                "Amount Exceeds: ",
                _withdraw,
                "Withdraw Limit: ",
                WITHDRAW_LIMIT
            )
        );
        kipuBank.withdraw(_withdraw);

        vm.stopPrank();
    }

    function testContractBalanceCheck() public {
        uint256 _deposit = 3 ether;

        vm.startPrank(user);

        vm.expectEmit(true, true, true, true);
        emit KipuBank.KipuBank_DepositSuccessful(user, _deposit);
        kipuBank.deposit{value: _deposit}();

        vm.stopPrank();

        assertEq(kipuBank.contractBalance(), _deposit);
    }

    function testContractBalanceAfterMultipleTransactions() public {
        uint256 _deposit1 = 3 ether;
        uint256 _deposit2 = 2 ether;
        uint256 _withdraw = 1 ether;

        vm.startPrank(user);

        kipuBank.deposit{value: _deposit1}();
        kipuBank.deposit{value: _deposit2}();
        kipuBank.withdraw(_withdraw);

        vm.stopPrank();

        uint256 expectedBalance = (_deposit1 + _deposit2) - _withdraw;
        assertEq(kipuBank.contractBalance(), expectedBalance);
    }
}
