// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.19;

import { IUniswapV3Factory } from '@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol';
import { INonfungiblePositionManager } from 'src/interfaces/external/uniswap/INonfungiblePositionManager.sol';
import { IP12CoinFactoryDef } from 'src/coinFactory/interfaces/IP12CoinFactoryUpgradeable.sol';

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
   * @notice game coin implmentation address
   */
  address public gameCoinImpl;
  /**
   * @dev length of cast delay time is a linear function of percentage of additional issues,
   * @dev delayK and delayB is the linear function's parameter which could be changed later
   */
  uint256 public delayK;
  uint256 public delayB;

  mapping(address => bool) public signers;

  // gameId => developer address
  mapping(uint256 => address) public gameDev;
  // gameCoinAddress => gameId
  mapping(address => uint256) public coinGameIds;
  // gameCoinAddress => declareMintId => MintCoinInfo
  mapping(address => mapping(bytes32 => IP12CoinFactoryDef.MintCoinInfo)) public coinMintRecords;
  // gameCoinAddress => declareMintId
  mapping(address => bytes32) public preMintIds;

  uint256[40] private __gap;
}
