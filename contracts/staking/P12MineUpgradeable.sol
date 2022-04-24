// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

//import { DecimalMath } from '../libraries/DecimalMath.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/utils/math/SafeMath.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import { IP12RewardVault, P12RewardVault } from './P12RewardVault.sol';

import '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';
import '@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';

contract P12MineUpgradeable is Initializable, UUPSUpgradeable, OwnableUpgradeable {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  uint256 constant ONE = 10**18;

  // Info of each user.
  struct UserInfo {
    uint256 amountOfLpToken; // How many LP tokens the user has provided.
    uint256 rewardDebt; // Reward debt. See explanation below.
    uint256 amountOfP12;
    //
    // We do some fancy math here. Basically, any point in time, the amount of P12s
    // entitled to a user but is pending to be distributed is:
    //
    //   pending reward = (amountOfp12 * pool.accP12PerShare) - user.rewardDebt
    //
    // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
    //   1. The pool's `accP12PerShare` (and `lastRewardBlock`) gets updated.
    //   2. User receives the pending reward sent to his/her address.
    //   3. User's `amount` gets updated.
    //   4. User's `rewardDebt` gets updated.
  }

  // Info of each pool.
  struct PoolInfo {
    address lpToken; // Address of LP token contract.
    uint256 p12Total;
    uint256 lastRewardBlock; // Last block number that P12s distribution occurs.
    uint256 accP12PerShare; // Accumulated P12s per share, times 1e18. See below.
  }
  // withdraw info

  struct WithdrawInfo {
    uint256 amount;
    uint256 unlockTimestamp;
    bool executed;
  }

  address public p12Factory;
  address public p12Token;

  address public p12RewardVault;
  uint256 public p12PerBlock;

  // Info of each pool.
  PoolInfo[] public poolInfos;
  mapping(address => uint256) public lpTokenRegistry;

  // Info of each user that stakes LP tokens.
  mapping(uint256 => mapping(address => UserInfo)) public userInfo;
  mapping(address => uint256) public realizedReward;

  // The block number when P12 mining starts.
  uint256 public startBlock;

  uint256 public delayK;
  uint256 public delayB;

  // lpToken => id
  mapping(address => bytes32) public preWithdrawIds;
  // lpToken => id=> WithdrawInfo
  mapping(address => mapping(bytes32 => WithdrawInfo)) public withdrawInfos;

  // Sum of all pools p12
  uint256 public totalBalanceOfP12;

  mapping(address => uint256) public totalLpStakedOfEachPool;

  uint256 private unlocked;

  event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
  event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
  event WithdrawDelay(address indexed user, uint256 indexed pid, uint256 amount, bytes32 newWithdrawId);
  event Claim(address indexed user, uint256 amount);

  function initialize(
    address _p12Token,
    address _p12Factory,
    uint256 _startBlock,
    uint256 _delayK,
    uint256 _delayB
  ) public initializer {
    __Ownable_init();
    p12Token = _p12Token;
    p12Factory = _p12Factory;
    p12RewardVault = address(new P12RewardVault(_p12Token));
    startBlock = _startBlock;
    delayK = _delayK;
    delayB = _delayB;
    unlocked = 1;
  }

  function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

  // ============ Modifiers ============

  modifier lpTokenExist(address lpToken) {
    require(lpTokenRegistry[lpToken] > 0, 'P12Mine: LP Token Not Exist');
    _;
  }

  modifier lpTokenNotExist(address lpToken) {
    require(lpTokenRegistry[lpToken] == 0, 'P12Mine: LP Token Already Exist');
    _;
  }

  modifier P12FactoryOrOwner() {
    require(msg.sender == p12Factory || msg.sender == owner(), 'P12Mine: caller must be p12factory or owner');
    _;
  }

  modifier onlyP12Factory() {
    require(msg.sender == p12Factory, 'P12Mine: caller must be p12factory');
    _;
  }

  modifier lock() {
    require(unlocked == 1, 'P12Mine: LOCKED');
    unlocked = 0;
    _;
    unlocked = 1;
  }

  // ============ Helper ============

  function poolLength() external view virtual returns (uint256) {
    return poolInfos.length;
  }

  function getPid(address _lpToken) public view virtual lpTokenExist(_lpToken) returns (uint256) {
    return lpTokenRegistry[_lpToken] - 1;
  }

  function getUserLpBalance(address _lpToken, address _user) public view virtual returns (uint256) {
    uint256 pid = getPid(_lpToken);
    return userInfo[pid][_user].amountOfLpToken;
  }

  function createWithdrawId(
    address lpToken,
    uint256 amount,
    address to
  ) internal virtual returns (bytes32 hash) {
    bytes32 preWithdrawId = preWithdrawIds[lpToken];
    bytes32 withdrawId = keccak256(abi.encode(lpToken, amount, to, preWithdrawId));

    preWithdrawIds[lpToken] = withdrawId;

    return withdrawId;
  }

  // This method is only used when creating game coin in p12factory
  function addLpTokenInfoForGameCreator(address _lpToken, address gameCoinCreator) public virtual onlyP12Factory {
    uint256 pid = getPid(_lpToken);
    uint256 _totalLpStaked = totalLpStakedOfEachPool[_lpToken];
    uint256 totalLpStaked = IERC20(_lpToken).balanceOf(address(this));
    uint256 _amount = totalLpStaked.sub(_totalLpStaked);
    require(_amount > 0, 'P12Mine: _amount should greater than zero ');
    PoolInfo storage pool = poolInfos[pid];
    UserInfo storage user = userInfo[pid][gameCoinCreator];
    updatePool(pid);
    // Update the current value of lpTokens
    user.amountOfLpToken = user.amountOfLpToken.add(_amount);
    totalLpStakedOfEachPool[_lpToken] += _amount;

    // Calculate the value of p12 corresponding to lpToken
    uint256 _amountOfP12 = calculateP12AmountByLpToken(_lpToken, _amount);
    // Update the value of p12 in the current pool
    pool.p12Total = pool.p12Total.add(_amountOfP12);
    // Update the value of the current user p12
    user.amountOfP12 = user.amountOfP12.add(_amountOfP12);
    // Update the value of p12 in the total pool
    totalBalanceOfP12 = totalBalanceOfP12.add(_amountOfP12);

    //user.rewardDebt = DecimalMath.mul(user.amountOfP12, pool.accP12PerShare);
    user.rewardDebt = user.amountOfP12.mul(pool.accP12PerShare).div(ONE);
    emit Deposit(gameCoinCreator, pid, _amount);
  }

  // Calculate the value of p12 corresponding to lpToken
  function calculateP12AmountByLpToken(address _lpToken, uint256 _amount) public virtual returns (uint256) {
    getPid(_lpToken);
    uint256 balance0 = IERC20(p12Token).balanceOf(_lpToken);
    uint256 _totalSupply = IERC20(_lpToken).totalSupply();
    uint256 amount0 = _amount.mul(balance0) / _totalSupply;

    return amount0;
  }

  // ============ Ownable ============

  function createPool(address _lpToken, bool _withUpdate) public virtual lpTokenNotExist(_lpToken) P12FactoryOrOwner {
    if (_withUpdate) {
      massUpdatePools();
    }
    uint256 lastRewardBlock = block.number > startBlock ? block.number : startBlock;
    poolInfos.push(PoolInfo({ lpToken: _lpToken, p12Total: 0, lastRewardBlock: lastRewardBlock, accP12PerShare: 0 }));
    lpTokenRegistry[_lpToken] = poolInfos.length;
  }

  function setReward(uint256 _p12PerBlock, bool _withUpdate) external virtual onlyOwner {
    if (_withUpdate) {
      massUpdatePools();
    }
    p12PerBlock = _p12PerBlock;
  }

  function setDelayK(uint256 _delayK) public virtual onlyOwner returns (bool) {
    delayK = _delayK;
    return true;
  }

  function setDelayB(uint256 _delayB) public virtual onlyOwner returns (bool) {
    delayB = _delayB;
    return true;
  }

  // ============ View Rewards ============

  // function getPendingReward(address _lpToken, address _user)
  //     external
  //     view
  //     virtual
  //     returns (uint256)
  // {
  //     uint256 pid = getPid(_lpToken);
  //     PoolInfo storage pool = poolInfos[pid];
  //     UserInfo storage user = userInfo[pid][_user];
  //     uint256 accP12PerShare = pool.accP12PerShare;
  //     uint256 totalLpStaked = IERC20(pool.lpToken).balanceOf(address(this));
  //     if (block.number > pool.lastRewardBlock && totalLpStaked != 0) {
  //         uint256 P12Reward = block
  //             .number
  //             .sub(pool.lastRewardBlock)
  //             .mul(p12PerBlock)
  //             .mul(pool.p12Total)
  //             .div(totalBalanceOfP12);
  //         accP12PerShare = accP12PerShare.add(
  //             DecimalMath.divFloor(P12Reward, pool.p12Total)
  //         );
  //     }
  //     return
  //         DecimalMath.mul(user.amountOfP12, accP12PerShare).sub(
  //             user.rewardDebt
  //         );
  // }

  // function getAllPendingReward(address _user)
  //     external
  //     view
  //     virtual
  //     returns (uint256)
  // {
  //     uint256 length = poolInfos.length;
  //     uint256 totalReward = 0;
  //     for (uint256 pid = 0; pid < length; ++pid) {
  //         if (
  //             userInfo[pid][_user].amountOfLpToken == 0 ||
  //             poolInfos[pid].p12Total == 0
  //         ) {
  //             continue; // save gas
  //         }
  //         PoolInfo storage pool = poolInfos[pid];
  //         UserInfo storage user = userInfo[pid][_user];
  //         uint256 accP12PerShare = pool.accP12PerShare;
  //         uint256 totalLpStaked = IERC20(pool.lpToken).balanceOf(
  //             address(this)
  //         );
  //         if (block.number > pool.lastRewardBlock && totalLpStaked != 0) {
  //             uint256 P12Reward = block
  //                 .number
  //                 .sub(pool.lastRewardBlock)
  //                 .mul(p12PerBlock)
  //                 .mul(pool.p12Total)
  //                 .div(totalBalanceOfP12);
  //             accP12PerShare = accP12PerShare.add(
  //                 DecimalMath.divFloor(P12Reward, pool.p12Total)
  //             );
  //         }
  //         totalReward = totalReward.add(
  //             DecimalMath.mul(user.amountOfP12, accP12PerShare).sub(
  //                 user.rewardDebt
  //             )
  //         );
  //     }
  //     return totalReward;
  // }

  // function getRealizedReward(address _user)
  //     external
  //     view
  //     virtual
  //     returns (uint256)
  // {
  //     return realizedReward[_user];
  // }

  function getDlpMiningSpeed(address _lpToken) external view virtual returns (uint256) {
    uint256 pid = getPid(_lpToken);
    PoolInfo storage pool = poolInfos[pid];
    return p12PerBlock.mul(pool.p12Total).div(totalBalanceOfP12);
  }

  // ============ Update Pools ============

  // Update reward variables for all pools. Be careful of gas spending!
  function massUpdatePools() public virtual {
    uint256 length = poolInfos.length;
    for (uint256 pid = 0; pid < length; ++pid) {
      updatePool(pid);
    }
  }

  // Update reward variables of the given pool to be up-to-date.
  function updatePool(uint256 _pid) public virtual {
    PoolInfo storage pool = poolInfos[_pid];
    if (block.number <= pool.lastRewardBlock) {
      return;
    }
    uint256 totalLpStaked = IERC20(pool.lpToken).balanceOf(address(this));
    if (totalLpStaked == 0) {
      pool.lastRewardBlock = block.number;
      return;
    }
    uint256 P12Reward = block.number.sub(pool.lastRewardBlock).mul(p12PerBlock).mul(pool.p12Total).div(totalBalanceOfP12);
    //pool.accP12PerShare = pool.accP12PerShare.add(DecimalMath.divFloor(P12Reward, pool.p12Total));
    pool.accP12PerShare = pool.accP12PerShare.add(P12Reward.mul(ONE).div(pool.p12Total));
    pool.lastRewardBlock = block.number;
  }

  // ============ Deposit & Withdraw & Claim ============
  // Deposit & withdraw will also trigger claim

  function deposit(address _lpToken, uint256 _amount) public virtual lock {
    uint256 pid = getPid(_lpToken);
    PoolInfo storage pool = poolInfos[pid];
    UserInfo storage user = userInfo[pid][msg.sender];
    updatePool(pid);
    if (user.amountOfLpToken > 0) {
      //uint256 pending = DecimalMath.mul(user.amountOfP12, pool.accP12PerShare).sub(user.rewardDebt);
      uint256 pending = user.amountOfP12.mul(pool.accP12PerShare).div(ONE).sub(user.rewardDebt);
      safeP12Transfer(msg.sender, pending);
    }
    IERC20(pool.lpToken).safeTransferFrom(address(msg.sender), address(this), _amount);
    totalLpStakedOfEachPool[_lpToken] += _amount;
    user.amountOfLpToken = user.amountOfLpToken.add(_amount);
    uint256 _amountOfP12 = calculateP12AmountByLpToken(_lpToken, _amount);
    pool.p12Total = pool.p12Total.add(_amountOfP12);
    user.amountOfP12 = user.amountOfP12.add(_amountOfP12);
    totalBalanceOfP12 = totalBalanceOfP12.add(_amountOfP12);
    //user.rewardDebt = DecimalMath.mul(user.amountOfP12, pool.accP12PerShare);
    user.rewardDebt = user.amountOfP12.mul(pool.accP12PerShare).div(ONE);
    emit Deposit(msg.sender, pid, _amount);
  }

  function withdrawDelay(address _lpToken, uint256 _amount) public virtual lock {
    uint256 pid = getPid(_lpToken);
    PoolInfo storage pool = poolInfos[pid];
    UserInfo storage user = userInfo[pid][msg.sender];
    require(user.amountOfLpToken >= _amount, 'P12Mine: withdraw too much');
    updatePool(pid);
    if (user.amountOfLpToken > 0) {
      //uint256 pending = DecimalMath.mul(user.amountOfP12, pool.accP12PerShare).sub(user.rewardDebt);
      uint256 pending = user.amountOfP12.mul(pool.accP12PerShare).div(ONE).sub(user.rewardDebt);
      safeP12Transfer(msg.sender, pending);
    }
    uint256 time;
    uint256 currentTimestamp = block.timestamp;
    bytes32 _preWithdrawId = preWithdrawIds[_lpToken];
    uint256 lastUnlockTimestamp = withdrawInfos[_lpToken][_preWithdrawId].unlockTimestamp;

    time = currentTimestamp >= lastUnlockTimestamp ? currentTimestamp : lastUnlockTimestamp;
    uint256 delay = _amount.mul(delayK).div(IERC20(pool.lpToken).totalSupply()) + delayB;
    uint256 unlockTimestamp = delay + time;

    bytes32 newWithdrawId = createWithdrawId(_lpToken, _amount, msg.sender);
    withdrawInfos[_lpToken][newWithdrawId] = WithdrawInfo(_amount, unlockTimestamp, false);
    //user.rewardDebt = DecimalMath.mul(user.amountOfP12, pool.accP12PerShare);
    user.rewardDebt = user.amountOfP12.mul(pool.accP12PerShare).div(ONE);
    emit WithdrawDelay(msg.sender, pid, _amount, newWithdrawId);
  }

  // function withdrawAll(address _lpToken) public virtual {
  //     uint256 balance = getUserLpBalance(_lpToken, msg.sender);
  //     withdraw(_lpToken, balance);
  // }

  // Withdraw without caring about rewards. EMERGENCY ONLY.
  // function emergencyWithdraw(address _lpToken) public {
  //     uint256 pid = getPid(_lpToken);
  //     PoolInfo storage pool = poolInfos[pid];
  //     UserInfo storage user = userInfo[pid][msg.sender];
  //     IERC20(pool.lpToken).safeTransfer(address(msg.sender), user.amount);
  //     user.amount = 0;
  //     user.rewardDebt = 0;
  // }

  function claim(address _lpToken) public virtual lock {
    uint256 pid = getPid(_lpToken);
    if (userInfo[pid][msg.sender].amountOfLpToken == 0 || poolInfos[pid].p12Total == 0) {
      return; // save gas
    }
    PoolInfo storage pool = poolInfos[pid];
    UserInfo storage user = userInfo[pid][msg.sender];
    updatePool(pid);
    // uint256 pending = DecimalMath.mul(user.amountOfP12, pool.accP12PerShare).sub(user.rewardDebt);
    uint256 pending = user.amountOfP12.mul(pool.accP12PerShare).div(ONE).sub(user.rewardDebt);
    //user.rewardDebt = DecimalMath.mul(user.amountOfP12, pool.accP12PerShare);
    user.rewardDebt = user.amountOfP12.mul(pool.accP12PerShare).div(ONE);
    safeP12Transfer(msg.sender, pending);
  }

  function claimAll() public virtual lock {
    uint256 length = poolInfos.length;
    uint256 pending = 0;
    for (uint256 pid = 0; pid < length; ++pid) {
      if (userInfo[pid][msg.sender].amountOfLpToken == 0 || poolInfos[pid].p12Total == 0) {
        continue; // save gas
      }
      PoolInfo storage pool = poolInfos[pid];
      UserInfo storage user = userInfo[pid][msg.sender];
      updatePool(pid);
      //pending = pending.add(DecimalMath.mul(user.amountOfP12, pool.accP12PerShare).sub(user.rewardDebt));
      pending = pending.add(user.amountOfP12.mul(pool.accP12PerShare).div(ONE).sub(user.rewardDebt));
      //user.rewardDebt = DecimalMath.mul(user.amountOfP12, pool.accP12PerShare);
      user.rewardDebt = user.amountOfP12.mul(pool.accP12PerShare).div(ONE);
    }
    safeP12Transfer(msg.sender, pending);
  }

  // Safe P12 transfer function
  function safeP12Transfer(address _to, uint256 _amount) internal virtual {
    IP12RewardVault(p12RewardVault).reward(_to, _amount);
    realizedReward[_to] = realizedReward[_to].add(_amount);
    emit Claim(_to, _amount);
  }

  //  get back lpToken
  function withdraw(
    address pledger,
    address _lpToken,
    bytes32 id
  ) public virtual lock {
    uint256 pid = getPid(_lpToken);
    PoolInfo storage pool = poolInfos[pid];
    UserInfo storage user = userInfo[pid][pledger];
    require(
      withdrawInfos[_lpToken][id].amount <= user.amountOfLpToken &&
        block.timestamp >= withdrawInfos[_lpToken][id].unlockTimestamp &&
        withdrawInfos[_lpToken][id].executed == false,
      'P12Mine: Withdraw condition not met'
    );
    withdrawInfos[_lpToken][id].executed = true;
    updatePool(pid);
    //uint256 pending = DecimalMath.mul(user.amountOfP12, pool.accP12PerShare).sub(user.rewardDebt);
    uint256 pending = user.amountOfP12.mul(pool.accP12PerShare).div(ONE).sub(user.rewardDebt);
    safeP12Transfer(pledger, pending);
    uint256 _amount = withdrawInfos[_lpToken][id].amount;
    user.amountOfLpToken = user.amountOfLpToken.sub(_amount);

    uint256 _amountOfP12 = calculateP12AmountByLpToken(_lpToken, _amount);
    pool.p12Total = pool.p12Total.sub(_amountOfP12);
    user.amountOfP12 = user.amountOfP12.sub(_amountOfP12);
    totalBalanceOfP12 = totalBalanceOfP12.sub(_amountOfP12);

    //user.rewardDebt = DecimalMath.mul(user.amountOfP12, pool.accP12PerShare);
    user.rewardDebt = user.amountOfP12.mul(pool.accP12PerShare).div(ONE);
    totalLpStakedOfEachPool[_lpToken] -= _amount;
    IERC20(pool.lpToken).safeTransfer(address(pledger), _amount);
    emit Withdraw(pledger, pid, _amount);
  }
}
