// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.13;

import '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router01.sol';
import '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '../../token/interfaces/IP12Token.sol';
import './IP12V0ERC20.sol';

interface IP12V0Factory {
  // register gameId =>developer
  function register(string memory gameId, address developer) external;

  // mint game coin
  function create(
    string memory name_,
    string memory symbol_,
    string memory gameId,
    string memory gameCoinIconUrl,
    uint256 amountGameCoin,
    uint256 amountP12
  ) external returns (IP12V0ERC20);

  // mint coin and Launch a statement
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

  // get mintFee
  function getMintFee(IP12V0ERC20 gameCoinAddress, uint256 amountGameCoin) external view returns (uint256);

  // get mintDelay
  function getMintDelay(IP12V0ERC20 gameCoinAddress, uint256 amountGameCoin) external view returns (uint256);

  // set custodian address
  function setCustodian(address _custodian) external returns (bool);

  // set admin address
  function setAdmin(address _admin) external returns (bool);

  // set delayK
  function setDelayK(uint256 _delayK) external returns (bool);

  // set delayB
  function setDelayB(uint256 _delayB) external returns (bool);

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
}
