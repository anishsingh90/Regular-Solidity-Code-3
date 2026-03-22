// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract StakingPool is Ownable {
    using SafeERC20 for IERC20;

    IERC20 public stakingToken;
    IERC20 public rewardToken;

    uint256 public rewardRate;
    uint256 public rewardsDuration;
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;

    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;
    mapping(address => uint256) public stakedAmounts;

    uint256 private _totalSupply;
    bool public paused;

    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);
    event RewardAdded(uint256 reward);
    event Paused(address indexed account);
    event Unpaused(address indexed account);

    constructor(
    address _stakingToken,
    address _rewardToken,
    uint256 _rewardRate,
    uint256 _rewardsDuration,
    address initialOwner
) Ownable(initialOwner) {
    stakingToken = IERC20(_stakingToken);
    rewardToken = IERC20(_rewardToken);
    rewardRate = _rewardRate;
    rewardsDuration = _rewardsDuration;
    lastUpdateTime = block.timestamp;
}

    modifier updateReward(address _account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();
        if (_account != address(0)) {
            rewards[_account] = earned(_account);
            userRewardPerTokenPaid[_account] = rewardPerTokenStored;
        }
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "Pausable: paused");
        _;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address _account) public view returns (uint256) {
        return stakedAmounts[_account];
    }

    function lastTimeRewardApplicable() public view returns (uint256) {
        return block.timestamp < lastUpdateTime + rewardsDuration ? block.timestamp : lastUpdateTime + rewardsDuration;
    }

    function rewardPerToken() public view returns (uint256) {
        if (_totalSupply == 0) {
            return rewardPerTokenStored;
        }
        return
            rewardPerTokenStored +
            (((lastTimeRewardApplicable() - lastUpdateTime) * rewardRate * 1e18) / _totalSupply);
    }

    function earned(address _account) public view returns (uint256) {
        return
            ((stakedAmounts[_account] * (rewardPerToken() - userRewardPerTokenPaid[_account])) / 1e18) +
            rewards[_account];
    }

    function stake(uint256 _amount) external updateReward(msg.sender) whenNotPaused {
        require(_amount > 0, "Cannot stake 0");
        _totalSupply += _amount;
        stakedAmounts[msg.sender] += _amount;
        stakingToken.safeTransferFrom(msg.sender, address(this), _amount);
        emit Staked(msg.sender, _amount);
    }

    function withdraw(uint256 _amount) public updateReward(msg.sender) whenNotPaused {
        require(_amount > 0, "Cannot withdraw 0");
        _totalSupply -= _amount;
        stakedAmounts[msg.sender] -= _amount;
        stakingToken.safeTransfer(msg.sender, _amount);
        emit Withdrawn(msg.sender, _amount);
    }

    function exit() external {
        withdraw(stakedAmounts[msg.sender]);
        getReward();
    }

    function getReward() public updateReward(msg.sender) whenNotPaused {
        uint256 reward = rewards[msg.sender];
        if (reward > 0) {
            rewards[msg.sender] = 0;
            rewardToken.safeTransfer(msg.sender, reward);
            emit RewardPaid(msg.sender, reward);
        }
    }

    function notifyRewardAmount(uint256 _reward) external onlyOwner updateReward(address(0)) whenNotPaused {
        require(_reward > 0, "Reward must be > 0");
        require(block.timestamp >= lastUpdateTime + rewardsDuration, "Previous rewards period must be complete before changing the reward rate");

        uint256 balance = rewardToken.balanceOf(address(this));
        require(_reward <= balance, "Reward amount exceeds balance");

        rewardToken.safeTransferFrom(msg.sender, address(this), _reward);
        lastUpdateTime = block.timestamp;
        rewardRate = _reward / rewardsDuration;
        emit RewardAdded(_reward);
    }

    function setRewardsDuration(uint256 _rewardsDuration) external onlyOwner {
        require(
            block.timestamp >= lastUpdateTime + rewardsDuration,
            "Previous rewards period must be complete before changing the duration for the new period"
        );
        rewardsDuration = _rewardsDuration;
    }

    function pause() external onlyOwner {
        paused = true;
        emit Paused(msg.sender);
    }

    function unpause() external onlyOwner {
        paused = false;
        emit Unpaused(msg.sender);
    }
}