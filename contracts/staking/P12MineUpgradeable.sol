// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.15;
import '@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol';
import '@openzeppelin/contracts/utils/math/SafeMath.sol';
import '@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol';
import '@openzeppelin/contracts/utils/math/Math.sol';
import '@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol';
import '../access/SafeOwnableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol';
import { IP12RewardVault, P12RewardVault } from './P12RewardVault.sol';
import './interfaces/IGaugeController.sol';
import './interfaces/IP12MineUpgradeable.sol';
import './P12MineStorage.sol';
import '../access/SafeOwnableUpgradeable.sol';
import '../token/interfaces/IP12Token.sol';

contract P12MineUpgradeable is
  P12MineStorage,
  IP12MineUpgradeable,
  UUPSUpgradeable,
  SafeOwnableUpgradeable,
  ReentrancyGuardUpgradeable,
  PausableUpgradeable
{
  using SafeERC20Upgradeable for IERC20Upgradeable;
  using Math for uint256;

  uint256 public constant ONE = 10**18;
  uint256 public constant WEEK = 7 * 86400;

  // ============ External ============

  /**
  @notice set new p12Factory
  @param newP12Factory address of p12Factory
   */
  function setP12Factory(address newP12Factory) external virtual override onlyOwner {
    address oldP12Factory = p12Factory;
    require(newP12Factory != address(0), 'P12Mine: p12Factory cannot be 0');
    p12Factory = newP12Factory;
    emit SetP12Factory(oldP12Factory, newP12Factory);
  }

  /**
  @notice set new gaugeController
  @param newGaugeController address of gaugeController
   */
  function setGaugeController(IGaugeController newGaugeController) external virtual override onlyOwner {
    IGaugeController oldGaugeController = gaugeController;
    require(address(newGaugeController) != address(0), 'P12Mine: gc cannot be zero');
    gaugeController = newGaugeController;
    emit SetGaugeController(oldGaugeController, newGaugeController);
  }

  /**
    @notice Get pool len
   */
  function poolLength() external view virtual override returns (uint256) {
    return poolInfos.length;
  }

  /**
​    @notice withdraw token Emergency
  */
  function withdrawEmergency() external virtual override onlyOwner {
    p12RewardVault.withdrawEmergency(msg.sender);
  }

  // ============ Public ============

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
    @param gaugeController_ address of gaugeController
    @param delayK_ delayK_ is a coefficient
    @param delayB_ delayB_ is a coefficient
   */
  function initialize(
    address p12Token_,
    address p12Factory_,
    IGaugeController gaugeController_,
    uint256 delayK_,
    uint256 delayB_,
    uint256 rate_
  ) public initializer {
    require(p12Token_ != address(0), 'P12Mine: p12Token cannot be 0');
    require(p12Factory_ != address(0), 'P12Mine: p12Factory cannot be 0');

    p12Token = p12Token_;
    p12Factory = p12Factory_;
    gaugeController = IGaugeController(gaugeController_);
    p12RewardVault = IP12RewardVault(new P12RewardVault(p12Token_));
    delayK = delayK_;
    delayB = delayB_;
    rate = rate_;

    __ReentrancyGuard_init_unchained();
    __Pausable_init_unchained();
    __Ownable_init_unchained();
  }

  /**
    @notice get withdraw unlockTimestamp
    @param lpToken Address of lpToken
    @param amount Number of lpToken
   */
  function getWithdrawUnlockTimestamp(address lpToken, uint256 amount) public view virtual override returns (uint256) {
    uint256 pid = getPid(lpToken);
    PoolInfo memory pool = poolInfos[pid];
    uint256 time;
    uint256 currentTimestamp = block.timestamp;
    bytes32 _preWithdrawId = preWithdrawIds[lpToken];
    uint256 lastUnlockTimestamp = withdrawInfos[lpToken][_preWithdrawId].unlockTimestamp;

    time = currentTimestamp >= lastUnlockTimestamp ? currentTimestamp : lastUnlockTimestamp;
    uint256 delay = (amount * delayK) / IERC20Upgradeable(pool.lpToken).totalSupply() + delayB;
    uint256 unlockTimestamp = delay + time;
    return unlockTimestamp;
  }

  /**
    @notice Get pool id
    @param lpToken Address of lpToken
   */
  function getPid(address lpToken) public view virtual override lpTokenExist(lpToken) returns (uint256) {
    return lpTokenRegistry[lpToken] - 1;
  }

  /**
    @notice Get user lpToken balance
    @param lpToken Address of lpToken
    @param user LpToken holder
    @return Get lpToken balance 
   */
  function getUserLpBalance(address lpToken, address user) public view virtual override returns (uint256) {
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
    createPool(lpToken);
    uint256 pid = getPid(lpToken);
    uint256 totalLpStaked = IERC20Upgradeable(lpToken).balanceOf(address(this));
    PoolInfo storage pool = poolInfos[pid];
    UserInfo storage user = userInfo[pid][gameCoinCreator];
    require(amount <= totalLpStaked - pool.amount && amount > 0, 'P12Mine: amount not met');
    pool.period += 1;
    periodTimestamp[pool.lpToken][pool.period] = block.timestamp;
    user.amount += amount;
    pool.amount += amount;
    user.rewardDebt = (user.amount * pool.accP12PerShare) / ONE;
    emit Deposit(gameCoinCreator, pid, amount, user.amount, pool.amount);
  }

  // ============ Ownable ============

  /**
    @notice set the isEmergency status
  */
  function setEmergency(bool emergencyStatus) public virtual override onlyOwner {
    require(isEmergency != emergencyStatus, 'P12Mine: already exists');
    isEmergency = emergencyStatus;
    emit SetEmergency(emergencyStatus);
  }

  /**
    @notice Create a new pool
    @param lpToken Address of lpToken
   */
  function createPool(address lpToken) public virtual override lpTokenNotExist(lpToken) whenNotPaused onlyP12FactoryOrOwner {
    poolInfos.push(PoolInfo({ lpToken: lpToken, accP12PerShare: 0, amount: 0, period: 0 }));
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

  /**
    @notice set new rate
    @param newRate is p12 token inflation rate 
   */
  function setRate(uint256 newRate) public virtual override onlyOwner returns (bool) {
    uint256 oldRate = rate;
    rate = newRate;
    checkpointAll();
    emit SetRate(oldRate, newRate);
    return true;
  }

  function checkpoint(address lpToken) external {
    uint256 pid = getPid(lpToken);
    _checkpoint(pid);
  }

  /**
    @notice update checkpoint for all pool
   */
  function checkpointAll() public virtual override {
    uint256 length = poolInfos.length;
    for (uint256 pid = 0; pid < length; pid++) {
      _checkpoint(pid);
    }
  }

  // ============ Deposit & Withdraw & Claim & ============
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
    if (user.amount > 0) {
      uint256 pending = (user.amount * pool.accP12PerShare) / ONE - user.rewardDebt;
      _safeP12Transfer(msg.sender, pending);
    }
    require(amount != 0, 'P12Mine: need amount > 0');
    user.amount += amount;
    pool.amount += amount;
    IERC20Upgradeable(pool.lpToken).safeTransferFrom(msg.sender, address(this), amount);
    user.rewardDebt = (user.amount * pool.accP12PerShare) / ONE;
    emit Deposit(msg.sender, pid, amount, user.amount, pool.amount);
  }

  /**
  @notice Withdraw lpToken delay
  @param lpToken Address of lpToken
  @param amount Number of lpToken
  */
  function queueWithdraw(address lpToken, uint256 amount) public virtual override whenNotPaused nonReentrant {
    uint256 pid = getPid(lpToken);
    PoolInfo memory pool = poolInfos[pid];
    UserInfo memory user = userInfo[pid][msg.sender];
    require(user.amount >= amount, 'P12Mine: withdraw too much');
    _checkpoint(pid);
    if (user.amount > 0) {
      uint256 pending = (user.amount * pool.accP12PerShare) / ONE - user.rewardDebt;
      _safeP12Transfer(msg.sender, pending);
    }
    uint256 unlockTimestamp = getWithdrawUnlockTimestamp(lpToken, amount);
    bytes32 newWithdrawId = _createWithdrawId(lpToken, amount, msg.sender);
    withdrawInfos[lpToken][newWithdrawId] = WithdrawInfo(msg.sender, amount, unlockTimestamp, false);
    user.rewardDebt = (user.amount * pool.accP12PerShare) / ONE;
    emit QueueWithdraw(msg.sender, pid, amount, newWithdrawId, unlockTimestamp);
  }

  /**
    @notice Get pending rewards
    @param lpToken Address of lpToken
   */
  function claim(address lpToken) public virtual override nonReentrant whenNotPaused {
    uint256 pid = getPid(lpToken);
    require(userInfo[pid][msg.sender].amount > 0, 'P12Mine: no staked token');
    PoolInfo storage pool = poolInfos[pid];
    UserInfo storage user = userInfo[pid][msg.sender];
    _checkpoint(pid);
    uint256 pending = (user.amount * pool.accP12PerShare) / ONE - user.rewardDebt;
    user.rewardDebt = (user.amount * pool.accP12PerShare) / ONE;
    _safeP12Transfer(msg.sender, pending);
  }

  /**
    @notice Get all pending rewards
   */
  function claimAll() public virtual override nonReentrant whenNotPaused {
    uint256 length = poolInfos.length;
    uint256 pending = 0;
    for (uint256 pid = 0; pid < length; pid++) {
      if (userInfo[pid][msg.sender].amount == 0) {
        continue; // save gas
      }
      PoolInfo storage pool = poolInfos[pid];
      UserInfo storage user = userInfo[pid][msg.sender];
      _checkpoint(pid);
      pending += (user.amount * pool.accP12PerShare) / ONE - user.rewardDebt;
      user.rewardDebt = (user.amount * pool.accP12PerShare) / ONE;
    }
    _safeP12Transfer(msg.sender, pending);
  }

  /**
    @notice Withdraw lpToken
    @param lpToken Address of lpToken
    @param id Withdraw id 
   */
  function executeWithdraw(address lpToken, bytes32 id) public virtual override nonReentrant whenNotPaused {
    uint256 pid = getPid(lpToken);
    address _who = withdrawInfos[lpToken][id].who;
    require(msg.sender == _who, 'P12Mine: caller not token owner');
    PoolInfo storage pool = poolInfos[pid];
    UserInfo storage user = userInfo[pid][_who];
    require(withdrawInfos[lpToken][id].amount <= user.amount, 'P12Mine: withdraw too much');
    require(block.timestamp >= withdrawInfos[lpToken][id].unlockTimestamp, 'P12Mine: unlock time not reached');
    require(!withdrawInfos[lpToken][id].executed, 'P12Mine: already withdrawn');
    withdrawInfos[lpToken][id].executed = true;
    _checkpoint(pid);
    uint256 pending = (user.amount * pool.accP12PerShare) / ONE - user.rewardDebt;
    _safeP12Transfer(_who, pending);
    uint256 amount = withdrawInfos[lpToken][id].amount;
    user.amount -= amount;
    pool.amount -= amount;
    user.rewardDebt = (user.amount * pool.accP12PerShare) / ONE;
    IERC20Upgradeable(pool.lpToken).safeTransfer(address(_who), amount);
    emit ExecuteWithdraw(_who, pid, amount, user.amount, pool.amount);
  }

  /**
​    @notice withdraw lpToken Emergency
  */

  function withdrawAllLpTokenEmergency() public virtual override onlyEmergency {
    uint256 length = poolInfos.length;

    for (uint256 pid = 0; pid < length; pid++) {
      if (userInfo[pid][msg.sender].amount == 0) {
        continue; // save gas
      }
      PoolInfo memory pool = poolInfos[pid];
      withdrawLpTokenEmergency(pool.lpToken);
    }
  }

  /**
​    @notice withdraw all lpToken Emergency
    @param lpToken address of lpToken
  */
  function withdrawLpTokenEmergency(address lpToken) public virtual override onlyEmergency {
    uint256 pid = getPid(lpToken);
    PoolInfo storage pool = poolInfos[pid];
    UserInfo storage user = userInfo[pid][msg.sender];
    require(user.amount > 0, 'P12Mine: without any lpToken');
    IERC20Upgradeable(pool.lpToken).safeTransfer(address(msg.sender), user.amount);
    uint256 amount = user.amount;
    user.amount = 0;
    user.rewardDebt = 0;
    emit WithdrawLpTokenEmergency(lpToken, amount);
  }

  // ============ Internal ============

  function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

  /**
    @notice Transfer p12 to user
    @param  to The address of receiver
    @param amount Number of p12
   */
  function _safeP12Transfer(address to, uint256 amount) internal virtual {
    p12RewardVault.reward(to, amount);
    realizedReward[to] = realizedReward[to] + amount;
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

  // ============ checkpoint ============
  /**
      @notice update checkpoint for pool
      @param pid Pool Id
  */
  function _checkpoint(uint256 pid) internal virtual whenNotPaused {
    PoolInfo storage pool = poolInfos[pid];
    uint256 _accP12PerShare = pool.accP12PerShare;
    uint256 _periodTime = periodTimestamp[pool.lpToken][pool.period];
    gaugeController.checkpointGauge(address(pool.lpToken));
    require(block.timestamp > _periodTime, 'P12Mine: not time to check');
    if (pool.amount == 0) {
      pool.period += 1;
      periodTimestamp[pool.lpToken][pool.period] = block.timestamp;
      return;
    }
    uint256 prevWeekTime = _periodTime;
    uint256 weekTime = Math.min(((_periodTime + WEEK) / WEEK) * WEEK, block.timestamp);
    for (uint256 i = 0; i < 500; i++) {
      uint256 dt = weekTime - prevWeekTime;
      uint256 w = gaugeController.gaugeRelativeWeight(pool.lpToken, (prevWeekTime / WEEK) * WEEK);
      _accP12PerShare += (rate * w * dt) / pool.amount;
      if (weekTime == block.timestamp) {
        break;
      }
      prevWeekTime = weekTime;
      weekTime = Math.min(weekTime + WEEK, block.timestamp);
    }
    pool.accP12PerShare = _accP12PerShare;
    pool.period += 1;
    periodTimestamp[pool.lpToken][pool.period] = block.timestamp;
    emit Checkpoint(pool.lpToken, pool.amount, pool.accP12PerShare);
  }

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
    require(msg.sender == address(p12Factory) || msg.sender == owner(), 'P12Mine: not p12factory or owner');
    _;
  }

  // check the caller
  modifier onlyP12Factory() {
    require(msg.sender == address(p12Factory), 'P12Mine: caller not p12factory');
    _;
  }

  // check Emergency
  modifier onlyEmergency() {
    require(isEmergency, 'P12Mine: no emergency now');
    _;
  }
}
