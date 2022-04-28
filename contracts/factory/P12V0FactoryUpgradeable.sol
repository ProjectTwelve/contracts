// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './interfaces/IUniswapV2Router02.sol';
import './interfaces/IP12V0FactoryUpgradeable.sol';
import './interfaces/IUniswapV2Pair.sol';
import './interfaces/IUniswapV2Factory.sol';
import '@openzeppelin/contracts/utils/math/SafeMath.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import './P12V0ERC20.sol';

import './interfaces/IP12Mine.sol';
import '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';
import '@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol';

// import "hardhat/console.sol";

contract P12V0FactoryUpgradeable is
  Initializable,
  UUPSUpgradeable,
  IP12V0FactoryUpgradeable,
  OwnableUpgradeable,
  ReentrancyGuardUpgradeable
{
  using SafeMath for uint256;
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
  bytes32 internal init_hash;

  /**
   * @dev struct of each mint request
   */
  struct MintCoinInfo {
    uint256 amount;
    uint256 unlockTimestamp;
    bool executed;
  }

  uint256 internal addLiquidityEffectiveTime;

  /**
   * @dev p12 staking contract
   */
  address public p12mine;

  // gameId => developer address
  mapping(string => address) public allGames;
  // gameCoinAddress => gameId
  mapping(address => string) public allGameCoins;
  // gameCoinAddress => declareMintId => MintCoinInfo
  mapping(address => mapping(bytes32 => MintCoinInfo)) public coinMintRecords;
  // gameCoinAddress => declareMintId
  mapping(address => bytes32) public preMintIds;

  function initialize(
    address _p12,
    address _uniswapFactory,
    address _uniswapRouter,
    uint256 _effectiveTime
  ) public initializer {
    __Ownable_init();
    p12 = _p12;
    uniswapFactory = _uniswapFactory;
    uniswapRouter = _uniswapRouter;
    init_hash = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;
    addLiquidityEffectiveTime = _effectiveTime;
    IERC20(p12).approve(uniswapRouter, type(uint256).max);
    __ReentrancyGuard_init_unchained();
  }

  function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

  // set p12mine contract address
  function setInfo(address _p12mine) public virtual onlyOwner {
    require(_p12mine != address(0), 'address cannot be zero');

    p12mine = _p12mine;
  }

  /**
   * @dev create binding between game and developer, only called by p12 backend
   */
  function register(string memory gameId, address developer) external virtual override onlyOwner {
    allGames[gameId] = developer;
    emit RegisterGame(gameId, developer);
  }

  /**
   * @dev developer first create their game coin
   */
  function create(
    string memory name_,
    string memory symbol_,
    string memory gameId,
    string memory gameCoinIconUrl,
    uint256 amountGameCoin,
    uint256 amountP12
  ) public virtual override nonReentrant returns (address gameCoinAddress) {
    require(msg.sender == allGames[gameId], 'FORBIDDEN: have no permit to create game coin');
    require(amountP12 > 0, 'FORBIDDEN: not enough p12');
    gameCoinAddress = _create(name_, symbol_, gameId, gameCoinIconUrl, amountGameCoin);
    uint256 amountGameCoinDesired = amountGameCoin / 2;

    IERC20(p12).transferFrom(msg.sender, address(this), amountP12);

    P12V0ERC20(gameCoinAddress).approve(uniswapRouter, amountGameCoinDesired);

    uint256 liquidity0;
    (, , liquidity0) = IUniswapV2Router02(uniswapRouter).addLiquidity(
      p12,
      gameCoinAddress,
      amountP12,
      amountGameCoinDesired,
      amountP12,
      amountGameCoinDesired,
      address(p12mine),
      getBlockTimestamp() + addLiquidityEffectiveTime
    );
    //get pair contract address
    address pair = IUniswapV2Factory(uniswapFactory).getPair(p12, gameCoinAddress);

    // check address
    require(pair != address(0), 'P12V0FactoryUpgradeableV2::pair address error');

    // get lpToken value
    uint256 liquidity1 = IUniswapV2Pair(pair).balanceOf(address(p12mine));
    require(liquidity0 == liquidity1, 'P12V0FactoryUpgradeableV2::liquidity0 should equal liquidity1');

    // new staking pool
    IP12Mine(p12mine).createPool(pair, false);

    //
    IP12Mine(p12mine).addLpTokenInfoForGameCreator(pair, msg.sender);

    allGameCoins[gameCoinAddress] = gameId;
    emit CreateGameCoin(gameCoinAddress, gameId, amountP12);
    return gameCoinAddress;
  }

  /**
   * @dev function to create a game coin contract
   */
  function _create(
    string memory name_,
    string memory symbol_,
    string memory gameId,
    string memory gameCoinIconUrl,
    uint256 amountGameCoin
  ) internal virtual returns (address gameCoinAddress) {
    P12V0ERC20 gameCoin = new P12V0ERC20(name_, symbol_, gameId, gameCoinIconUrl, amountGameCoin);
    gameCoinAddress = address(gameCoin);
  }

  /**
   * @dev if developer want to mint after create coin, developer must declare first
   */
  function declareMintCoin(
    string memory gameId,
    address gameCoinAddress,
    uint256 amountGameCoin
  ) public virtual override nonReentrant returns (bool success) {
    require(msg.sender == allGames[gameId], 'FORBIDDEN: have no permission');
    require(compareStrings(allGameCoins[gameCoinAddress], gameId), 'FORBIDDEN');
    // Set the correct unlock time
    uint256 time;
    uint256 currentTimestamp = getBlockTimestamp();
    bytes32 _preMintId = preMintIds[gameCoinAddress];
    uint256 lastUnlockTimestamp = coinMintRecords[gameCoinAddress][_preMintId].unlockTimestamp;
    if (currentTimestamp >= lastUnlockTimestamp) {
      time = currentTimestamp;
    } else {
      time = lastUnlockTimestamp;
    }

    // minting fee for p12
    uint256 p12Fee = getMintFee(gameCoinAddress, amountGameCoin);
    // require(p12Needed < amountP12, "p12 not enough");

    // transfer the p12 to this contract
    ERC20(p12).transferFrom(msg.sender, address(this), p12Fee);

    uint256 delayD = getMintDelay(gameCoinAddress, amountGameCoin);

    bytes32 mintId = _hashOperation(gameCoinAddress, msg.sender, amountGameCoin, time, init_hash);
    coinMintRecords[gameCoinAddress][mintId] = MintCoinInfo(amountGameCoin, delayD + time, false);

    emit DeclareMint(mintId, gameCoinAddress, amountGameCoin, delayD + time, p12Fee);

    return true;
  }

  /**
   * @dev compare two string and judge whether they are the same
   */
  function compareStrings(string memory a, string memory b) internal pure virtual returns (bool) {
    return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
  }

  /**
   * @dev hash function to general mintId
   */
  function _hashOperation(
    address gameCoinAddress,
    address declarer,
    uint256 amount,
    uint256 timestamp,
    bytes32 salt
  ) internal virtual returns (bytes32 hash) {
    bytes32 preMintId = preMintIds[gameCoinAddress];

    bytes32 preMintIdNew = keccak256(abi.encode(gameCoinAddress, declarer, amount, timestamp, preMintId, salt));
    preMintIds[gameCoinAddress] = preMintIdNew;
    return preMintIdNew;
  }

  /**
   * @dev when time is up, anyone can call this function to make the mint executed
   */
  function executeMint(address gameCoinAddress, bytes32 mintId) external virtual override nonReentrant returns (bool) {
    // check if it has been executed
    require(coinMintRecords[gameCoinAddress][mintId].executed == false, 'this mint has been executed');

    uint256 time = getBlockTimestamp();

    // check that the current time is greater than the unlock time
    require(time > coinMintRecords[gameCoinAddress][mintId].unlockTimestamp, "It's not time to Mint");

    // Modify status
    coinMintRecords[gameCoinAddress][mintId].executed = true;

    // transfer the gameCoin to this contract first

    P12V0ERC20(gameCoinAddress).mint(address(this), coinMintRecords[gameCoinAddress][mintId].amount);

    emit ExecuteMint(mintId, gameCoinAddress, msg.sender);

    return true;
  }

  function withdraw(
    address userAddress,
    address gameCoinAddress,
    uint256 amountGameCoin
  ) external virtual override onlyOwner returns (bool) {
    P12V0ERC20(gameCoinAddress).transfer(userAddress, amountGameCoin);
    emit Withdraw(userAddress, gameCoinAddress, amountGameCoin);
    return true;
  }

  /**
   * @dev calculate the MintFee in P12
   */
  function getMintFee(address gameCoinAddress, uint256 amountGameCoin)
    public
    view
    virtual
    override
    returns (uint256 amountP12)
  {
    uint256 gameCoinReserved;
    uint256 p12Reserved;
    if (p12 < gameCoinAddress) {
      (p12Reserved, gameCoinReserved, ) = IUniswapV2Pair(IUniswapV2Factory(uniswapFactory).getPair(gameCoinAddress, p12))
        .getReserves();
    } else {
      (gameCoinReserved, p12Reserved, ) = IUniswapV2Pair(IUniswapV2Factory(uniswapFactory).getPair(gameCoinAddress, p12))
        .getReserves();
    }

    // overflow when p12Reserved * amountGameCoin > 2^256 ~= 10^77
    amountP12 = p12Reserved.mul(amountGameCoin).div((gameCoinReserved * 100));

    return amountP12;
  }

  /**
   * @dev linear function to calculate the delay time
   */
  function getMintDelay(address gameCoinAddress, uint256 amountGameCoin) public view virtual override returns (uint256 time) {
    time = amountGameCoin.mul(delayK).div(P12V0ERC20(gameCoinAddress).totalSupply()) + 4 * delayB;
    return time;
  }

  /**
   * @dev get current block's timestamp
   */
  function getBlockTimestamp() internal view virtual returns (uint256) {
    return block.timestamp;
  }

  /**
   * @dev set linear function's K parameter
   */
  function setDelayK(uint256 _delayK) public virtual override onlyOwner returns (bool) {
    delayK = _delayK;
    return true;
  }

  /**
   * @dev set linear function's B parameter
   */
  function setDelayB(uint256 _delayB) public virtual override onlyOwner returns (bool) {
    delayB = _delayB;
    return true;
  }
}
