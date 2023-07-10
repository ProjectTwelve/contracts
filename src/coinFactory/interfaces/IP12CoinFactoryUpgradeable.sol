// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.19;

import { IUniswapV3Factory } from '@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol';
import { INonfungiblePositionManager } from '@uniswap/v3-periphery/contracts/interfaces/INonfungiblePositionManager.sol';

import '../../staking/interfaces/IP12MineUpgradeable.sol';
import '../../staking/interfaces/IGaugeController.sol';
import './IP12GameCoin.sol';

interface IP12CoinFactoryUpgradeable {
  // register gameId =>developer
  function register(string memory gameId, address developer) external;

  // mint game coin
  function create(
    string memory name,
    string memory symbol,
    string memory gameId,
    string memory gameCoinIconUrl,
    uint256 amountGameCoin,
    uint256 amountP12
  ) external returns (IP12GameCoin);

  //  mint coin and Launch a statement
  function queueMintCoin(string memory gameId, IP12GameCoin gameCoinAddress, uint256 amountGameCoin) external returns (bool);

  // execute Mint coin
  function executeMintCoin(IP12GameCoin gameCoinAddress, bytes32 mintId) external returns (bool);

  function withdraw(address userAddress, IP12GameCoin gameCoinAddress, uint256 amountGameCoin) external returns (bool);

  function setDev(address newDev) external;

  function setP12Mine(IP12MineUpgradeable newP12Mine) external;

  function setGaugeController(IGaugeController newGaugeController) external;

  function setUniswapFactory(IUniswapV3Factory newUniswapFactory) external;

  function setUniswapPosManager(INonfungiblePositionManager newUniswapRouter) external;

  function setP12Token(address newP12Token) external;

  // get mintFee
  function getMintFee(IP12GameCoin gameCoinAddress, uint256 amountGameCoin) external view returns (uint256);

  // get mintDelay
  function getMintDelay(IP12GameCoin gameCoinAddress, uint256 amountGameCoin) external view returns (uint256);

  // get delayK
  function setDelayK(uint256 delayK) external returns (bool);

  // get delayB
  function setDelayB(uint256 delayB) external returns (bool);

  error MisMatchCoinWithGameId(IP12GameCoin coin, string gameId);
  // not existent mint id
  error NonExistenceMintId(bytes32 mintId);
  // mintId is already executed
  error ExecutedMint(bytes32 mintId);
  // it's not time to mint this batch of coins
  error NotTimeToMint(bytes32 mintId);
  // don't have p12 dev role
  error NotP12Dev();
  // invalid liquidity when first create coin and create swap pool
  error InvalidLiquidity();

  // register Game developer log
  event RegisterGame(string gameId, address indexed developer);

  // register Game coin log
  event CreateGameCoin(IP12GameCoin indexed gameCoinAddress, string gameId, uint256 amountP12);

  // mint coin in future log
  event QueueMintCoin(
    bytes32 indexed mintId,
    IP12GameCoin indexed gameCoinAddress,
    uint256 mintAmount,
    uint256 unlockTimestamp,
    uint256 amountP12
  );

  // mint coin success log
  event ExecuteMintCoin(bytes32 indexed mintId, IP12GameCoin indexed gameCoinAddress, address indexed executor);

  // game player withdraw gameCoin
  event Withdraw(address userAddress, IP12GameCoin gameCoinAddress, uint256 amountGameCoin);

  event SetDev(address oldDev, address newDev);

  // p12Mine and GaugeController address change log
  event SetP12Mine(IP12MineUpgradeable oldP12Mine, IP12MineUpgradeable newP12Mine);

  event SetGaugeController(IGaugeController oldGaugeController, IGaugeController newGaugeController);

  // uniFactory and router address change log
  event SetUniswapFactory(IUniswapV3Factory oldUniswapFactory, IUniswapV3Factory newUniswapFactory);

  event SetUniswapPosManager(INonfungiblePositionManager oldUniswapRouter, INonfungiblePositionManager newUniswapRouter);

  event SetP12Token(address oldP12Token, address newP12Token);

  // change delayB log
  event SetDelayB(uint256 oldDelayB, uint256 newDelayB);

  // change delayK log
  event SetDelayK(uint256 oldDelayK, uint256 newDelayK);
}
