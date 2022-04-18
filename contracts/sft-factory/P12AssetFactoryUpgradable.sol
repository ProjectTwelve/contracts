// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';
import '@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol';
import '@openzeppelin/contracts/utils/cryptography/ECDSA.sol';
import './P12Asset.sol';
import './P12V0FactoryStorage.sol';

// import "hardhat/console.sol";

contract P12AssetFactoryUpgradable is
  Initializable,
  ReentrancyGuardUpgradeable,
  OwnableUpgradeable,
  PausableUpgradeable,
  UUPSUpgradeable
{
  event CollectionCreated(address indexed collection, address indexed developer);
  event SftCreated(address indexed collection, uint256 indexed tokenId, uint256 amount);

  /**
        @dev collection => gameId
     */
  mapping(address => string) public registry;

  // for reading game and developer relationship
  address public p12factory;

  /** upgrade function */
  function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

  function pause() public onlyOwner {
    _pause();
  }

  function unpause() public onlyOwner {
    _unpause();
  }

  function initialize(address p12factory_) public initializer {
    p12factory = p12factory_;

    __ReentrancyGuard_init_unchained();
    __Pausable_init_unchained();
    __Ownable_init_unchained();
  }

  modifier onlyDeveloper(string memory gameId) {
    require(P12V0FactoryStorage(p12factory).allGames(gameId) == msg.sender, 'P12Asset: not game developer');
    _;
  }

  modifier onlyCollectionDeveloper(address collection) {
    require(P12V0FactoryStorage(p12factory).allGames(registry[collection]) == msg.sender, 'P12Asset: not game developer');
    _;
  }

  /**
   * @dev create Collection
   * TODO: return value can be delete later
   */
  function createCollection(string memory gameId, string calldata contractURI_) public onlyDeveloper(gameId) returns (address) {
    P12Asset collection = new P12Asset(contractURI_);
    // record creator
    registry[address(collection)] = gameId;

    emit CollectionCreated(address(collection), msg.sender);

    return address(collection);
  }

  /**
   * @dev create asset and mint to msg.sender address
   * @return uint256  asset tokenId
   * TODO: return value can be delete later
   */
  function createAssetAndMint(
    address collection,
    uint256 amount_,
    string calldata uri_
  ) public onlyCollectionDeveloper(collection) returns (uint256) {
    // create
    uint256 tokenId = P12Asset(collection).create(amount_, uri_);
    // mint to developer address
    P12Asset(collection).mint(msg.sender, tokenId, amount_, new bytes(0));

    emit SftCreated(address(collection), tokenId, amount_);
    return tokenId;
  }

  function updateCollectionUri(address collection, string calldata uri_) public onlyCollectionDeveloper(collection) {
    P12Asset(collection).setContractURI(uri_);
  }
}
