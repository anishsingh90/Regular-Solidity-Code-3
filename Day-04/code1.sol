// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract SecureLendingPool is ReentrancyGuard {
    // Mapping to track user balances
    mapping(address => uint256) public balances;
    // Total Ether in the pool
    uint256 public totalPool;
    // Interest rate (5% per year)
    uint256 public constant INTEREST_RATE = 5;
    // Last update time for each user
    mapping(address => uint256) public lastUpdateTime;
    // Withdrawal limit per transaction
    uint256 public constant WITHDRAWAL_LIMIT = 1 ether;

    // Event for deposits
    event Deposited(address indexed user, uint256 amount);
    // Event for withdrawals
    event Withdrawn(address indexed user, uint256 amount);
    // Event for interest calculations
    event InterestCalculated(address indexed user, uint256 amount);

    // Deposit Ether into the pool
    function deposit() external payable nonReentrant {
        require(msg.value > 0, "Deposit amount must be greater than 0");

        balances[msg.sender] += msg.value;
        totalPool += msg.value;
        lastUpdateTime[msg.sender] = block.timestamp;

        emit Deposited(msg.sender, msg.value);
    }

    // Withdraw Ether from the pool with interest
    function withdraw(uint256 amount) external nonReentrant {
        require(amount > 0, "Withdrawal amount must be greater than 0");
        require(amount <= WITHDRAWAL_LIMIT, "Exceeds withdrawal limit");
        require(balances[msg.sender] >= amount, "Insufficient balance");

        uint256 interest = calculateInterest(msg.sender);
        uint256 totalWithdraw = amount + interest;

        require(totalPool >= totalWithdraw, "Insufficient pool balance");

        balances[msg.sender] -= amount;
        totalPool -= totalWithdraw;

        payable(msg.sender).transfer(totalWithdraw);

        emit Withdrawn(msg.sender, totalWithdraw);
    }

    // Calculate interest for a user
    function calculateInterest(address user) public returns (uint256) {
        uint256 timeElapsed = block.timestamp - lastUpdateTime[user];
        uint256 interest = (balances[user] * INTEREST_RATE * timeElapsed) / (365 days * 100);

        emit InterestCalculated(user, interest);
        return interest;
    }

    // Function to get days in seconds
    function convertDaysToSeconds(uint256 _days) public pure returns (uint256) {
        return _days * 1 days;
    }
}