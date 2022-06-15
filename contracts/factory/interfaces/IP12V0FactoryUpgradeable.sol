// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.13;

import './IP12V0ERC20.sol';
import '../../staking/interfaces/IP12MineUpgradeable.sol';
import '../../staking/interfaces/IGaugeController.sol';

interface IP12V0FactoryUpgradeable {
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
  ) external returns (IP12V0ERC20);

  //  mint coin and Launch a statement
  function declareMintCoin(
    string memory gameId,
    IP12V0ERC20 gameCoinAddress,
    uint256 amountGameCoin
  ) external returns (bool);

  // execute Mint coin
  function executeMint(IP12V0ERC20 gameCoinAddress, bytes32 mintId) external returns (bool);

  function withdraw(
    address userAddress,
    IP12V0ERC20 gameCoinAddress,
    uint256 amountGameCoin
  ) external returns (bool);

  function setP12Mine(IP12MineUpgradeable newP12Mine) external;

  function setGaugeController(IGaugeController newGaugeController) external;

  // get mintFee
  function getMintFee(IP12V0ERC20 gameCoinAddress, uint256 amountGameCoin) external view returns (uint256);

  // get mintDelay
  function getMintDelay(IP12V0ERC20 gameCoinAddress, uint256 amountGameCoin) external view returns (uint256);

  // get delayK
  function setDelayK(uint256 delayK) external returns (bool);

  // get delayB
  function setDelayB(uint256 delayB) external returns (bool);

  // register Game developer log
  event RegisterGame(string gameId, address indexed developer);

  // register Game coin log
  event CreateGameCoin(IP12V0ERC20 indexed gameCoinAddress, string gameId, uint256 amountP12);

  // mint coin in future log
  event DeclareMint(
    bytes32 indexed mintId,
    IP12V0ERC20 indexed gameCoinAddress,
    uint256 mintAmount,
    uint256 unlockTimestamp,
    uint256 amountP12
  );

  // mint coin success log
  event ExecuteMint(bytes32 indexed mintId, IP12V0ERC20 indexed gameCoinAddress, address indexed executor);

  // game player withdraw gameCoin
  event Withdraw(address userAddress, IP12V0ERC20 gameCoinAddress, uint256 amountGameCoin);

  // p12Mine and GaugeController address change log
  event SetP12Mine(IP12MineUpgradeable oldP12Mine, IP12MineUpgradeable newP12Mine);
  //
  event SetGaugeController(IGaugeController oldGaugeController, IGaugeController newGaugeController);
  // change delayB log
  event SetDelayB(uint256 oldDelayB, uint256 newDelayB);

  // change delayK log
  event SetDelayK(uint256 oldDelayK, uint256 newDelayK);
}
