// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import './P12V0FactoryStorage.sol';

// not complete contract, just for mock data
contract P12V0FactoryTem is P12V0FactoryStorage {
  event RegisterGame(string gameId, address indexed developer);

  function register(string memory gameId, address developer) external virtual {
    allGames[gameId] = developer;
    emit RegisterGame(gameId, developer);
  }
}
