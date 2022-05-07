// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;
import '@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol';
import '@openzeppelin/contracts/utils/math/SafeMath.sol';
import '@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol';
import { IP12RewardVault, P12RewardVault } from './P12RewardVault.sol';

import './interfaces/IP12MineUpgradeable.sol';

import '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';
import '@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol';

import './P12MineUpgradeableStorage.sol';

contract P12MineUpgradeable is
  P12MineUpgradeableStorage,
  IP12MineUpgradeable,
  Initializable,
  UUPSUpgradeable,
  OwnableUpgradeable,
  ReentrancyGuardUpgradeable,
  PausableUpgradeable
{
  using SafeMath for uint256;
  using SafeERC20Upgradeable for IERC20Upgradeable;

  function pause() public onlyOwner {
    _pause();
  }

  function unpause() public onlyOwner {
    _unpause();
  }

  // init
  function initialize(
    address _p12Token,
    address _p12Factory,
    uint256 _startBlock,
    uint256 _delayK,
    uint256 _delayB
  ) public initializer {
    p12Token = _p12Token;
    p12Factory = _p12Factory;
    p12RewardVault = address(new P12RewardVault(_p12Token));
    startBlock = _startBlock;
    delayK = _delayK;
    delayB = _delayB;

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

  // get pool len
  function poolLength() external view virtual returns (uint256) {
    return poolInfos.length;
  }

  // get pool id
  function getPid(address _lpToken) public view virtual lpTokenExist(_lpToken) returns (uint256) {
    return lpTokenRegistry[_lpToken] - 1;
  }

  // get user lpToken balance
  function getUserLpBalance(address _lpToken, address _user) public view virtual returns (uint256) {
    uint256 pid = getPid(_lpToken);
    return userInfo[pid][_user].amountOfLpToken;
  }

  // This method is only used when creating game coin in p12factory
  function addLpTokenInfoForGameCreator(address _lpToken, address gameCoinCreator)
    public
    virtual
    override
    whenNotPaused
    onlyP12Factory
  {
    uint256 pid = getPid(_lpToken);
    uint256 _totalLpStaked = totalLpStakedOfEachPool[_lpToken];
    uint256 totalLpStaked = IERC20Upgradeable(_lpToken).balanceOf(address(this));
    uint256 _amount = totalLpStaked.sub(_totalLpStaked);
    require(_amount > 0, 'P12Mine: _amount should > 0');
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
    user.rewardDebt = user.amountOfP12.mul(pool.accP12PerShare).div(ONE);
    emit Deposit(gameCoinCreator, pid, _amount);
  }

  // ============ Ownable ============

  // create a new pool
  function createPool(address _lpToken, bool _withUpdate)
    public
    virtual
    override
    lpTokenNotExist(_lpToken)
    whenNotPaused
    onlyP12FactoryOrOwner
  {
    if (_withUpdate) {
      massUpdatePools();
    }
    uint256 lastRewardBlock = block.number > startBlock ? block.number : startBlock;
    poolInfos.push(PoolInfo({ lpToken: _lpToken, p12Total: 0, lastRewardBlock: lastRewardBlock, accP12PerShare: 0 }));
    lpTokenRegistry[_lpToken] = poolInfos.length;
  }

  // set reward value for per block
  function setReward(uint256 _p12PerBlock, bool _withUpdate) external virtual override onlyOwner {
    if (_withUpdate) {
      massUpdatePools();
    }
    p12PerBlock = _p12PerBlock;
  }

  function setDelayK(uint256 _delayK) public virtual override onlyOwner returns (bool) {
    uint256 oldDelayK = delayK;
    delayK = _delayK;
    emit SetDelayK(oldDelayK, delayK);
    return true;
  }

  function setDelayB(uint256 _delayB) public virtual override onlyOwner returns (bool) {
    uint256 oldDelayB = delayB;
    delayB = _delayB;
    emit SetDelayB(oldDelayB, delayB);
    return true;
  }

  function getDlpMiningSpeed(address _lpToken) external view virtual override returns (uint256) {
    uint256 pid = getPid(_lpToken);
    PoolInfo storage pool = poolInfos[pid];
    return p12PerBlock.mul(pool.p12Total).div(totalBalanceOfP12);
  }

  // ============ Update Pools ============

  // Update reward variables for all pools. Be careful of gas spending!
  function massUpdatePools() public virtual override whenNotPaused {
    uint256 length = poolInfos.length;
    for (uint256 pid = 0; pid < length; ++pid) {
      updatePool(pid);
    }
  }

  // Update reward variables of the given pool to be up-to-date.
  function updatePool(uint256 _pid) public virtual override whenNotPaused {
    PoolInfo storage pool = poolInfos[_pid];
    if (block.number <= pool.lastRewardBlock) {
      return;
    }
    uint256 totalLpStaked = IERC20Upgradeable(pool.lpToken).balanceOf(address(this));
    if (totalLpStaked == 0) {
      pool.lastRewardBlock = block.number;
      return;
    }
    uint256 P12Reward = block.number.sub(pool.lastRewardBlock).mul(p12PerBlock).mul(pool.p12Total).div(totalBalanceOfP12);
    pool.accP12PerShare = pool.accP12PerShare.add(P12Reward.mul(ONE).div(pool.p12Total));
    pool.lastRewardBlock = block.number;
    emit UpdatePool(_pid, pool.lpToken, pool.accP12PerShare);
  }

  // ============ Deposit & Withdraw & Claim ============
  // Deposit & withdraw will also trigger claim

  // deposit lpToken
  function deposit(address _lpToken, uint256 _amount) public virtual override whenNotPaused nonReentrant {
    uint256 pid = getPid(_lpToken);
    PoolInfo storage pool = poolInfos[pid];
    UserInfo storage user = userInfo[pid][msg.sender];
    updatePool(pid);
    if (user.amountOfLpToken > 0) {
      uint256 pending = user.amountOfP12.mul(pool.accP12PerShare).div(ONE).sub(user.rewardDebt);
      safeP12Transfer(msg.sender, pending);
    }
    IERC20Upgradeable(pool.lpToken).safeTransferFrom(address(msg.sender), address(this), _amount);
    totalLpStakedOfEachPool[_lpToken] += _amount;
    user.amountOfLpToken = user.amountOfLpToken.add(_amount);
    uint256 _amountOfP12 = calculateP12AmountByLpToken(_lpToken, _amount);
    pool.p12Total = pool.p12Total.add(_amountOfP12);
    user.amountOfP12 = user.amountOfP12.add(_amountOfP12);
    totalBalanceOfP12 = totalBalanceOfP12.add(_amountOfP12);
    user.rewardDebt = user.amountOfP12.mul(pool.accP12PerShare).div(ONE);
    emit Deposit(msg.sender, pid, _amount);
  }

  // withdraw lpToken delay
  function withdrawDelay(address _lpToken, uint256 _amount) public virtual override whenNotPaused nonReentrant {
    uint256 pid = getPid(_lpToken);
    PoolInfo storage pool = poolInfos[pid];
    UserInfo storage user = userInfo[pid][msg.sender];
    require(user.amountOfLpToken >= _amount, 'P12Mine: withdraw too much');
    updatePool(pid);
    if (user.amountOfLpToken > 0) {
      uint256 pending = user.amountOfP12.mul(pool.accP12PerShare).div(ONE).sub(user.rewardDebt);
      safeP12Transfer(msg.sender, pending);
    }
    uint256 time;
    uint256 currentTimestamp = block.timestamp;
    bytes32 _preWithdrawId = preWithdrawIds[_lpToken];
    uint256 lastUnlockTimestamp = withdrawInfos[_lpToken][_preWithdrawId].unlockTimestamp;

    time = currentTimestamp >= lastUnlockTimestamp ? currentTimestamp : lastUnlockTimestamp;
    uint256 delay = _amount.mul(delayK).div(IERC20Upgradeable(pool.lpToken).totalSupply()) + delayB;
    uint256 unlockTimestamp = delay + time;

    bytes32 newWithdrawId = createWithdrawId(_lpToken, _amount, msg.sender);
    withdrawInfos[_lpToken][newWithdrawId] = WithdrawInfo(_amount, unlockTimestamp, false);
    user.rewardDebt = user.amountOfP12.mul(pool.accP12PerShare).div(ONE);
    emit WithdrawDelay(msg.sender, pid, _amount, newWithdrawId);
  }

  // get pending rewards
  function claim(address _lpToken) public virtual override nonReentrant whenNotPaused {
    uint256 pid = getPid(_lpToken);
    if (userInfo[pid][msg.sender].amountOfLpToken == 0 || poolInfos[pid].p12Total == 0) {
      return; // save gas
    }
    PoolInfo storage pool = poolInfos[pid];
    UserInfo storage user = userInfo[pid][msg.sender];
    updatePool(pid);
    uint256 pending = user.amountOfP12.mul(pool.accP12PerShare).div(ONE).sub(user.rewardDebt);
    user.rewardDebt = user.amountOfP12.mul(pool.accP12PerShare).div(ONE);
    safeP12Transfer(msg.sender, pending);
  }

  // get all pending rewards
  function claimAll() public virtual override nonReentrant whenNotPaused {
    uint256 length = poolInfos.length;
    uint256 pending = 0;
    for (uint256 pid = 0; pid < length; ++pid) {
      if (userInfo[pid][msg.sender].amountOfLpToken == 0 || poolInfos[pid].p12Total == 0) {
        continue; // save gas
      }
      PoolInfo storage pool = poolInfos[pid];
      UserInfo storage user = userInfo[pid][msg.sender];
      updatePool(pid);
      pending = pending.add(user.amountOfP12.mul(pool.accP12PerShare).div(ONE).sub(user.rewardDebt));
      user.rewardDebt = user.amountOfP12.mul(pool.accP12PerShare).div(ONE);
    }
    safeP12Transfer(msg.sender, pending);
  }

  // withdraw lpToken
  function withdraw(
    address pledger,
    address _lpToken,
    bytes32 id
  ) public virtual override nonReentrant whenNotPaused {
    uint256 pid = getPid(_lpToken);
    PoolInfo storage pool = poolInfos[pid];
    UserInfo storage user = userInfo[pid][pledger];
    require(
      withdrawInfos[_lpToken][id].amount <= user.amountOfLpToken &&
        block.timestamp >= withdrawInfos[_lpToken][id].unlockTimestamp &&
        !withdrawInfos[_lpToken][id].executed,
      'P12Mine: can not withdraw'
    );
    withdrawInfos[_lpToken][id].executed = true;
    updatePool(pid);
    uint256 pending = user.amountOfP12.mul(pool.accP12PerShare).div(ONE).sub(user.rewardDebt);
    safeP12Transfer(pledger, pending);
    uint256 _amount = withdrawInfos[_lpToken][id].amount;
    user.amountOfLpToken = user.amountOfLpToken.sub(_amount);

    uint256 _amountOfP12 = calculateP12AmountByLpToken(_lpToken, _amount);
    pool.p12Total = pool.p12Total.sub(_amountOfP12);
    user.amountOfP12 = user.amountOfP12.sub(_amountOfP12);
    totalBalanceOfP12 = totalBalanceOfP12.sub(_amountOfP12);
    user.rewardDebt = user.amountOfP12.mul(pool.accP12PerShare).div(ONE);
    totalLpStakedOfEachPool[_lpToken] -= _amount;
    IERC20Upgradeable(pool.lpToken).safeTransfer(address(pledger), _amount);
    emit Withdraw(pledger, pid, _amount);
  }

  // ============ Internal ============

  // Safe P12 transfer function
  function safeP12Transfer(address _to, uint256 _amount) internal virtual {
    IP12RewardVault(p12RewardVault).reward(_to, _amount);
    realizedReward[_to] = realizedReward[_to].add(_amount);
    emit Claim(_to, _amount);
  }

  // crate withdraw id
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

  // Calculate the value of p12 corresponding to lpToken
  function calculateP12AmountByLpToken(address _lpToken, uint256 _amount) internal view virtual returns (uint256) {
    getPid(_lpToken);
    uint256 balance0 = IERC20Upgradeable(p12Token).balanceOf(_lpToken);
    uint256 _totalSupply = IERC20Upgradeable(_lpToken).totalSupply();
    uint256 amount0 = _amount.mul(balance0) / _totalSupply;

    return amount0;
  }
}
