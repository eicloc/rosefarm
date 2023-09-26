// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract RoseFarm {
    IERC20 public immutable seedCoin;
    IERC20 public immutable roseCoin;
    address private owner;
    uint decimals = 10 ** 18;
    uint private pool1 = 40;
    uint private pool2 = 60;
    uint public compoundRate = 10;
    uint public timeGap = 10800000;
    
    //Struct of stakings
    struct Stake {
        uint amount;
        uint idx;
        uint ri;
        uint startAt;
        uint duration;
        uint rewards;
    }

    //Struct of deposit
    struct Deposit {
        uint amount;
        uint idx;
        uint startAt;
        uint duration;
        uint earns;
    }

    //numValid
    mapping(uint => uint) numValid;
    //mapping of validators
    mapping(uint => mapping(address => bool)) isValid;
    //total staked amount in pool1 or pool2 or pool3
    mapping(uint => uint) totalSupplyOf;
    //rewards to be claimed in pool1 or pool2
    mapping(uint => mapping(address => uint)) toBeClaimed;
    mapping(address => uint) totalRwdsOf;
    mapping(address => uint) totalEarnOf;
    //Staking list of user in Pool1 or Pool2
    mapping(uint => mapping(address => Stake[])) private stakesOf;
    //Balance of user in Pool1 or Pool2
    mapping(uint => mapping(address => uint)) public poolStakedAmount;

    //Deposit list of user in Pool3
    mapping(address => Deposit[]) private depsOf;
    //Deposit amount in pool3
    mapping(address => uint) public depositAmt;

    //rewardIndex, other word the latest block
    mapping(uint => uint) private _rwdIndex;


    

    //Set compound rate and mul
    function setCpdRate(uint _rate) external {
        require(msg.sender == owner, "Not permitted.");
        compoundRate = _rate;
    }

    //update the rewardIndex
    function updateRwdIndex(uint _reward) external {
        uint totalSupply = totalSupplyOf[1] + totalSupplyOf[2];
        _rwdIndex[1] += ((_reward * pool1) / (totalSupply / decimals));
        _rwdIndex[2] += ((_reward * pool2) / (totalSupply / decimals));
    }

    //Import the tokens' contract
    constructor(address _seedCoin, address _roseCoin) {
        owner = msg.sender;
        seedCoin = IERC20(_seedCoin);
        roseCoin = IERC20(_roseCoin);
    }

    //Stake
    function stake(uint _pool, uint _amount, uint duration) external {
        require(
            seedCoin.balanceOf(msg.sender) >= _amount,
            "Insufficient balance."
        );
        Stake[] memory orders = stakesOf[_pool][msg.sender];
        stakesOf[_pool][msg.sender][orders.length] = Stake({
            amount: _amount,
            idx: orders.length,
            ri: _rwdIndex[_pool],
            startAt: block.timestamp,
            duration: duration,
            rewards: 0
        });

        if (!isValid[_pool][msg.sender]) {
            numValid[_pool] += 1;
            isValid[_pool][msg.sender] = true;
        }

        poolStakedAmount[_pool][msg.sender] += _amount;
        totalSupplyOf[_pool] += _amount;

        seedCoin.transferFrom(msg.sender, address(this), _amount);
    }

    //Unstake
    function unstake(uint _pool, uint _idx, uint _amount) external {
        stakesOf[_pool][msg.sender][_idx].amount = 0;
        poolStakedAmount[_pool][msg.sender] -= _amount;
        if (poolStakedAmount[_pool][msg.sender] == 0) {
            isValid[_pool][msg.sender] = false;
            numValid[_pool] -= 1;
        }
        totalSupplyOf[_pool] -= _amount;
        seedCoin.transfer(msg.sender, _amount);
    }

    //Claim rewards
    function claimReward(uint _pool, uint claimAmt) external {
        roseCoin.transfer(msg.sender, claimAmt);
        toBeClaimed[_pool][msg.sender] -= claimAmt;
    }

    //Deposit SEED
    function deposit(uint _amount, uint _duration) external {
        require(
            seedCoin.balanceOf(msg.sender) >= _amount,
            "Insufficient balance."
        );
        uint len = depsOf[msg.sender].length;

        depsOf[msg.sender][len] = Deposit({
            amount: _amount,
            idx: len,
            startAt: block.timestamp,
            duration: _duration,
            earns: _amount
        });

        if (!isValid[3][msg.sender]) {
            numValid[3] += 1;
            isValid[3][msg.sender] = true;
        }

        totalSupplyOf[3] += _amount;
        depositAmt[msg.sender] += _amount;
        seedCoin.transferFrom(msg.sender, address(this), _amount);
    }

    //Withdraw the deposit and earns together
    function withdraw(uint _idx) external {
        uint deposited = depsOf[msg.sender][_idx].amount;
        uint earns = depsOf[msg.sender][_idx].earns;
        totalEarnOf[msg.sender] += earns - deposited;
        depositAmt[msg.sender] -= deposited;
        totalSupplyOf[3] -= deposited;
        delete depsOf[msg.sender][_idx];

        if (depositAmt[msg.sender] == 0) {
            isValid[3][msg.sender] = false;
            numValid[3] -= 1;
        }

        seedCoin.transfer(msg.sender, earns);
    }

    //Calculate the rewards of user
    function refreshCalculateRewards(uint _pool) external {
        //get the latest r first
        uint rINow = _rwdIndex[_pool];
        uint toBeClaim = 0;
        //have the current timestamp
        // uint tStamp = block.timestamp;
        Stake[] memory orders = stakesOf[_pool][msg.sender];
        for (uint i = 0; i < orders.length; i++) {
            // uint timeLeft = (orders[i].startAt + orders[i].duration) - tStamp;
            stakesOf[_pool][msg.sender][i].rewards =
                (orders[i].amount * (rINow - orders[i].ri)) /
                decimals;
            toBeClaim += stakesOf[_pool][msg.sender][i].rewards;
            // stakesOf[_pool][msg.sender][i].timeLeft = timeLeft > 0 ? timeLeft : 0;
        }

        toBeClaimed[_pool][msg.sender] = toBeClaim;
    }

    //Calculate the earnings of user
    function refreshCalculateEarned() external view {
        //have the current timestamp
        uint tStamp = block.timestamp;
        Deposit[] memory dept = depsOf[msg.sender];
        for (uint i = 0; i < dept.length; i++) {
            uint period = ((tStamp - dept[i].startAt) / timeGap);
            dept[i].earns = period > 0
                ? (dept[i].amount * (100 + compoundRate) ** period) /
                    100 ** period
                : dept[i].amount;
        }
    }
}
