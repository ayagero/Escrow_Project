// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/Escrow.sol";

contract EscrowTest is Test {
    Escrow escrow;
    address buyer = address(0x1);
    address seller = address(0x2);
    address arbiter = address(0x3);
    address attacker = address(0x4);

    event Deposited(address indexed buyer, uint256 amount);
    event Released(address indexed seller, uint256 amount);
    event Refunded(address indexed buyer, uint256 amount);

    function setUp() public {
        vm.prank(buyer);
        escrow = new Escrow(buyer, seller, arbiter);
        vm.deal(buyer, 100 ether); // Fund buyer for tests
        vm.deal(attacker, 100 ether); // Fund attacker for tests
    }

    // Unit Tests
    function test_Constructor() public {
        assertEq(escrow.buyer(), buyer);
        assertEq(escrow.seller(), seller);
        assertEq(escrow.arbiter(), arbiter);
        assertEq(uint(escrow.state()), 0); // State.Created
        assertEq(escrow.getBalance(), 0);
    }

    function test_Deposit() public {
        vm.prank(buyer);
        vm.expectEmit(true, false, false, true);
        emit Deposited(buyer, 1 ether);
        escrow.deposit{value: 1 ether}();

        assertEq(escrow.amount(), 1 ether);
        assertEq(escrow.getBalance(), 1 ether);
        assertEq(uint(escrow.state()), 1); // State.Funded
    }

    function test_Deposit_NotBuyer() public {
        vm.prank(attacker);
        vm.expectRevert("Only buyer can call this");
        escrow.deposit{value: 1 ether}();
    }

    function test_Deposit_ZeroValue() public {
        vm.prank(buyer);
        vm.expectRevert("Deposit must be greater than 0");
        escrow.deposit{value: 0}();
    }

    function test_Deposit_WrongState() public {
        vm.prank(buyer);
        escrow.deposit{value: 1 ether}();
        vm.prank(buyer); // Ensure second call is by buyer
        vm.expectRevert("Invalid state");
        escrow.deposit{value: 1 ether}();
    }

    function test_Release() public {
        vm.prank(buyer);
        escrow.deposit{value: 1 ether}();

        uint256 sellerBalanceBefore = seller.balance;
        vm.prank(arbiter);
        vm.expectEmit(true, false, false, true);
        emit Released(seller, 1 ether);
        escrow.release();

        assertEq(escrow.getBalance(), 0);
        assertEq(escrow.amount(), 0);
        assertEq(uint(escrow.state()), 2); // State.Released
        assertEq(seller.balance, sellerBalanceBefore + 1 ether);
    }

    function test_Release_NotArbiter() public {
        vm.prank(buyer);
        escrow.deposit{value: 1 ether}();

        vm.prank(attacker);
        vm.expectRevert("Only arbiter can call this");
        escrow.release();
    }

    function test_Release_WrongState() public {
        vm.prank(arbiter);
        vm.expectRevert("Invalid state");
        escrow.release();
    }

    function test_Refund() public {
        vm.prank(buyer);
        escrow.deposit{value: 1 ether}();

        uint256 buyerBalanceBefore = buyer.balance;
        vm.prank(arbiter);
        vm.expectEmit(true, false, false, true);
        emit Refunded(buyer, 1 ether);
        escrow.refund();

        assertEq(escrow.getBalance(), 0);
        assertEq(escrow.amount(), 0);
        assertEq(uint(escrow.state()), 3); // State.Refunded
        assertEq(buyer.balance, buyerBalanceBefore + 1 ether);
    }

    function test_Refund_NotArbiter() public {
        vm.prank(buyer);
        escrow.deposit{value: 1 ether}();

        vm.prank(attacker);
        vm.expectRevert("Only arbiter can call this");
        escrow.refund();
    }

    function test_Refund_WrongState() public {
        vm.prank(arbiter);
        vm.expectRevert("Invalid state");
        escrow.refund();
    }

    // Fuzz Tests
    function testFuzz_Deposit(uint256 depositAmount) public {
        vm.assume(depositAmount > 0 && depositAmount <= 100 ether);

        vm.prank(buyer);
        vm.expectEmit(true, false, false, true);
        emit Deposited(buyer, depositAmount);
        escrow.deposit{value: depositAmount}();

        assertEq(escrow.amount(), depositAmount);
        assertEq(escrow.getBalance(), depositAmount);
        assertEq(uint(escrow.state()), 1); // State.Funded
    }

    function testFuzz_Release(uint256 depositAmount) public {
        vm.assume(depositAmount > 0 && depositAmount <= 100 ether);

        vm.prank(buyer);
        escrow.deposit{value: depositAmount}();

        uint256 sellerBalanceBefore = seller.balance;
        vm.prank(arbiter);
        vm.expectEmit(true, false, false, true);
        emit Released(seller, depositAmount);
        escrow.release();

        assertEq(escrow.getBalance(), 0);
        assertEq(escrow.amount(), 0);
        assertEq(uint(escrow.state()), 2); // State.Released
        assertEq(seller.balance, sellerBalanceBefore + depositAmount);
    }

    function testFuzz_Refund(uint256 depositAmount) public {
        vm.assume(depositAmount > 0 && depositAmount <= 100 ether);

        vm.prank(buyer);
        escrow.deposit{value: depositAmount}();

        uint256 buyerBalanceBefore = buyer.balance;
        vm.prank(arbiter);
        vm.expectEmit(true, false, false, true);
        emit Refunded(buyer, depositAmount);
        escrow.refund();

        assertEq(escrow.getBalance(), 0);
        assertEq(escrow.amount(), 0);
        assertEq(uint(escrow.state()), 3); // State.Refunded
        assertEq(buyer.balance, buyerBalanceBefore + depositAmount);
    }
}