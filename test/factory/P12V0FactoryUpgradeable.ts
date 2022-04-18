import { ethers, upgrades } from 'hardhat';
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';
import { expect } from 'chai';
import {
  P12Token,
  P12V0ERC20,
  P12V0FactoryUpgradeable,
  P12V0FactoryUpgradeable2,
  UniswapV2Factory,
  UniswapV2Router02,
  // eslint-disable-next-line node/no-missing-import
} from '../../typechain';
import { Contract } from 'ethers';

// describe("deploy P12V0Factory ", function () {
//   before("get factories", async function () {
//     this.P12FactoryV0Upgradeable = await ethers.getContractFactory(
//       "P12V0FactoryUpgradeable"
//     );
//   });
//   it("p12factory deploy and upgrade", async function () {
//     const accounts = await ethers.getSigners();
//     const admin = accounts[0];
//     const developer = accounts[1];
//     // console.log("Admin address", admin.address);
//     // console.log("developer address", developer.address);
//     const p12 = "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266";
//     const uniswapFactory = "0x53457536bd7C93D91c1FC12214Fb8FF8E7D86315";
//     const uniswapRouter = "0xE76701C2fE67A56A03e1bEb88E8A954537C30b54";
//     const p12Factory = await upgrades.deployProxy(
//       this.P12FactoryV0Upgradeable,
//       [p12, uniswapFactory, uniswapRouter],
//       { kind: "uups" }
//     );
//     // console.log("original contract", await p12Factory.address);
//     // console.log(await p12Factory.owner());
//     await p12Factory.register("0001", developer.address);
//     // console.log(p12Factory.allGames["1101"]);
//     // console.log("p12Factory address is:", p12Factory.address);

//     // upgrade
//     const p12Factory2 = await ethers.getContractFactory(
//       "P12V0FactoryUpgradeable2"
//     );
//     const upgradeP12Factory = await upgrades.upgradeProxy(
//       p12Factory.address,
//       p12Factory2
//     );
//     // use some function  for test
//     await upgradeP12Factory.setName("River");
//     const name = await upgradeP12Factory.getName();

//     // call some old P12factory function for test
//     // console.log("game info is:", upgradeP12Factory.allGames["1101"]);

