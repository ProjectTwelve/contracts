// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.19;

import { IUniswapV3Factory } from '@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol';
import { INonfungiblePositionManager } from 'src/interfaces/external/uniswap/INonfungiblePositionManager.sol';
import '../staking/interfaces/IP12MineUpgradeable.sol';
import '../staking/interfaces/IGaugeController.sol';
import './interfaces/IP12GameCoin.sol';

contract P12CoinFactoryStorage {
  /**
   * @dev p12 ERC20 address
   */
  address public p12;
  /**
   * @dev uniswap position manager address
   */
  INonfungiblePositionManager public uniswapPosManager;
  /**
   * @dev uniswap v3 Factory address
   */
  IUniswapV3Factory public uniswapFactory;

  /**
   * @notice game coin implmentation address
   */
  address public gameCoinImpl;
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

  /**
   * @dev p12 staking contract
   */
  IP12MineUpgradeable public p12Mine;

  address public dev;
  IGaugeController public gaugeController;

  uint256[40] private __gap;

  // gameId => developer address
  mapping(string => address) public _gameDev;
  // gameCoinAddress => gameId
  mapping(address => string) public allGameCoins;
  // gameCoinAddress => declareMintId => MintCoinInfo
  mapping(address => mapping(bytes32 => MintCoinInfo)) public coinMintRecords;
  // gameCoinAddress => declareMintId
  mapping(address => bytes32) public preMintIds;

  /**
   * @dev struct of each mint request
   */
  struct MintCoinInfo {
    uint256 amount;
    uint256 unlockTimestamp;
    bool executed;
  }
}
