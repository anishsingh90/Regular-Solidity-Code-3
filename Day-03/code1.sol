// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IERC20 {
    function totalSupply() external view returns(uint256);
    function balanceOf(address) external view returns(uint256);
    function transfer(address to, uint256 value) external returns(bool);
    function transferFrom(address src, address dst, uint256 value) external returns(bool);
    function decimals() external view returns(uint8);
}

contract SavingAccount{
    uint256 private constant RAY = 1e27;


    IERC20 public immutable asset;
    address public immutable admin;

    uint256 public index;
    uint256 public lastAccrual;
    uint256 public ratePerSecond;

    uint256 public totalScaledSupply;
    mapping (address => uint256) public scaledBalanceOf;

    error NotAdmin();
    error ZeroAmount();
    error InsufficientBalance();
    error TransferFailed();

    event Deposited(address indexed user, uint256 amount, uint256 scaledAdded);
    event Withdrawn(address indexed user, uint256 amount, uint256 scaledRemoved);
    event Accrued(uint256 newIndex, uint256 ratePerSecond);
    event RateUpdated(uint256 oldRate, uint256 newRate);
    event ReserveFunded(address indexed from, uint256 amount);

    constructor(IERC20 _asset, uint256 _ratePerSecond){
        asset = _asset;
        admin = msg.sender;

        index = RAY;
        lastAccrual = block.timestamp;
        ratePerSecond = _ratePerSecond;
    }

    modifier onlyAdmin(){
        if(msg.sender != admin) revert NotAdmin();
        _;
    }

    //Current index accounting for elapsed time
    function previewIndex() public view returns(uint256){
        uint256 t = block.timestamp;
        uint256 dt = t - lastAccrual;
        if(dt == 0) return index;

        uint256 linear = (ratePerSecond * dt) / RAY;
        return index + ((index * linear)/1);
    }

    //Actual user balance in asset uints at current time.
    function balanceOf(address user) external view returns(uint256){
        uint256 idx = previewIndex();
        uint256 sb = scaledBalanceOf[user];
        if(sb == 0) return 0;

        return (sb * idx) / RAY;
    }

    //Total liabilities (sum of all user actual balances)
    function totalAssets() external view returns(uint256){
        uint256 idx = previewIndex();
        return (totalScaledSupply * idx) / RAY;
    }

    //Update the stored index to the current time. Cheap and collable by anyone
    function accrue() public {
        uint256 t = block.timestamp;
        uint256 dt = t - lastAccrual;
        if(dt == 0) return;

        uint256 oldIndex = index;
        uint256 linear = (ratePerSecond * dt) / RAY;
        uint256 delta = (oldIndex * linear);
        index = oldIndex + delta;

        lastAccrual = t;
        emit Accrued(index, ratePerSecond);
    }

    function deposit(uint256 amount) external{
        if(amount == 0) revert ZeroAmount();
        accrue();

        if(!asset.transferFrom(msg.sender, address(this), amount)) revert TransferFailed();

        uint256 idx = index;
        uint256 scaled = (amount * RAY) / idx;

        unchecked{
            scaledBalanceOf[msg.sender] += scaled;
            totalScaledSupply += scaled;
        }
        emit Deposited(msg.sender, amount, scaled);
    }


    //Withdraw all available balance (saves gas vs preview + explicit amount)
    function withdrawAll() external {
        accrue();
        uint256 sb = scaledBalanceOf[msg.sender];
        if(sb == 0) revert InsufficientBalance();

        uint256 idx = index;
        uint256 amount = (sb * idx) / RAY;

        //Effects
        scaledBalanceOf[msg.sender] = 0;
        unchecked {totalScaledSupply -= sb;}

        //Interactions
        if(!asset.transfer(msg.sender, amount)) revert TransferFailed();

        emit Withdrawn(msg.sender, amount, sb);
    }

    //Fund the reserve with additional tokens (used to pay accrued interest)
    function fundReserve(uint256 amount) external onlyAdmin{
        if(amount == 0) revert ZeroAmount();
        if(!asset.transferFrom(msg.sender, address(this), amount)) revert TransferFailed();
        emit ReserveFunded(msg.sender, amount);
    }

    //Update the fixed rate per second (in RAY)
    function setRatePerSecond(uint256 newRatePerSecond) external onlyAdmin{
        accrue();
        uint256 old = ratePerSecond;
        ratePerSecond = newRatePerSecond;
        emit RateUpdated(old, newRatePerSecond);
    }
}