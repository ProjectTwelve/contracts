// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.19;

import { IUniswapV3Factory } from '@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol';
import { INonfungiblePositionManager } from 'src/interfaces/external/uniswap/INonfungiblePositionManager.sol';

interface IP12CoinFactoryDef {
  /**
   * @dev struct of each mint request
   */
  struct MintCoinInfo {
    uint256 amount;
    address coinAddr;
    uint40 unlockTimestamp;
    bool executed;
  }

  // register Game developer log
  event RegisterGame(uint256 gameId, address indexed developer);

  // register Game coin log
  event CreateGameCoin(
    address indexed developer,
    address indexed gameCoinAddress,
    uint256 indexed gameId,
    uint256 amountGameCoin,
    uint256 amountP12
  );

  // mint coin in future log
  event QueueMintCoin(
    bytes32 indexed mintId,
    address indexed gameCoinAddress,
    uint256 mintAmount,
    uint256 unlockTimestamp,
    uint256 amountP12
  );

  event SignerUpdate(address signer, bool valid);

  // mint coin success log
  event ExecuteMintCoin(bytes32 indexed mintId, address indexed gameCoinAddress, address indexed executor);

  // game player withdraw gameCoin
  event Withdraw(address userAddress, address gameCoinAddress, uint256 amountGameCoin);

  event SetDev(address oldDev, address newDev);

  // change delayB log
  event SetDelayB(uint256 oldDelayB, uint256 newDelayB);

  // change delayK log
  event SetDelayK(uint256 oldDelayK, uint256 newDelayK);

  error MisMatchCoinWithGameId(address coin, uint256 gameId);
  // not existent mint id
  error NonExistenceMintId(bytes32 mintId);
  // mintId is already executed
  error ExecutedMint(bytes32 mintId);
  // it's not time to mint this batch of coins
  error NotTimeToMint(bytes32 mintId);
  // don't have p12 dev role
  error NotP12Signer();
  // invalid liquidity when first create coin and create swap pool
  error InvalidLiquidity();
}

interface IP12CoinFactoryUpgradeable is IP12CoinFactoryDef {
  // register gameId =>developer
  function register(uint256 gameId, address developer) external;

  // mint game coin
  function create(
    string calldata name,
    string calldata symbol,
    string calldata uri,
    uint256 gameId,
    uint256 amountGameCoin,
    uint256 amountP12
  ) external returns (address);

  //  mint coin and Launch a statement
  function queueMintCoin(address gameCoinAddress, uint256 amountGameCoin) external returns (bytes32);

  // execute Mint coin
  function executeMintCoin(bytes32 mintId) external;

  function withdraw(address userAddress, address gameCoinAddress, uint256 amountGameCoin) external returns (bool);

  function getGameDev(uint256) external returns (address);

  function getGameNextCoinAddress(uint256 gameId) external view returns (address gameCoinAddress);

  // get mintFee
  function getMintFee(address gameCoinAddress, uint256 amountGameCoin) external view returns (uint256);

  // get mintDelay
  function getMintDelay(address gameCoinAddress, uint256 amountGameCoin) external view returns (uint256);

  // get delayK
  function setDelayK(uint256 delayK) external returns (bool);

  // get delayB
  function setDelayB(uint256 delayB) external returns (bool);
}
