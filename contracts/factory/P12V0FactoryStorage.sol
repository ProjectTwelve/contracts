// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.13;

import '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol';
import './interfaces/IP12MineUpgradeable.sol';
import './interfaces/IGaugeController.sol';
import './interfaces/IP12V0ERC20.sol';

contract P12V0FactoryStorage {
  /**
   * @dev p12 ERC20 address
   */
  address public p12;
  /**
   * @dev uniswap v2 Router address
   */
  IUniswapV2Router02 public uniswapRouter;
  /**
   * @dev uniswap v2 Factory address
   */
  IUniswapV2Factory public uniswapFactory;
  /**
   * @dev length of cast delay time is a linear function of percentage of additional issues,
   * @dev delayK and delayB is the linear function's parameter which could be changed later
   */
  uint256 public delayK;
  uint256 public delayB;

  /**
   * @dev a random hash value for calculate mintId
   */
  bytes32 internal _initHash;

  uint256 public addLiquidityEffectiveTime;

  /**
   * @dev p12 staking contract
   */
  IP12MineUpgradeable public p12Mine;

  address public dev;
  IGaugeController public gaugeController;

  uint256[40] private __gap;

  /**
   * @dev struct of each mint request
   */
  struct MintCoinInfo {
    uint256 amount;
    uint256 unlockTimestamp;
    bool executed;
  }
  // gameId => developer address
  mapping(string => address) public allGames;
  // gameCoinAddress => gameId
  mapping(IP12V0ERC20 => string) public allGameCoins;
  // gameCoinAddress => declareMintId => MintCoinInfo
  mapping(IP12V0ERC20 => mapping(bytes32 => MintCoinInfo)) public coinMintRecords;
  // gameCoinAddress => declareMintId
  mapping(IP12V0ERC20 => bytes32) public preMintIds;
}
