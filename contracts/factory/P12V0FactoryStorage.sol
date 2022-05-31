// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.13;

contract P12V0FactoryStorage {
  /**
   * @dev p12 ERC20 address
   */
  address public p12;
  /**
   * @dev uniswap v2 Router address
   */
  address public uniswapRouter;
  /**
   * @dev uniswap v2 Factory address
   */
  address public uniswapFactory;
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
  address public p12Mine;
  address public gaugeController;

  // gameId => developer address
  mapping(string => address) public allGames;
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
