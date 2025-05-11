// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract Escrow {
    address public buyer;
    address public seller;
    address public arbiter;
    uint256 public amount;

    enum State { Created, Funded, Released, Refunded }
    State public state;

    event Deposited(address indexed buyer, uint256 amount);
    event Released(address indexed seller, uint256 amount);
    event Refunded(address indexed buyer, uint256 amount);

    modifier onlyArbiter() {
        require(msg.sender == arbiter, "Only arbiter can call this");
        _;
    }

    modifier onlyBuyer() {
        require(msg.sender == buyer, "Only buyer can call this");
        _;
    }

    modifier inState(State expectedState) {
        require(state == expectedState, "Invalid state");
        _;
    }

    constructor(address _buyer, address _seller, address _arbiter) {
        require(_buyer != address(0) && _seller != address(0) && _arbiter != address(0), "Invalid address");
        buyer = _buyer;
        seller = _seller;
        arbiter = _arbiter;
        state = State.Created;
    }

    function deposit() external payable onlyBuyer inState(State.Created) {
        require(msg.value > 0, "Deposit must be greater than 0");
        amount = msg.value;
        state = State.Funded;
        emit Deposited(msg.sender, msg.value);
    }

    function release() external onlyArbiter inState(State.Funded) {
        state = State.Released;
        emit Released(seller, amount);
        (bool success, ) = seller.call{value: amount}("");
        require(success, "Transfer failed");
        amount = 0;
    }

    function refund() external onlyArbiter inState(State.Funded) {
        state = State.Refunded;
        emit Refunded(buyer, amount);
        (bool success, ) = buyer.call{value: amount}("");
        require(success, "Transfer failed");
        amount = 0;
    }

    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }
}