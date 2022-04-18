// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './interfaces/IUniswapV2Router02.sol';
import './interfaces/IP12V0Factory.sol';
import './interfaces/IUniswapV2Pair.sol';
import './interfaces/IUniswapV2Factory.sol';
import '../libraries/FullMath.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import './P12V0ERC20.sol';

// import "hardhat/console.sol";

contract P12V0Factory is IP12V0Factory {
  // p12 token address
  address public immutable p12;
  // uniswap router address
  address public immutable router;
  // uniswap factory address
  address public immutable uniswapFactory;
  // delay k and b
  uint256 public delayK;
  uint256 public delayB;

  // a random salt
  bytes32 internal randSalt = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;

  // gameCoin address => gameId
  mapping(address => string) public allGameCoins;
  // gameId => developer
  mapping(string => address) public allGames;
  // reentrant lock
  mapping(address => bool) public coinsMintLock;

  //gameCoin=>mintId=>MintCoinInfo
  mapping(address => mapping(bytes32 => MintCoinInfo)) public coinsMintRecord;

  //gameCoin=> mintId
  mapping(address => bytes32) public preMintIds;

  // record of issued currency
  struct MintCoinInfo {
    uint256 amount;
    uint256 unlockTimestamp;
    bool executed;
  }

  // Administrator address
  address public admin;
  // Escrow contract address
  address public custodian;

  uint256 private unlocked = 1;
  // reentrant lock
  modifier lock() {
    require(unlocked == 1, 'P12Factory: LOCKED');
    unlocked = 0;
    _;
    unlocked = 1;
  }

  // identity check
  modifier onlyAdmin() {
    require(msg.sender == admin, 'FORBIDDEN::caller must be admin');
    _;
  }

  constructor(
    address _admin,
    address _custodian,
    address _router,
    address _p12,
    address _uniswapFactory
  ) {
    admin = _admin;
    custodian = _custodian;
    router = _router;
    p12 = _p12;
    uniswapFactory = _uniswapFactory;
    delayK = 60;
    delayB = 60;
  }

  function register(string memory gameId, address developer) external override onlyAdmin {
    allGames[gameId] = developer;
    emit RegisterGame(gameId, developer);
  }

  function create(
    string memory name_,
    string memory symbol_,
    string memory gameId,
    string memory gameCoinIconUrl,
    uint256 amountGameCoin,
    uint256 amountP12
  ) public override lock returns (address gameCoinAddress) {
    require(msg.sender == allGames[gameId], 'FORBIDDEN: have no permit to create game coin');
    require(amountP12 > 0, 'FORBIDDEN: not enough p12');
    gameCoinAddress = _create(name_, symbol_, gameId, gameCoinIconUrl, amountGameCoin);
    uint256 amountGameCoinDesired = amountGameCoin / 2;

    ERC20(p12).transferFrom(msg.sender, address(this), amountP12);

    ERC20(p12).approve(router, amountP12);

    P12V0ERC20(gameCoinAddress).approve(router, amountGameCoinDesired);

    IUniswapV2Router02(router).addLiquidity(
      p12,
      gameCoinAddress,
      amountP12,
      amountGameCoinDesired,
      amountP12,
      amountGameCoinDesired,
      msg.sender,
      2641387311
    );

    // allGameCoins[gameId].push(gameCoinAddress);
    allGameCoins[gameCoinAddress] = gameId;
    emit CreateGameCoin(gameCoinAddress, gameId, amountP12);
    return gameCoinAddress;
  }

  function _create(
    string memory name_,
    string memory symbol_,
    string memory gameId,
    string memory gameCoinIconUrl,
    uint256 amountGameCoin
  ) internal returns (address gameCoinAddress) {
    P12V0ERC20 gameCoin = new P12V0ERC20(name_, symbol_, gameId, gameCoinIconUrl, amountGameCoin);
    gameCoinAddress = address(gameCoin);
  }

  function declareMintCoin(
    string memory gameId,
    address gameCoinAddress,
    uint256 amountGameCoin
  ) public override lock returns (bool success) {
    require(msg.sender == allGames[gameId], 'FORBIDDEN: have no permission');
    require(compareStrings(allGameCoins[gameCoinAddress], gameId), 'FORBIDDEN');
    // Set the correct unlock time
    uint256 time;
    uint256 currentTimestamp = getBlockTimestamp();
    bytes32 _preMintId = preMintIds[gameCoinAddress];
    uint256 lastUnlockTimestamp = coinsMintRecord[gameCoinAddress][_preMintId].unlockTimestamp;
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
    uint256 delayD = FullMath.mulDiv(amountGameCoin, delayK, P12V0ERC20(gameCoinAddress).totalSupply()) + 4 * delayB;

    bytes32 mintId = _hashOperation(gameCoinAddress, msg.sender, amountGameCoin, time, randSalt);

    coinsMintRecord[gameCoinAddress][mintId] = MintCoinInfo(amountGameCoin, delayD + time, false);

    emit DeclareMint(mintId, gameCoinAddress, amountGameCoin, delayD + time, p12Fee);

    return true;
  }

  function compareStrings(string memory a, string memory b) public pure returns (bool) {
    return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
  }

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
        execute minting active
     */

  function executeMint(address gameCoinAddress, bytes32 mintId) external override returns (bool) {
    //  check lock
    require(coinsMintLock[gameCoinAddress] == false, 'achieve this coin locked');

    coinsMintLock[gameCoinAddress] == true;

    // check
    require(coinsMintRecord[gameCoinAddress][mintId].executed == false, 'this mint has been executed');

    // check if it has been executed
    uint256 time = getBlockTimestamp();

    // check that the current time is greater than the unlock time
    require(time > coinsMintRecord[gameCoinAddress][mintId].unlockTimestamp, "It's not time to Mint");

    // Modify status
    coinsMintRecord[gameCoinAddress][mintId].executed = true;

    // transfer the gameCoin to this contract first
    P12V0ERC20(gameCoinAddress).mint(address(this), coinsMintRecord[gameCoinAddress][mintId].amount);

    // release lock
    coinsMintLock[gameCoinAddress] == false;

    emit ExecuteMint(mintId, gameCoinAddress, msg.sender);

    return true;
  }

  function withdraw(
    address userAddress,
    address gameCoinAddress,
    uint256 amountGameCoin
  ) external override onlyAdmin returns (bool) {
    //require(msg.sender == admin, "FORBIDDEN: have no permission");
    P12V0ERC20(gameCoinAddress).transfer(userAddress, amountGameCoin);
    emit Withdraw(userAddress, gameCoinAddress, amountGameCoin);
    return true;
  }

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
    // console.log("mint fee mint fee", (p12Reserved * amountGameCoin * decimals() * 10 ** 18) / (gameCoinReserved * 100));
    amountP12 = FullMath.mulDiv(p12Reserved, amountGameCoin, (gameCoinReserved * 100));
    return amountP12;
  }

  function getMintDelay(address gameCoinAddress, uint256 amountGameCoin) external view override returns (uint256 time) {
    time = FullMath.mulDiv(amountGameCoin, delayK, P12V0ERC20(gameCoinAddress).totalSupply()) + 4 * delayB;
    return time;
  }

  function getBlockTimestamp() internal view returns (uint256) {
    // solium-disable-next-line security/no-block-members
    return block.timestamp;
  }

  function setCustodian(address _custodian) public virtual override onlyAdmin returns (bool) {
    //require(msg.sender == admin, "FORBIDDEN");
    custodian = _custodian;
    return true;
  }

  function setAdmin(address _admin) public virtual override onlyAdmin returns (bool) {
    //require(msg.sender == admin, "FORBIDDEN");
    admin = _admin;
    return true;
  }

  function setDelayK(uint256 _delayK) public virtual override onlyAdmin returns (bool) {
    //require(msg.sender == admin, "FORBIDDEN");
    delayK = _delayK;
    return true;
  }

  function setDelayB(uint256 _delayB) public virtual override onlyAdmin returns (bool) {
    //require(msg.sender == admin, "FORBIDDEN");
    delayB = _delayB;
    return true;
  }
}
