// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.19;

import { INonfungiblePositionManager } from 'src/interfaces/external/uniswap/INonfungiblePositionManager.sol';
import { IERC20Upgradeable } from '@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol';
import { ClonesUpgradeable } from '@openzeppelin/contracts-upgradeable/proxy/ClonesUpgradeable.sol';
import { Ownable2StepUpgradeable } from '@openzeppelin/contracts-upgradeable/access/Ownable2StepUpgradeable.sol';
import { UUPSUpgradeable } from '@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol';
import { ReentrancyGuardUpgradeable } from '@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol';
import { PausableUpgradeable } from '@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol';
import { SafeERC20Upgradeable } from '@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol';
import { IERC20Upgradeable } from '@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol';
import { IP12CoinFactoryUpgradeable } from 'src/coinFactory/interfaces/IP12CoinFactoryUpgradeable.sol';
import { IP12MineUpgradeable } from '../staking/interfaces/IP12MineUpgradeable.sol';
import { P12CoinFactoryStorage } from './P12CoinFactoryStorage.sol';
import { IP12GameCoin } from 'src/coinFactory/interfaces/IP12GameCoin.sol';
import { CommonError } from 'src/libraries/CommonError.sol';

contract P12CoinFactoryUpgradeable is
  P12CoinFactoryStorage,
  UUPSUpgradeable,
  IP12CoinFactoryUpgradeable,
  Ownable2StepUpgradeable,
  ReentrancyGuardUpgradeable,
  PausableUpgradeable
{
  using SafeERC20Upgradeable for IERC20Upgradeable;

  /**
   * @dev create binding between game and developer, only called by p12 backend
   * @param gameId game id
   * @param developer developer address, who own this game
   */
  function register(uint256 gameId, address developer) external virtual override onlySigner {
    if (address(developer) == address(0)) revert CommonError.ZeroAddressSet();
    gameDev[gameId] = developer;
    emit RegisterGame(gameId, developer);
  }

  /**
   * @dev developer first create their game coin
   * @param name new game coin's name
   * @param symbol game coin's symbol
   * @param gameId the game's id
   * @param amountGameCoin how many coin first mint
   * @param priceSqrtX96 X game coin per p12
   * @return gameCoinAddress the address of the new game coin
   */
  function create(
    string calldata name,
    string calldata symbol,
    string calldata uri,
    uint256 gameId,
    uint256 amountGameCoin,
    uint256 amountP12,
    uint160 priceSqrtX96
  ) external virtual override nonReentrant whenNotPaused returns (address gameCoinAddress) {
    if (msg.sender != gameDev[gameId]) revert CommonError.NotGameDeveloper(msg.sender, gameId);
    gameCoinAddress = _create(name, symbol, uri, gameId, amountGameCoin);

    uint256 amountGameCoinDesired = amountGameCoin / 2;

    address token0;
    uint256 token0Amount;
    address token1;
    uint256 token1Amount;

    if (address(gameCoinAddress) < p12) {
      token0 = address(gameCoinAddress);
      token0Amount = amountGameCoinDesired;
      token1 = p12;
      token1Amount = amountP12;
    } else {
      token0 = p12;
      token0Amount = amountP12;
      token1 = address(gameCoinAddress);
      token1Amount = amountGameCoinDesired;
    }

    // transfer P12 to address this for later liquidity create
    IERC20Upgradeable(p12).safeTransferFrom(msg.sender, address(this), amountP12);

    // aprove gamecoin
    IERC20Upgradeable(gameCoinAddress).approve(address(uniswapPosManager), type(uint256).max);

    // fee 0.3% tickSpacing 60
    uniswapPosManager.createAndInitializePoolIfNecessary(token0, token1, 3000, priceSqrtX96);

    // create initial liquidity and givev nft to msg.sender
    uniswapPosManager.mint(
      INonfungiblePositionManager.MintParams(
        token0,
        token1,
        3000,
        // Tick range should be an integer multiple of the tick space
        -88680,
        88680,
        token0Amount,
        token1Amount,
        0,
        0,
        msg.sender,
        block.timestamp + 1
      )
    );

    coinGameIds[gameCoinAddress] = gameId;
    emit CreateGameCoin(gameCoinAddress, gameId, amountP12);
    return gameCoinAddress;
  }

  /**
   * @dev if developer want to mint after create coin, developer must declare first
   * @param gameId game's id
   * @param gameCoinAddress game coin's address
   * @param amountGameCoin how many developer want to mint
   * @param success whether the operation success
   */
  function queueMintCoin(
    uint256 gameId,
    address gameCoinAddress,
    uint256 amountGameCoin
  ) external virtual override nonReentrant whenNotPaused returns (bool success) {
    if (msg.sender != gameDev[gameId]) revert CommonError.NotGameDeveloper(msg.sender, gameId);
    if (coinGameIds[gameCoinAddress] != gameId) revert MisMatchCoinWithGameId(gameCoinAddress, gameId);
    // Set the correct unlock time
    uint256 time;
    uint256 currentTimestamp = _getBlockTimestamp();
    bytes32 _preMintId = preMintIds[gameCoinAddress];
    uint256 lastUnlockTimestamp = coinMintRecords[gameCoinAddress][_preMintId].unlockTimestamp;
    if (currentTimestamp >= lastUnlockTimestamp) {
      time = currentTimestamp;
    } else {
      time = lastUnlockTimestamp;
    }

    // minting fee for p12
    uint256 p12Fee = getMintFee(gameCoinAddress, amountGameCoin);

    // transfer the p12 to this contract
    IERC20Upgradeable(p12).safeTransferFrom(msg.sender, address(this), p12Fee);

    uint256 delayD = getMintDelay(address(gameCoinAddress), amountGameCoin);

    bytes32 mintId = _hashOperation(gameCoinAddress, msg.sender, amountGameCoin, time);
    coinMintRecords[gameCoinAddress][mintId] = MintCoinInfo(amountGameCoin, delayD + time, false);

    emit QueueMintCoin(mintId, gameCoinAddress, amountGameCoin, delayD + time, p12Fee);

    return true;
  }

  /**
   * @dev when time is up, anyone can call this function to make the mint executed
   * @param gameCoinAddress address of the game coin
   * @param mintId a unique id to identify a mint, developer can get it after declare
   * @return bool whether the operation success
   */
  function executeMintCoin(
    address gameCoinAddress,
    bytes32 mintId
  ) external virtual override nonReentrant whenNotPaused returns (bool) {
    if (coinMintRecords[gameCoinAddress][mintId].unlockTimestamp == 0) revert NonExistenceMintId(mintId);
    // check if it has been executed
    if (coinMintRecords[gameCoinAddress][mintId].executed) revert ExecutedMint(mintId);

    uint256 time = _getBlockTimestamp();

    // check that the current time is greater than the unlock time
    if (time <= coinMintRecords[gameCoinAddress][mintId].unlockTimestamp) revert NotTimeToMint(mintId);

    // Modify status
    coinMintRecords[gameCoinAddress][mintId].executed = true;

    // transfer the gameCoin to this contract first

    IP12GameCoin(gameCoinAddress).mint(address(this), coinMintRecords[gameCoinAddress][mintId].amount);

    emit ExecuteMintCoin(mintId, gameCoinAddress, msg.sender);

    return true;
  }

  /**
   * @notice called when user want to withdraw his game coin from custodian address
   * @param userAddress user's address
   * @param gameCoinAddress gameCoin's address
   * @param amountGameCoin how many user want to withdraw
   */
  function withdraw(
    address userAddress,
    address gameCoinAddress,
    uint256 amountGameCoin
  ) external virtual override onlySigner returns (bool) {
    IERC20Upgradeable(address(gameCoinAddress)).safeTransfer(userAddress, amountGameCoin);
    emit Withdraw(userAddress, gameCoinAddress, amountGameCoin);
    return true;
  }

  //============ Public ============
  function pause() public onlyOwner {
    _pause();
  }

  function unpause() public onlyOwner {
    _unpause();
  }

  function initialize(
    address owner_,
    address p12_,
    INonfungiblePositionManager uniswapPosManager_,
    address gameCoinImpl_
  ) public initializer {
    if (address(p12_) == address(0)) revert CommonError.ZeroAddressSet();
    if (address(uniswapPosManager_) == address(0)) revert CommonError.ZeroAddressSet();

    p12 = p12_;
    uniswapPosManager = uniswapPosManager_;
    gameCoinImpl = gameCoinImpl_;
    IERC20Upgradeable(p12).safeApprove(address(uniswapPosManager_), type(uint256).max);
    __ReentrancyGuard_init_unchained();
    __Pausable_init_unchained();
    __Ownable2Step_init();
    _transferOwnership(owner_);
  }

  /**
   * @dev set linear function's K parameter
   * @param newDelayK new K parameter
   */
  function setDelayK(uint256 newDelayK) public virtual override onlyOwner returns (bool) {
    uint256 oldDelayK = delayK;
    delayK = newDelayK;
    emit SetDelayK(oldDelayK, delayK);
    return true;
  }

  /**
   * @dev set linear function's B parameter
   * @param newDelayB new B parameter
   */
  function setDelayB(uint256 newDelayB) public virtual override onlyOwner returns (bool) {
    uint256 oldDelayB = delayB;
    delayB = newDelayB;
    emit SetDelayB(oldDelayB, delayB);
    return true;
  }

  function getGameDev(uint256 gameId) public view override returns (address) {
    return gameDev[gameId];
  }

  /**
   * @dev calculate the MintFee in P12
   */
  function getMintFee(
    address gameCoinAddress,
    uint256 amountGameCoin
  ) public view virtual override returns (uint256 amountP12) {
    // uint256 gameCoinReserved;
    // uint256 p12Reserved;
    // if (p12 < address(gameCoinAddress)) {
    //   (p12Reserved, gameCoinReserved, ) = IUniswapV2Pair(uniswapFactory.getPair(address(gameCoinAddress), p12)).getReserves();
    // } else {
    //   (gameCoinReserved, p12Reserved, ) = IUniswapV2Pair(uniswapFactory.getPair(address(gameCoinAddress), p12)).getReserves();
    // }
    // // overflow when p12Reserved * amountGameCoin > 2^256 ~= 10^77
    // amountP12 = (p12Reserved * amountGameCoin) / (gameCoinReserved * 100);
    // return amountP12;
  }

  /**
   * @dev linear function to calculate the delay time
   * @dev delayB is the minimum delay period, even someone mint zero token,
   * @dev there still be delayB period before someone can really mint zero token
   * @dev delayK is the parameter to take the ratio of new amount in to account
   * @dev For example, the initial supply of Game Coin is 100k. If developer want
   * @dev to mint 100k, developer needs to real mint it after `delayK + delayB`. If
   * @dev developer want to mint 200k, developer has to real mint it after `2DelayK +
   * @dev delayB`.
          ^
        t +            /
          |          /
          |        /
      2k+b|      /
          |    /
       k+b|  / 
          |/ 
         b|
          0----p---2p---------> amount
            
   */
  function getMintDelay(address gameCoinAddress, uint256 amountGameCoin) public view virtual override returns (uint256 time) {
    time = (amountGameCoin * delayK) / (IERC20Upgradeable(gameCoinAddress).totalSupply()) + delayB;
    return time;
  }

  //============ Internal ============

  /**
   * @dev function to create a game coin contract
   * @param name game coin name
   * @param symbol game coin symbol
   * @param gameId game id
   * @param amountGameCoin how many for first mint
   */
  function _create(
    string calldata name,
    string calldata symbol,
    string calldata uri,
    uint256 gameId,
    uint256 amountGameCoin
  ) internal virtual returns (address gameCoinAddress) {
    bytes32 salt = keccak256(abi.encode(gameId, ++_gameCoinCount[gameId]));
    // erc1167 deterministic clone
    gameCoinAddress = ClonesUpgradeable.cloneDeterministic(gameCoinImpl, salt);
    // initialize
    IP12GameCoin(gameCoinAddress).initialize(address(this), name, symbol, uri, gameId);
    // mint initial amount
    IP12GameCoin(gameCoinAddress).mint(address(this), amountGameCoin);
  }

  /**
   * @dev hash function to general mintId
   * @param gameCoinAddress game coin address
   * @param declarer address which declare to mint game coin
   * @param amount how much to mint
   * @param timestamp time when declare
   * @return hash mintId
   */
  function _hashOperation(
    address gameCoinAddress,
    address declarer,
    uint256 amount,
    uint256 timestamp
  ) internal virtual returns (bytes32 hash) {
    bytes32 preMintId = preMintIds[gameCoinAddress];

    bytes32 preMintIdNew = keccak256(abi.encode(gameCoinAddress, declarer, amount, timestamp, preMintId));
    preMintIds[gameCoinAddress] = preMintIdNew;
    return preMintIdNew;
  }

  /** upgrade function */
  function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

  /**
   * @dev get a specific game next coin's deterministic address
   * @param gameId off chain game Id
   */
  function getGameNextCoinAddress(uint256 gameId) public view returns (address gameCoinAddress) {
    bytes32 salt = keccak256(abi.encode(gameId, _gameCoinCount[gameId] + 1));
    gameCoinAddress = ClonesUpgradeable.predictDeterministicAddress(gameCoinImpl, salt);
  }

  /**
   * @dev get current block's timestamp
   */
  function _getBlockTimestamp() internal view virtual returns (uint256) {
    return block.timestamp;
  }

  function _verifySigner() internal view {
    if (!signers[msg.sender]) {
      revert NotP12Signer();
    }
  }

  function _verifyGameDev(address token) internal view {
    if (msg.sender != gameDev[coinGameIds[token]]) revert CommonError.NotGameDeveloper(msg.sender, coinGameIds[token]);
  }

  /**
   * @dev compare two string and judge whether they are the same
   */
  function _compareStrings(string memory a, string memory b) internal pure virtual returns (bool) {
    return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
  }

  // ============= Modifier ================
  modifier onlySigner() {
    _verifySigner();
    _;
  }

  modifier onlyGameDev(address token) {
    _verifyGameDev(token);
    _;
  }
}
