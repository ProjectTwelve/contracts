// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.15;

import '@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol';
import '@openzeppelin/contracts/utils/math/Math.sol';

import './interfaces/IGaugeController.sol';
import '../token/interfaces/IVotingEscrow.sol';
import './ControllerStorage.sol';
import '../access/SafeOwnableUpgradeable.sol';
import '../libraries/CommonError.sol';

contract GaugeControllerUpgradeable is
  ControllerStorage,
  IGaugeController,
  UUPSUpgradeable,
  SafeOwnableUpgradeable,
  PausableUpgradeable
{
  using Math for uint256;
  // 7 * 86400 seconds - all future times are rounded by week
  uint256 public constant WEEK = 604800;
  uint256 public constant MULTIPLIER = 10**18;

  // Cannot change weight votes more often than once in 10 days
  uint256 public constant WEIGHT_VOTE_DELAY = 10 * 86400;

  /**
   * @notice set new votingEscrow
   * @param newVotingEscrow address of votingEscrow
   */
  function setVotingEscrow(IVotingEscrow newVotingEscrow) external virtual override onlyOwner {
    IVotingEscrow oldVotingEscrow = votingEscrow;
    if (address(newVotingEscrow) == address(0)) revert CommonError.ZeroAddressSet();
    votingEscrow = newVotingEscrow;
    emit SetVotingEscrow(oldVotingEscrow, newVotingEscrow);
  }

  /**
   * @notice set new p12CoinFactory
   * @param newP12Factory address of newP12Factory
   */
  function setP12CoinFactory(address newP12Factory) external virtual override onlyOwner {
    address oldP12Factory = p12CoinFactory;
    if (newP12Factory == address(0)) revert CommonError.ZeroAddressSet();
    p12CoinFactory = newP12Factory;
    emit SetP12Factory(oldP12Factory, newP12Factory);
  }

  /**
   * @notice Get gauge type for address
   * @param addr Gauge address
   * @return Gauge type id
   */
  function getGaugeTypes(address addr) external view virtual override returns (int128) {
    int128 gaugeType = gaugeTypes[addr];
    if (gaugeType == 0) revert InvalidGaugeType();
    return gaugeType - 1;
  }

  /**
   * @notice Add gauge `addr` of type `gaugeType` with weight `weight`
   * @param addr Gauge address
   * @param gaugeType Gauge type
   * @param weight Gauge weight
   */
  function addGauge(
    address addr,
    int128 gaugeType,
    uint256 weight
  ) external virtual override {
    if (msg.sender != owner() && msg.sender != address(p12CoinFactory)) revert CommonError.NoPermission();
    if (gaugeType < 0 || gaugeType >= nGaugeTypes) revert InvalidGaugeType();
    if (gaugeTypes[addr] != 0) revert DuplicatedGaugeType();

    int128 n = nGauges;
    nGauges = n + 1;
    gauges[n] = addr;

    gaugeTypes[addr] = gaugeType + 1;
    uint256 nextTime = ((block.timestamp + WEEK) / WEEK) * WEEK;

    if (weight > 0) {
      uint256 typeWeight = _getTypeWeight(gaugeType);
      uint256 oldSum = _getSum(gaugeType);
      uint256 oldTotal = _getTotal();

      pointsSum[gaugeType][nextTime].bias = weight + oldSum;
      timeSum[gaugeType] = nextTime;
      pointsTotal[nextTime] = oldTotal + typeWeight * weight;
      timeTotal = nextTime;

      pointsWeight[addr][nextTime].bias = weight;
    }

    if (timeSum[gaugeType] == 0) {
      timeSum[gaugeType] = nextTime;
    }
    timeWeight[addr] = nextTime;

    emit NewGauge(addr, gaugeType, weight);
  }

  /**
   * @notice Checkpoint to fill data common for all gauges
   */
  function checkpoint() external virtual override {
    _getTotal();
  }

  /**
   * @notice Checkpoint to fill data for both a specific gauge and common for all gauges
   * @param addr Gauge address
   */
  function checkpointGauge(address addr) external virtual override {
    _getWeight(addr);
    _getTotal();
  }

  /**
   * @notice Get Gauge relative weight (not more than 1.0) normalized to 1e18
   *        (e.g. 1.0 == 1e18). Inflation which will be received by it is
   *        inflation_rate * relative_weight / 1e18
   * @param addr Gauge address
   * @param time Relative weight at the specified timestamp in the past or present
   * @return Value of relative weight normalized to 1e18
   */
  function gaugeRelativeWeight(address addr, uint256 time) external view virtual override returns (uint256) {
    return _gaugeRelativeWeight(addr, time);
  }

  /**
   * @notice Get gauge weight normalized to 1e18 and also fill all the unfilled
   *     values for type and gauge records
   * @dev Any address can call, however nothing is recorded if the values are filled already
   * @param addr Gauge address
   * @param time Relative weight at the specified timestamp in the past or present
   * @return Value of relative weight normalized to 1e18
   */
  function gaugeRelativeWeightWrite(address addr, uint256 time) external virtual override returns (uint256) {
    _getWeight(addr);
    _getTotal(); // Also calculates get_sum
    return _gaugeRelativeWeight(addr, time);
  }

  /**
   * @notice Add gauge type with name `name` and weight `weight`
   * @param name Name of gauge type
   * @param weight Weight of gauge type
   */
  function addType(string memory name, uint256 weight) external virtual override onlyOwner {
    int128 typeId = nGaugeTypes;
    gaugeTypeNames[typeId] = name;
    nGaugeTypes = typeId + 1;
    if (weight != 0) {
      _changeTypeWeight(typeId, weight);
      emit AddType(name, typeId);
    }
  }

  /**
   * @notice Change gauge type `typeId` weight to `weight`
   * @param typeId Gauge type id
   * @param weight New Gauge weight
   */
  function changeTypeWeight(int128 typeId, uint256 weight) external virtual override onlyOwner {
    _changeTypeWeight(typeId, weight);
  }

  /**
   * @notice Change weight of gauge `addr` to `weight`
   * @param addr `GaugeController` contract address
   * @param weight New Gauge weight
   */
  function changeGaugeWeight(address addr, uint256 weight) external virtual override onlyOwner {
    _changeGaugeWeight(addr, weight);
  }

  /**
   * @notice Allocate voting power for changing pool weights
   * @param gaugeAddr Gauge which `msg.sender` votes for
   * @param userWeight Weight for a gauge in bps (units of 0.01%). Minimal is 0.01%. Ignored if 0
   */
  function voteForGaugeWeights(address gaugeAddr, uint256 userWeight) external virtual override whenNotPaused {
    uint256 slope = uint256(votingEscrow.getLastUserSlope(msg.sender));
    uint256 lockEnd = votingEscrow.lockedEnd(msg.sender);
    uint256 nextTime = ((block.timestamp + WEEK) / WEEK) * WEEK;

    if (lockEnd <= nextTime) revert UnLockTooSoon();
    if (userWeight > 10000) revert InvalidWeight();
    if (block.timestamp < lastUserVote[msg.sender][gaugeAddr] + WEIGHT_VOTE_DELAY) revert VoteTooOften();
    TmpBias memory tmp1;
    int128 gaugeType = gaugeTypes[gaugeAddr] - 1;
    if (gaugeType < 0) revert AddGaugeFail();
    // Prepare slopes and biases in memory
    VotedSlope memory oldSlope = voteUserSlopes[msg.sender][gaugeAddr];
    uint256 oldDt = 0;
    if (oldSlope.end > nextTime) {
      oldDt = oldSlope.end - nextTime;
    }
    tmp1.oldBias = oldSlope.slope * oldDt;
    VotedSlope memory newSlope = VotedSlope({ slope: (slope * userWeight) / 10000, end: lockEnd, power: userWeight });
    uint256 newDt = lockEnd - nextTime; // dev: raises when expired
    tmp1.newBias = newSlope.slope * newDt;

    // Check and update powers (weights) used
    voteUserPower[msg.sender] = voteUserPower[msg.sender] + newSlope.power - oldSlope.power;
    if (voteUserPower[msg.sender] > 10000) revert InvalidWeight();

    // Remove old and schedule new slope changes
    // Remove slope changes for old slopes
    // Schedule recording of initial slope for nextTime

    {
      TmpBiasAndSlope memory tmp2;
      tmp2.oldWeightBias = _getWeight(gaugeAddr);
      tmp2.oldWeightSlope = pointsWeight[gaugeAddr][nextTime].slope;
      tmp2.oldSumBias = _getSum(gaugeType);
      tmp2.oldSumSlope = pointsSum[gaugeType][nextTime].slope;

      pointsWeight[gaugeAddr][nextTime].bias = Math.max(tmp2.oldWeightBias + tmp1.newBias, tmp1.oldBias) - tmp1.oldBias;
      pointsSum[gaugeType][nextTime].bias = Math.max(tmp2.oldSumBias + tmp1.newBias, tmp1.oldBias) - tmp1.oldBias;
      if (oldSlope.end > nextTime) {
        pointsWeight[gaugeAddr][nextTime].slope =
          Math.max(tmp2.oldWeightSlope + newSlope.slope, oldSlope.slope) -
          oldSlope.slope;
        pointsSum[gaugeType][nextTime].slope = Math.max(tmp2.oldSumSlope + newSlope.slope, oldSlope.slope) - oldSlope.slope;
      } else {
        pointsWeight[gaugeAddr][nextTime].slope += newSlope.slope;
        pointsSum[gaugeType][nextTime].slope += newSlope.slope;
      }
    }

    if (oldSlope.end > block.timestamp) {
      // Cancel old slope changes if they still didn't happen
      changesWeight[gaugeAddr][oldSlope.end] -= oldSlope.slope;
      changesSum[gaugeType][oldSlope.end] -= oldSlope.slope;
    }

    // Add slope changes for new slopes

    changesWeight[gaugeAddr][newSlope.end] += newSlope.slope;
    changesSum[gaugeType][newSlope.end] += newSlope.slope;

    _getTotal();

    voteUserSlopes[msg.sender][gaugeAddr] = newSlope;

    // Record last action time
    lastUserVote[msg.sender][gaugeAddr] = block.timestamp;
    emit VoteForGauge(block.timestamp, msg.sender, gaugeAddr, userWeight);
  }

  /**
   * @notice Get current gauge weight
   * @param addr Gauge address
   * @return Gauge weight
   */
  function getGaugeWeight(address addr) external view virtual override returns (uint256) {
    return pointsWeight[addr][timeWeight[addr]].bias;
  }

  /**
   * @notice Get current type weight
   * @param typeId Type id
   * @return Type weight
   */
  function getTypeWeight(int128 typeId) external view virtual override returns (uint256) {
    return pointsTypeWeight[typeId][timeTypeWeight[typeId]];
  }

  /**
   * @notice Get current total (type-weighted) weight
   * @return Total weight
   */
  function getTotalWeight() external view virtual override returns (uint256) {
    return pointsTotal[timeTotal];
  }

  /**
   * @notice Get sum of gauge weights per type
   * @param typeId Type id
   * @return Sum of gauge weights
   */
  function getWeightsSumPerType(int128 typeId) external view virtual override returns (uint256) {
    return pointsSum[typeId][timeSum[typeId]].bias;
  }

  //-----------public----------

  function pause() public onlyOwner {
    _pause();
  }

  function unpause() public onlyOwner {
    _unpause();
  }

  function initialize(
    address owner_,
    address votingEscrow_,
    address p12CoinFactory_
  ) public initializer {
    if (votingEscrow_ == address(0) || p12CoinFactory_ == address(0)) revert CommonError.ZeroAddressSet();
    votingEscrow = IVotingEscrow(votingEscrow_);
    p12CoinFactory = p12CoinFactory_;

    __Pausable_init_unchained();
    __Ownable_init_unchained(owner_);
  }

  //-----------internal----------
  /** upgrade function */
  function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

  /**
   * @notice Fill historic type weights week-over-week for missed checkins
   *     and return the type weight for the future week
   * @param gaugeType Gauge type id
   * @return Type weight
   */
  function _getTypeWeight(int128 gaugeType) internal virtual returns (uint256) {
    uint256 t = timeTypeWeight[gaugeType];
    if (t > 0) {
      uint256 w = pointsTypeWeight[gaugeType][t];
      for (uint256 i = 0; i < 500; i++) {
        if (t > block.timestamp) {
          break;
        }
        t += WEEK;
        pointsTypeWeight[gaugeType][t] = w;
        if (t > block.timestamp) {
          timeTypeWeight[gaugeType] = t;
        }
      }
      return w;
    } else {
      return 0;
    }
  }

  /**
   * @notice Fill sum of gauge weights for the same type week-over-week for
   *     missed checkins and return the sum for the future week
   * @param gaugeType Gauge type id
   * @return Sum of weights
   */
  function _getSum(int128 gaugeType) internal virtual returns (uint256) {
    uint256 t = timeSum[gaugeType];
    if (t > 0) {
      Point memory pt = pointsSum[gaugeType][t];
      for (uint256 i = 0; i < 500; i++) {
        if (t > block.timestamp) {
          break;
        }
        t += WEEK;
        uint256 dBias = pt.slope * WEEK;
        if (pt.bias > dBias) {
          pt.bias -= dBias;
          uint256 dSlope = changesSum[gaugeType][t];
          pt.slope -= dSlope;
        } else {
          pt.bias = 0;
          pt.slope = 0;
        }
        pointsSum[gaugeType][t] = pt;
        if (t > block.timestamp) {
          timeSum[gaugeType] = t;
        }
      }
      return pt.bias;
    } else {
      return 0;
    }
  }

  /**
   * @notice Fill historic total weights week-over-week for missed checkins
   *  and return the total for the future week
   * @return Total weight
   */
  function _getTotal() internal virtual returns (uint256) {
    uint256 t = timeTotal;
    int128 _nGaugeTypes = nGaugeTypes;
    if (t > block.timestamp) {
      // If we have already checkpointed - still need to change the value
      t -= WEEK;
    }

    uint256 pt = pointsTotal[t];
    for (int128 gaugeType = 0; gaugeType < 100; gaugeType++) {
      if (gaugeType == _nGaugeTypes) {
        break;
      }
      _getSum(gaugeType);
      _getTypeWeight(gaugeType);
    }

    for (uint256 i = 0; i < 500; i++) {
      if (t > block.timestamp) {
        break;
      }

      t += WEEK;
      pt = 0;
      // Scales as n_types * n_unchecked_weeks (hopefully 1 at most)
      for (int128 gaugeType = 0; gaugeType < 100; gaugeType++) {
        if (gaugeType == nGaugeTypes) {
          break;
        }
        uint256 typeSum = pointsSum[gaugeType][t].bias;
        uint256 typeWeight = pointsTypeWeight[gaugeType][t];
        pt += typeSum * typeWeight;
      }
      pointsTotal[t] = pt;

      if (t > block.timestamp) {
        timeTotal = t;
      }
    }
    return pt;
  }

  /**
   * @notice Fill historic gauge weights week-over-week for missed checkins
   *     and return the total for the future week
   * @param gaugeAddr Address of the gauge
   * @return Gauge weight
   */
  function _getWeight(address gaugeAddr) internal virtual returns (uint256) {
    uint256 t = timeWeight[gaugeAddr];
    if (t > 0) {
      Point memory pt = pointsWeight[gaugeAddr][t];
      for (uint256 i = 0; i < 500; i++) {
        if (t > block.timestamp) {
          break;
        }
        t += WEEK;
        uint256 dBias = pt.slope * WEEK;
        if (pt.bias > dBias) {
          pt.bias -= dBias;
          uint256 dSlope = changesWeight[gaugeAddr][t];
          pt.slope -= dSlope;
        } else {
          pt.bias = 0;
          pt.slope = 0;
        }
        pointsWeight[gaugeAddr][t] = pt;
        if (t > block.timestamp) {
          timeWeight[gaugeAddr] = t;
        }
      }
      return pt.bias;
    } else {
      return 0;
    }
  }

  /**
   * @notice Get Gauge relative weight (not more than 1.0) normalized to 1e18
   *         (e.g. 1.0 == 1e18). Inflation which will be received by it is
   *         inflation_rate * relative_weight / 1e18
   * @param addr Gauge address
   * @param time Relative weight at the specified timestamp in the past or present
   * @return Value of relative weight normalized to 1e18
   */
  function _gaugeRelativeWeight(address addr, uint256 time) internal view virtual returns (uint256) {
    uint256 t = (time / WEEK) * WEEK;

    uint256 totalWeight = pointsTotal[t];

    if (totalWeight > 0) {
      int128 gaugeType = gaugeTypes[addr] - 1;
      uint256 typeWeight = pointsTypeWeight[gaugeType][t];
      uint256 gaugeWeight = pointsWeight[addr][t].bias;
      return (MULTIPLIER * typeWeight * gaugeWeight) / totalWeight;
    } else {
      return 0;
    }
  }

  function _changeTypeWeight(int128 typeId, uint256 weight) internal virtual {
    uint256 oldWeight = _getTypeWeight(typeId);
    uint256 oldSum = _getSum(typeId);
    uint256 totalWeight = _getTotal();
    uint256 nextTime = ((block.timestamp + WEEK) / WEEK) * WEEK;

    totalWeight = totalWeight + oldSum * weight - oldSum * oldWeight;
    pointsTotal[nextTime] = totalWeight;
    pointsTypeWeight[typeId][nextTime] = weight;
    timeTotal = nextTime;
    timeTypeWeight[typeId] = nextTime;

    emit NewTypeWeight(typeId, nextTime, weight, totalWeight);
  }

  function _changeGaugeWeight(address addr, uint256 weight) internal virtual {
    // Change gauge weight
    // Only needed when testing in reality
    int128 gaugeType = gaugeTypes[addr] - 1;
    uint256 oldGaugeWeight = _getWeight(addr);
    uint256 typeWeight = _getTypeWeight(gaugeType);
    uint256 oldSum = _getSum(gaugeType);
    uint256 totalWeight = _getTotal();
    uint256 nextTime = ((block.timestamp + WEEK) / WEEK) * WEEK;

    pointsWeight[addr][nextTime].bias = weight;
    timeWeight[addr] = nextTime;

    uint256 newSum = oldSum + weight - oldGaugeWeight;
    pointsSum[gaugeType][nextTime].bias = newSum;
    timeSum[gaugeType] = nextTime;

    totalWeight = totalWeight + newSum * typeWeight - oldSum * typeWeight;
    pointsTotal[nextTime] = totalWeight;
    timeTotal = nextTime;

    emit NewGaugeWeight(addr, block.timestamp, weight, totalWeight);
  }
}
