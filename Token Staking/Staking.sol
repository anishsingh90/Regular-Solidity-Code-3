// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Staking is Ownable {
    IERC20 public stakingToken;
    IERC20 public rewardToken;
    uint256 public rewardRate;
    uint256 public lastUpdateTime;
    uint256 public totalStaked;

    mapping(address => uint256) public userStakedAmounts;
    mapping(address => uint256) public userRewards;

    event Staked(address indexed user, uint256 amount);
    event Unstaked(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);

    constructor(
        address _stakingToken,
        address _rewardToken,
        uint256 _rewardRate,
        address _initialOwner
    ) Ownable(_initialOwner) {
        stakingToken = IERC20(_stakingToken);
        rewardToken = IERC20(_rewardToken);
        rewardRate = _rewardRate;
        lastUpdateTime = block.timestamp;
    }

    // ... rest of your contract code ...
}