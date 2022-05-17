// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.13;

import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';
import '@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol';
import '@openzeppelin/contracts/utils/cryptography/ECDSA.sol';
import './P12Asset.sol';
import '../factory/P12V0FactoryUpgradeable.sol';
import './interfaces/IP12AssetFactoryUpgradable.sol';
import './P12AssetFactoryStorage.sol';

contract P12AssetFactoryUpgradable is
  P12AssetFactoryStorage,
  IP12AssetFactoryUpgradable,
  Initializable,
  ReentrancyGuardUpgradeable,
  OwnableUpgradeable,
  PausableUpgradeable,
  UUPSUpgradeable
{
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
    require(P12V0FactoryUpgradeable(p12factory).allGames(gameId) == msg.sender, 'P12Asset: not game developer');
    _;
  }

  modifier onlyCollectionDeveloper(address collection) {
    require(P12V0FactoryUpgradeable(p12factory).allGames(registry[collection]) == msg.sender, 'P12Asset: not game developer');
    _;
  }

  /**
   * @dev create Collection
   * @param gameId a off-chain game id
   * @param contractURI contract-level metadata uri
   */
  function createCollection(string calldata gameId, string calldata contractURI)
    public
    override
    onlyDeveloper(gameId)
    whenNotPaused
  {
    P12Asset collection = new P12Asset(contractURI);
    // record creator
    registry[address(collection)] = gameId;

    emit CollectionCreated(address(collection), msg.sender);
  }

  /**
   * @dev create asset and mint to msg.sender address
   * @param collection which collection want to create
   * @param amount amount of asset
   * @param uri new asset's metadata uri
   */
  function createAssetAndMint(
    address collection,
    uint256 amount,
    string calldata uri
  ) public override onlyCollectionDeveloper(collection) whenNotPaused nonReentrant {
    // create
    uint256 tokenId = P12Asset(collection).create(amount, uri);
    // mint to developer address
    P12Asset(collection).mint(msg.sender, tokenId, amount, new bytes(0));

    emit SftCreated(address(collection), tokenId, amount);
  }

  /**
   * @dev update Collection Uri
   * @param collection collection address
   * @param newUri new Contract-level metadata uri
   */
  function updateCollectionUri(address collection, string calldata newUri)
    public
    override
    onlyCollectionDeveloper(collection)
    whenNotPaused
  {
    P12Asset(collection).setContractURI(newUri);
  }

  /**
   * @dev update Sft Uri
   * @param collection collection address
   * @param tokenId token id
   * @param newUri new metadata uri
   */
  function updateSftUri(
    address collection,
    uint256 tokenId,
    string calldata newUri
  ) public override onlyCollectionDeveloper(collection) whenNotPaused {
    P12Asset(collection).setUri(tokenId, newUri);
  }
}