//     // console.log("upgradeP12Factory", upgradeP12Factory.address);
//     // console.log("name is:", name);
//   });
// });
describe('P12Factory', function () {
  let admin: SignerWithAddress;
  let developer: SignerWithAddress;
  let user: SignerWithAddress;
  let router: UniswapV2Router02;
  let p12: P12Token;
  let UniswapV2Factory: UniswapV2Factory;
  let p12Factory1: Contract;
  let p12Factory2: Contract;
  let gameCoinAddress: string;
  let gameCoin: P12V0ERC20;
  let mintId: string;
  let mintId2: string;

  this.beforeAll(async function () {
    // hardhat test account
    const accounts = await ethers.getSigners();
    admin = accounts[0];
    developer = accounts[1];
    user = accounts[2];
    // console.log('Admin address', admin.address);
    // console.log('developer address', developer.address);

    // deploy uniswap
    const UNISWAPV2ROUTER = await ethers.getContractFactory('UniswapV2Router02');
    const UNISWAPV2FACTORY = await ethers.getContractFactory('UniswapV2Factory');
    const WETH = await ethers.getContractFactory('WETH9');
    UniswapV2Factory = await UNISWAPV2FACTORY.connect(admin).deploy(admin.address);
    // console.log('UniswapV2Factory Address', UniswapV2Factory.address);
    // console.log('UniswapV2Factory INIT_CODE_PAIR_HASH', await UniswapV2Factory.INIT_CODE_PAIR_HASH());
    const weth = await WETH.deploy();
    // console.log('Weth Address', weth.address);
    router = await UNISWAPV2ROUTER.connect(admin).deploy(UniswapV2Factory.address, weth.address);
    // console.log('Router Address', router.address);
  });
  it('Should show p12 token deploy successfully!', async function () {
    // deploy p12token
    const ERC20 = await ethers.getContractFactory('P12Token');
    p12 = await ERC20.connect(admin).deploy('ProjectTwelve', 'P12', 1000n * 10n ** 18n);
    // console.log('P12 token deploy successfully!');
    // console.log('p12 token owner balance: ', await p12.balanceOf(admin.address));
  });

  it('Should show P12Factory contract deploy successful!', async function () {
    const P12FACTORY = await ethers.getContractFactory('P12V0FactoryUpgradeable');
    p12Factory1 = await upgrades.deployProxy(P12FACTORY, [p12.address, UniswapV2Factory.address, router.address], {
      kind: 'uups',
    });
    // console.log('p12Factory contract deploy successfully!');
    // console.log('p12Factory address: ', p12Factory1.address);
  });
  it('Should show developer register successfully', async function () {
    const gameId = '1101';
    await p12Factory1.connect(admin).register(gameId, developer.address);
    // console.log('developer register successfully!');
  });
  it('Give developer p12', async function () {
    await p12.connect(admin).transfer(developer.address, BigInt(3) * 10n ** 18n);
    // console.log('developer has number of p12', await p12.balanceOf(developer.address));
  });
  it('Should show gameCoin create successfully!', async function () {
    const name = 'GameCoin';
    const symbol = 'GC';
    const gameId = '1101';
    const gameCoinIconUrl =
      'https://images.weserv.nl/?url=https://i0.hdslb.com/bfs/article/87c5b43b19d4065f837f54637d3932e680af9c9b.jpg';
    const amountGameCoin = BigInt(10) * BigInt(10) ** 18n;
    const amountP12 = BigInt(1) * BigInt(10) ** 18n;

    await p12.connect(developer).approve(p12Factory1.address, amountP12);
    const createInfo = await p12Factory1
      .connect(developer)
      .create(name, symbol, gameId, gameCoinIconUrl, amountGameCoin, amountP12);

    (await createInfo.wait()).events!.forEach((x: { event: string; args: any }) => {
      if (x.event === 'CreateGameCoin') {
        gameCoinAddress = x.args!.gameCoinAddress;
      }
    });

    const P12V0ERC20 = await ethers.getContractFactory('P12V0ERC20');
    gameCoin = await P12V0ERC20.attach(gameCoinAddress);
    const pairAddress = await UniswapV2Factory.getPair(gameCoinAddress, p12.address);
    const UNISWAPV2PAIR = await ethers.getContractFactory('UniswapV2Pair');
    const pool = await UNISWAPV2PAIR.attach(pairAddress);

    // console.log('gameCoin address: ', gameCoinAddress);
    // console.log('gameCoin name: ', await gameCoin.name());
    // console.log('gameCoin symbol: ', await gameCoin.symbol());
    // console.log('gameCoin gameId: ', await gameCoin.gameId());
    // console.log('gameCoin Icon url: ', await gameCoin.gameCoinIconUrl());
    // console.log('P12-GameCoin Pair Address: ', pairAddress);
    // console.log('P12-GameCoin Pair Reserves: ', await pool.getReserves());
    // console.log('gameCoin create successfully!');
  });

  it('Should show set delay variable successfully! ', async function () {
    await p12Factory1.connect(admin).setDelayK(1);
    await p12Factory1.connect(admin).setDelayB(1);
    // console.log('p12Factory delay K: ', await p12Factory1.delayK());
    // console.log('p12Factory delay B: ', await p12Factory1.delayB());
    // console.log('set delay variable successfully!');
  });

  it('Check gameCoin mint fee', async function () {
    const price = await p12Factory1.getMintFee(gameCoinAddress, BigInt(30) * BigInt(10) ** 18n);
    // console.log('check gameCoin mint fee', price);
  });

  it('Check gameCoin mint delay time', async function () {
    // console.log('gameCoin mint delay time', await p12Factory1.getMintDelay(gameCoinAddress, BigInt(5) * BigInt(10) ** 18n));
  });
  it('Should show declare mint successfully!', async function () {
    const amountP12 = BigInt(6) * BigInt(10) ** 17n;
    // console.log(developer.address);
    await p12.connect(developer).approve(p12Factory1.address, amountP12);
    const tx = await p12Factory1.connect(developer).declareMintCoin('1101', gameCoinAddress, BigInt(5) * BigInt(10) ** 18n);
    (await tx.wait()).events!.forEach((x: { event: string; args: any }) => {
      if (x.event === 'DeclareMint') {
        mintId = x.args!.mintId;
      }
    });
    // console.log('mintId is: ', mintId);
  });

  it('Should show declare mint successfully!', async function () {
    const amountP12 = BigInt(6) * BigInt(10) ** 17n;
    // eslint-disable-next-line no-unused-vars
    // console.log(developer.address);
    await p12.connect(developer).approve(p12Factory1.address, amountP12);
    const tx = await p12Factory1.connect(developer).declareMintCoin('1101', gameCoinAddress, BigInt(5) * BigInt(10) ** 18n);
    (await tx.wait()).events!.forEach((x: { event: string; args: any }) => {
      if (x.event === 'DeclareMint') {
        mintId2 = x.args!.mintId;
      }
    });
    // console.log('mintId2 is: ', mintId2);

    // // console.log(p12Factory1);
    const coinsMintRecordInfo1 = await p12Factory1.coinMintRecords(gameCoinAddress, mintId);

    const coinsMintRecordInfo2 = await p12Factory1.coinMintRecords(gameCoinAddress, mintId2);
    // console.log('timestamp1 is:', coinsMintRecordInfo1.unlockTimestamp);
    // console.log('timestamp2 is:', coinsMintRecordInfo2.unlockTimestamp);
  });

  it('Should show execute mint successfully!', async function () {
    const timestampBefore = (await ethers.provider.getBlock(await ethers.provider.getBlockNumber())).timestamp;
    await ethers.provider.send('evm_mine', [timestampBefore + 60]);
    await p12Factory1.executeMint(gameCoinAddress, mintId);
    // console.log('p12 Factory gameCoin balance: ', await gameCoin.balanceOf(p12Factory1.address));
  });

  it('Should show duplicate mint fail!', async function () {
    // await new Promise((resolve) => setTimeout(() => resolve(true), 5000));
    await expect(p12Factory1.executeMint(gameCoinAddress, mintId)).to.be.revertedWith('this mint has been executed');
    // console.log('p12 Factory gameCoin balance: ', await gameCoin.balanceOf(p12Factory1.address));
  });

  it('Should show change game developer successfully !', async function () {
    const gameId = '1101';
    await p12Factory1.connect(admin).register(gameId, admin.address);
    // console.log('change game developer successfully !');
  });

  it('Should show withdraw gameCoin successfully', async function () {
    await p12Factory1.connect(admin).withdraw(user.address, gameCoinAddress, 1n * 10n ** 18n);
    // console.log(await gameCoin.balanceOf(user.address));
  });
  // upgrade
  it('P12Factory upgrade', async function () {
    const P12FACTORY2 = await ethers.getContractFactory('P12V0FactoryUpgradeable2');
    p12Factory2 = await upgrades.upgradeProxy(p12Factory1.address, P12FACTORY2);

    await p12Factory2.setName('River');
    const name = await p12Factory2.getName();
    // console.log('name is:', name);
  });

  // check the value after upgrade
  it('P12Factory upgrade', async function () {
    const gameCoinBalance = await gameCoin.balanceOf(p12Factory1.address);
    // console.log('gameCoinBalance', gameCoinBalance);

    const coinsMintRecordInfo2 = await p12Factory1.coinMintRecords(gameCoinAddress, mintId2);

    // console.log('timestamp2 is:', coinsMintRecordInfo2.unlockTimestamp);
  });
});
