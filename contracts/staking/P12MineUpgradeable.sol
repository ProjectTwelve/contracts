// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.13;
import '@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol';
import '@openzeppelin/contracts/utils/math/SafeMath.sol';
import '@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol';
import '@openzeppelin/contracts/utils/math/Math.sol';
import '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';
import '@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol';

import { IP12RewardVault, P12RewardVault } from './P12RewardVault.sol';
import './interfaces/IGaugeController.sol';
import './interfaces/IP12MineUpgradeable.sol';
import './P12MineStorage.sol';

contract P12MineUpgradeable is
  P12MineStorage,
  IP12MineUpgradeable,
  Initializable,
  UUPSUpgradeable,
  OwnableUpgradeable,
  ReentrancyGuardUpgradeable,
  PausableUpgradeable
{
  using SafeMath for uint256;
  using SafeERC20Upgradeable for IERC20Upgradeable;
  using Math for uint256;

  uint256 public constant ONE = 10**18;
  uint256 public constant BOOST_WARMUP = 2 * 7 * 86400;
  uint256 public constant WEEK = 7 * 86400;
  uint256 public constant TOKENLESS_PRODUCTION = 40;
  uint256 public constant YEAR = 365 * 86400;
  uint256 public constant RATE = (200000000 * ONE) / YEAR;

  function pause() public onlyOwner {
    _pause();
  }

  function unpause() public onlyOwner {
    _unpause();
  }

  /**
    @notice Contract initialization
    @param p12Token_ Address of p12Token
    @param p12Factory_ Address of p12Factory
    @param controller_ address of gaugeController
    @param votingEscrow_ address of votingEscrow
    @param delayK_ delayK_ is a coefficient
    @param delayB_ delayB_ is a coefficient
   */
  function initialize(
    address p12Token_,
    address p12Factory_,
    address controller_,
    address votingEscrow_,
    uint256 delayK_,
    uint256 delayB_
  ) public initializer {
    p12Token = p12Token_;
    p12Factory = p12Factory_;
    controller = controller_;
    votingEscrow = votingEscrow_;
    p12RewardVault = address(new P12RewardVault(p12Token_));
    delayK = delayK_;
    delayB = delayB_;

    __ReentrancyGuard_init_unchained();
    __Pausable_init_unchained();
    __Ownable_init_unchained();
  }

  function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

  // ============ Modifiers ============

  // check if lpToken exists
  modifier lpTokenExist(address lpToken) {
    require(lpTokenRegistry[lpToken] > 0, 'P12Mine: LP Token Not Exist');
    _;
  }
  // check if lpToken exists
  modifier lpTokenNotExist(address lpToken) {
    require(lpTokenRegistry[lpToken] == 0, 'P12Mine: LP Token Already Exist');
    _;
  }

  // check the caller
  modifier onlyP12FactoryOrOwner() {
    require(msg.sender == p12Factory || msg.sender == owner(), 'P12Mine: not p12factory or owner');
    _;
  }

  // check the caller
  modifier onlyP12Factory() {
    require(msg.sender == p12Factory, 'P12Mine: caller not p12factory');
    _;
  }

  // ============ Helper ============

  /**
    @notice Get pool len
   */
  function poolLength() external view virtual returns (uint256) {
    return poolInfos.length;
  }

  /**
    @notice Get pool id
    @param lpToken Address of lpToken
   */
  function getPid(address lpToken) public view virtual lpTokenExist(lpToken) returns (uint256) {
    return lpTokenRegistry[lpToken] - 1;
  }

  /**
    @notice Get user lpToken balance
    @param lpToken Address of lpToken
    @param user LpToken holder
    @return Get lpToken balance 
   */
  function getUserLpBalance(address lpToken, address user) public view virtual returns (uint256) {
    uint256 pid = getPid(lpToken);
    return userInfo[pid][user].amount;
  }

  /**
    @notice This method is only used when creating game coin in p12factory
    @param lpToken Address of lpToken
    @param gameCoinCreator user of game coin creator
   */
  function addLpTokenInfoForGameCreator(
    address lpToken,
    uint256 amount,
    address gameCoinCreator
  ) public virtual override whenNotPaused onlyP12Factory {
    uint256 pid = getPid(lpToken);
    uint256 totalLpStaked = IERC20Upgradeable(lpToken).balanceOf(address(this));
    PoolInfo storage pool = poolInfos[pid];
    UserInfo storage user = userInfo[pid][gameCoinCreator];
    require(amount <= totalLpStaked - pool.amount, 'P12Mine: value should <= totalLpStaked - pool.amount');
    _checkpoint(pid);
    if (user.workingAmount > 0) {
      uint256 pending = user.workingAmount.mul(pool.accP12PerShare).div(ONE).sub(user.rewardDebt);
      _safeP12Transfer(msg.sender, pending);
    }
    if (amount != 0) {
      user.amount += amount;
      pool.amount += amount;
      uint256 balance = IERC20Upgradeable(lpToken).balanceOf(address(this)) + amount;
      _updateLiquidityLimit(pid, user.amount, balance);
    }
    user.rewardDebt = user.workingAmount.mul(pool.accP12PerShare).div(ONE);
    emit Deposit(gameCoinCreator, pid, amount);
  }

  // ============ Ownable ============

  /**
    @notice Create a new pool
    @param lpToken Address of lpToken
   */
  function createPool(address lpToken) public virtual override lpTokenNotExist(lpToken) whenNotPaused onlyP12FactoryOrOwner {
    poolInfos.push(PoolInfo({ lpToken: lpToken, accP12PerShare: 0, workingAmount: 0, amount: 0, period: 0 }));
    periodTimestamp[lpToken][0] = block.timestamp;
    lpTokenRegistry[lpToken] = poolInfos.length;
  }

  /**
    @notice Set delayK value 
    @param newDelayK Is a coefficient
    @return Get bool result 
   */
  function setDelayK(uint256 newDelayK) public virtual override onlyOwner returns (bool) {
    uint256 oldDelayK = delayK;
    delayK = newDelayK;
    emit SetDelayK(oldDelayK, delayK);
    return true;
  }

  /**
    @notice Set delayB value 
    @param newDelayB Is a coefficient
    @return Get bool result 
   */
  function setDelayB(uint256 newDelayB) public virtual override onlyOwner returns (bool) {
    uint256 oldDelayB = delayB;
    delayB = newDelayB;
    emit SetDelayB(oldDelayB, delayB);
    return true;
  }

  // ============ checkpoint ============
  /**
      @param lpToken address of lpToken
      @return bool success
     */
  function userCheckpoint(address lpToken) external virtual returns (bool) {
    uint256 pid = getPid(lpToken);
    PoolInfo storage pool = poolInfos[pid];
    UserInfo storage user = userInfo[pid][msg.sender];
    _checkpoint(pid);
    _updateLiquidityLimit(pid, user.amount, pool.amount);
    return true;
  }

  // ============ Deposit & Withdraw & Claim ============
  // Deposit & withdraw will also trigger claim

  /**
    @notice Deposit lpToken
    @param lpToken Address of lpToken
    @param amount Number of lpToken
   */
  function deposit(address lpToken, uint256 amount) public virtual override whenNotPaused nonReentrant {
    uint256 pid = getPid(lpToken);
    PoolInfo storage pool = poolInfos[pid];
    UserInfo storage user = userInfo[pid][msg.sender];

    _checkpoint(pid);
    if (user.workingAmount > 0) {
      uint256 pending = user.workingAmount.mul(pool.accP12PerShare).div(ONE).sub(user.rewardDebt);
      _safeP12Transfer(msg.sender, pending);
    }
    if (amount != 0) {
      user.amount += amount;
      pool.amount += amount;
      _updateLiquidityLimit(pid, user.amount, pool.amount);
      IERC20Upgradeable(pool.lpToken).safeTransferFrom(msg.sender, address(this), amount);
    }
    user.rewardDebt = user.workingAmount.mul(pool.accP12PerShare).div(ONE);
    emit Deposit(msg.sender, pid, amount);
  }

  /**
  @notice Withdraw lpToken delay
  @param lpToken Address of lpToken
  @param amount Number of lpToken
  */
  function withdrawDelay(address lpToken, uint256 amount) public virtual override whenNotPaused nonReentrant {
    uint256 pid = getPid(lpToken);
    PoolInfo storage pool = poolInfos[pid];
    UserInfo storage user = userInfo[pid][msg.sender];
    require(user.amount >= amount, 'P12Mine: withdraw too much');
    _checkpoint(pid);
    if (user.workingAmount > 0) {
      uint256 pending = user.amount.mul(pool.accP12PerShare).div(ONE).sub(user.rewardDebt);
      _safeP12Transfer(msg.sender, pending);
    }
    uint256 time;
    uint256 currentTimestamp = block.timestamp;
    bytes32 _preWithdrawId = preWithdrawIds[lpToken];
    uint256 lastUnlockTimestamp = withdrawInfos[lpToken][_preWithdrawId].unlockTimestamp;

    time = currentTimestamp >= lastUnlockTimestamp ? currentTimestamp : lastUnlockTimestamp;
    uint256 delay = amount.mul(delayK).div(IERC20Upgradeable(pool.lpToken).totalSupply()) + delayB;
    uint256 unlockTimestamp = delay + time;

    bytes32 newWithdrawId = _createWithdrawId(lpToken, amount, msg.sender);
    withdrawInfos[lpToken][newWithdrawId] = WithdrawInfo(amount, unlockTimestamp, false);
    user.rewardDebt = user.workingAmount.mul(pool.accP12PerShare).div(ONE);
    emit WithdrawDelay(msg.sender, pid, amount, newWithdrawId);
  }

  /**
    @notice Get pending rewards
    @param lpToken Address of lpToken
   */
  function claim(address lpToken) public virtual override nonReentrant whenNotPaused {
    uint256 pid = getPid(lpToken);
    if (userInfo[pid][msg.sender].workingAmount == 0) {
      return; // save gas
    }
    PoolInfo storage pool = poolInfos[pid];
    UserInfo storage user = userInfo[pid][msg.sender];
    _checkpoint(pid);
    uint256 pending = user.workingAmount.mul(pool.accP12PerShare).div(ONE).sub(user.rewardDebt);
    user.rewardDebt = user.workingAmount.mul(pool.accP12PerShare).div(ONE);
    _safeP12Transfer(msg.sender, pending);
  }

  /**
    @notice Get all pending rewards
   */
  function claimAll() public virtual override nonReentrant whenNotPaused {
    uint256 length = poolInfos.length;
    uint256 pending = 0;
    for (uint256 pid = 0; pid < length; ++pid) {
      if (userInfo[pid][msg.sender].workingAmount == 0) {
        continue; // save gas
      }
      PoolInfo storage pool = poolInfos[pid];
      UserInfo storage user = userInfo[pid][msg.sender];
      _checkpoint(pid);
      pending = pending.add(user.workingAmount.mul(pool.accP12PerShare).div(ONE).sub(user.rewardDebt));
      user.rewardDebt = user.workingAmount.mul(pool.accP12PerShare).div(ONE);
    }
    _safeP12Transfer(msg.sender, pending);
  }

  /**
    @notice Withdraw lpToken
    @param pledger Holder of lpToken
    @param lpToken Address of lpToken
    @param id Withdraw id 
   */
  function withdraw(
    address pledger,
    address lpToken,
    bytes32 id
  ) public virtual override nonReentrant whenNotPaused {
    uint256 pid = getPid(lpToken);
    PoolInfo storage pool = poolInfos[pid];
    UserInfo storage user = userInfo[pid][pledger];
    require(
      withdrawInfos[lpToken][id].amount <= user.amount &&
        block.timestamp >= withdrawInfos[lpToken][id].unlockTimestamp &&
        !withdrawInfos[lpToken][id].executed,
      'P12Mine: can not withdraw'
    );
    withdrawInfos[lpToken][id].executed = true;
    _checkpoint(pid);
    uint256 pending = user.workingAmount.mul(pool.accP12PerShare).div(ONE).sub(user.rewardDebt);
    _safeP12Transfer(pledger, pending);
    uint256 amount = withdrawInfos[lpToken][id].amount;
    user.amount -= amount;
    pool.amount -= amount;
    _updateLiquidityLimit(pid, user.amount, pool.amount);
    IERC20Upgradeable(pool.lpToken).safeTransfer(address(pledger), amount);
    emit Withdraw(pledger, pid, amount);
  }

  // ============ Internal ============

  /**
      @notice Checkpoint for a user
      @param pid Pool Id
  */
  function _checkpoint(uint256 pid) internal virtual {
    PoolInfo storage pool = poolInfos[pid];
    uint256 _accP12PerShare = pool.accP12PerShare;
    uint256 _workingTotalAmount = pool.workingAmount;
    uint256 _periodTime = periodTimestamp[pool.lpToken][pool.period];
    IGaugeController(controller).checkpointGauge(address(pool.lpToken));

    if (block.timestamp > _periodTime) {
      uint256 prevWeekTime = _periodTime;
      uint256 weekTime = Math.min(((_periodTime + WEEK) / WEEK) * WEEK, block.timestamp);
      for (uint256 i = 0; i < 500; i++) {
        uint256 dt = weekTime - prevWeekTime;
        uint256 w = IGaugeController(controller).gaugeRelativeWeight(pool.lpToken, (prevWeekTime / WEEK) * WEEK);
        if (_workingTotalAmount > 0) {
          _accP12PerShare += (RATE * w * dt) / _workingTotalAmount;
        }
        if (weekTime == block.timestamp) {
          break;
        }
        prevWeekTime = weekTime;
        weekTime = Math.min(weekTime + WEEK, block.timestamp);
      }
    }

    pool.accP12PerShare = _accP12PerShare;
    pool.period += 1;
    periodTimestamp[pool.lpToken][pool.period] = block.timestamp;
  }

  /**
    @param pid pool id
    @param l User's amount of liquidity (LP tokens)
    @param L Total amount of liquidity (LP tokens)
   */
  function _updateLiquidityLimit(
    uint256 pid,
    uint256 l,
    uint256 L
  ) internal virtual {
    PoolInfo storage pool = poolInfos[pid];
    UserInfo storage user = userInfo[pid][msg.sender];

    // To be called after pool's lpToken is updated
    uint256 votingBalance = IERC20Upgradeable(votingEscrow).balanceOf(msg.sender);
    uint256 votingTotal = IERC20Upgradeable(votingEscrow).totalSupply();

    uint256 lim = (l * TOKENLESS_PRODUCTION) / 100;
    if (votingTotal > 0 && block.timestamp > (periodTimestamp[pool.lpToken][0] + BOOST_WARMUP)) {
      lim += (((L * votingBalance) / votingTotal) * (100 - TOKENLESS_PRODUCTION)) / 100;
    }
    lim = Math.min(l, lim);
    uint256 oldWorkingAmount = user.workingAmount;
    user.workingAmount = lim;
    pool.workingAmount = pool.workingAmount + lim - oldWorkingAmount;

    emit UpdateLiquidityLimit(msg.sender, l, L, lim, pool.workingAmount);
  }

  /**
    @notice Transfer p12 to user
    @param  to The address of receiver
    @param amount Number of p12
   */
  function _safeP12Transfer(address to, uint256 amount) internal virtual {
    IP12RewardVault(p12RewardVault).reward(to, amount);
    realizedReward[to] = realizedReward[to].add(amount);
    emit Claim(to, amount);
  }

  /**
    @notice Create withdraw id
    @param lpToken Address of lpToken
    @param amount Number of lpToken
    @param to Address of receiver
    @return hash Get a withdraw Id
   */
  function _createWithdrawId(
    address lpToken,
    uint256 amount,
    address to
  ) internal virtual returns (bytes32 hash) {
    bytes32 preWithdrawId = preWithdrawIds[lpToken];
    bytes32 withdrawId = keccak256(abi.encode(lpToken, amount, to, preWithdrawId));

    preWithdrawIds[lpToken] = withdrawId;

    return withdrawId;
  }
}
