import { ethers } from 'hardhat';
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';
import { string } from 'hardhat/internal/core/params/argumentTypes';

async function main() {
  let admin: SignerWithAddress;
  let user: SignerWithAddress;
  [admin, user] = await ethers.getSigners();
  let gameCoinAddress;

  console.log(admin.address, user.address);

  // connect P12FactoryProxy
  const P12V0FactoryUpgradeable = await ethers.getContractFactory('P12V0FactoryUpgradeable');
  const P12FactoryProxy = await P12V0FactoryUpgradeable.attach('0x395FAbef71433280f85f79ad43f99E3cC040af5C');

  // connect P12
  const P12 = await ethers.getContractFactory('P12Token');
  const P12Instance = await P12.attach('0x2844B158Bcffc0aD7d881a982D464c0ce38d8086');

  // connect uniFactory
  const UNISWAPV2FACTORY = await ethers.getContractFactory('UniswapV2Factory');
  const UniswapV2Factory = await UNISWAPV2FACTORY.attach('0x913d71546cC9FBB06b6F9d2ADEb0C58EFEF7a690');

  // connect router
  const UniRouter = await ethers.getContractFactory('UniswapV2Router02');
  const uniswapV2Router = await UniRouter.attach('0x7320C150D5fd661Fb1fB7af19a6337F3d099b41f');

  // register
  const gameId = '1101';
  await P12FactoryProxy.connect(admin).register(gameId, user.address);

  // create gameCoin
  await P12Instance.connect(admin).transfer(user.address, BigInt(3) * 10n ** 18n);
  const name = 'GameCoin';
  const symbol = 'GC';
  // const gameId = "1101";
  const gameCoinIconUrl =
    'https://images.weserv.nl/?url=https://i0.hdslb.com/bfs/article/87c5b43b19d4065f837f54637d3932e680af9c9b.jpg';
  const amountGameCoin = BigInt(10) * BigInt(10) ** 18n;
  const amountP12 = BigInt(1) * BigInt(10) ** 18n;

  await P12Instance.connect(user).approve(P12FactoryProxy.address, amountP12);
  const createInfo = await P12FactoryProxy.connect(user).create(
    name,
    symbol,
    gameId,
    gameCoinIconUrl,
    amountGameCoin,
    amountP12,
  );
  // console.log("createInfo", createInfo);
  (await createInfo.wait()).events!.forEach((x) => {
    if (x.event === 'CreateGameCoin') {
      gameCoinAddress = x.args!.gameCoinAddress;
    }
  });
  console.log('gameCoinAddress is :', gameCoinAddress);

  // get pair
  const P12V0ERC20 = await ethers.getContractFactory('P12V0ERC20');
  const gameCoin = await P12V0ERC20.attach(String(gameCoinAddress));
  const pairAddress = await UniswapV2Factory.getPair(String(gameCoinAddress), P12Instance.address);
  const UNISWAPV2PAIR = await ethers.getContractFactory('UniswapV2Pair');
  const pool = await UNISWAPV2PAIR.attach(pairAddress);

  console.log('gameCoin address: ', gameCoinAddress);
  console.log('gameCoin name: ', await gameCoin.name());
  console.log('gameCoin symbol: ', await gameCoin.symbol());
  console.log('gameCoin gameId: ', await gameCoin.gameId());
  console.log('gameCoin Icon url: ', await gameCoin.gameCoinIconUrl());
  console.log('P12-GameCoin Pair Address: ', pairAddress);
  console.log('P12-GameCoin Pair Reserves: ', await pool.getReserves());
  console.log('gameCoin create successfully!');

  // set delay
  await P12FactoryProxy.connect(admin).setDelayK(1);
  await P12FactoryProxy.connect(admin).setDelayB(1);
  console.log('p12Factory delay K: ', await P12FactoryProxy.delayK());
  console.log('p12Factory delay B: ', await P12FactoryProxy.delayB());
  console.log('set delay variable successfully!');
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
