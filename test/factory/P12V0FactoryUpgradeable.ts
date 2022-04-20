import { ethers, upgrades } from 'hardhat';
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';
import { expect } from 'chai';
import {
  P12Token,
  UniswapV2Factory,
  UniswapV2Router02,
  // eslint-disable-next-line node/no-missing-import
} from '../../typechain';
import { Contract } from 'ethers';

describe('P12Factory', function () {
  let admin: SignerWithAddress;
  let developer: SignerWithAddress;
  let user: SignerWithAddress;
  let router: UniswapV2Router02;
  let p12: P12Token;
  let UniswapV2Factory: UniswapV2Factory;
  let p12Factory: Contract;
  let gameCoinAddress: string;
  let mintId: string;
  let mintId2: string;
  let p12MineUpgradeable: any;

  this.beforeAll(async function () {
    // hardhat test accounts
    const accounts = await ethers.getSigners();
    admin = accounts[0];
    developer = accounts[1];
    user = accounts[2];

    // deploy uniswap
    const UNISWAPV2ROUTER = await ethers.getContractFactory('UniswapV2Router02');
    const UNISWAPV2FACTORY = await ethers.getContractFactory('UniswapV2Factory');
    const WETH = await ethers.getContractFactory('WETH9');
    UniswapV2Factory = await UNISWAPV2FACTORY.connect(admin).deploy(admin.address);

    const weth = await WETH.deploy();

    router = await UNISWAPV2ROUTER.connect(admin).deploy(UniswapV2Factory.address, weth.address);
  });
  it('Should show p12 token deploy successfully!', async function () {
    // deploy p12token
    const ERC20 = await ethers.getContractFactory('P12Token');
    p12 = await ERC20.connect(admin).deploy('ProjectTwelve', 'P12', 1000n * 10n ** 18n);
    expect(await p12.balanceOf(admin.address)).to.be.equal(1000n * 10n ** 18n);
  });

  it('Should show P12Factory contract deploy successful!', async function () {
    const P12FACTORY = await ethers.getContractFactory('P12V0FactoryUpgradeable');
    p12Factory = await upgrades.deployProxy(P12FACTORY, [p12.address, UniswapV2Factory.address, router.address, 3600], {
      kind: 'uups',
    });
    expect(await p12Factory.owner()).to.be.equal(admin.address);
  });

  // deploy P12Mine
  it('show deploy p12mine successfully', async function () {
    const timeStart = 1;
    const delayK = 60;
    const delayB = 60;
    const P12MineUpgradeable = await ethers.getContractFactory('P12MineUpgradeable');
    p12MineUpgradeable = await upgrades.deployProxy(
      P12MineUpgradeable,
      [p12.address, p12Factory.address, timeStart, delayK, delayB],
      { kind: 'uups' },
    );
  });
  it('set some info to p12Factory', async function () {
    await p12Factory.setInfo(p12MineUpgradeable.address);
    expect(await p12Factory.p12mine()).to.be.equal(p12MineUpgradeable.address);
  });
  it('Should show developer register successfully', async function () {
    const gameId = '1101';
    await p12Factory.connect(admin).register(gameId, developer.address);
    expect(await p12Factory.allGames('1101')).to.be.equal(developer.address);
  });

  it('Give developer p12', async function () {
    await p12.connect(admin).transfer(developer.address, BigInt(3) * 10n ** 18n);
    expect(await p12.balanceOf(developer.address)).to.be.equal(3n * 10n ** 18n);
  });
  it('Should show gameCoin create successfully!', async function () {
    const name = 'GameCoin';
    const symbol = 'GC';
    const gameId = '1101';
    const gameCoinIconUrl =
      'https://images.weserv.nl/?url=https://i0.hdslb.com/bfs/article/87c5b43b19d4065f837f54637d3932e680af9c9b.jpg';
    const amountGameCoin = BigInt(10) * BigInt(10) ** 18n;
    const amountP12 = BigInt(1) * BigInt(10) ** 18n;

    await p12.connect(developer).approve(p12Factory.address, amountP12);
    const createInfo = await p12Factory
      .connect(developer)
      .create(name, symbol, gameId, gameCoinIconUrl, amountGameCoin, amountP12);

    (await createInfo.wait()).events!.forEach((x: { event: string; args: any }) => {
      if (x.event === 'CreateGameCoin') {
        gameCoinAddress = x.args!.gameCoinAddress;
      }
    });
  });

  it('Should show set delay variable successfully! ', async function () {
    await p12Factory.connect(admin).setDelayK(1);
    await p12Factory.connect(admin).setDelayB(1);
    expect(await p12Factory.delayK()).to.be.equal(1);
    expect(await p12Factory.delayB()).to.be.equal(1);
  });

  // it("Check gameCoin mint fee", async function () {
  //   const price = await p12Factory.getMintFee(
  //     gameCoinAddress,
  //     BigInt(30) * BigInt(10) ** 18n
  //   );
  //   console.log("check gameCoin mint fee", price);
  // });

  it('Check gameCoin mint delay time', async function () {
    await p12Factory.getMintDelay(gameCoinAddress, BigInt(5) * BigInt(10) ** 18n);
  });
  it('Should show declare mint successfully!', async function () {
    const amountP12 = BigInt(6) * BigInt(10) ** 17n;
    await p12.connect(developer).approve(p12Factory.address, amountP12);
    const tx = await p12Factory.connect(developer).declareMintCoin('1101', gameCoinAddress, BigInt(5) * BigInt(10) ** 18n);
    (await tx.wait()).events!.forEach((x: { event: string; args: any }) => {
      if (x.event === 'DeclareMint') {
        mintId = x.args!.mintId;
      }
    });
  });

  it('Should show declare mint successfully!', async function () {
    const amountP12 = BigInt(6) * BigInt(10) ** 17n;

    await p12.connect(developer).approve(p12Factory.address, amountP12);
    const tx = await p12Factory.connect(developer).declareMintCoin('1101', gameCoinAddress, BigInt(5) * BigInt(10) ** 18n);
    (await tx.wait()).events!.forEach((x: { event: string; args: any }) => {
      if (x.event === 'DeclareMint') {
        mintId2 = x.args!.mintId;
      }
    });
  });

  it('Should show execute mint successfully!', async function () {
    const blockNumBefore = await ethers.provider.getBlockNumber();
    const blockBefore = await ethers.provider.getBlock(blockNumBefore);
    const timestampBefore = blockBefore.timestamp;
    await ethers.provider.send('evm_mine', [timestampBefore + 5000]);
    await p12Factory.executeMint(gameCoinAddress, mintId);
  });

  it('Should show duplicate mint fail!', async function () {
    const blockNumBefore = await ethers.provider.getBlockNumber();
    const blockBefore = await ethers.provider.getBlock(blockNumBefore);
    const timestampBefore = blockBefore.timestamp;
    await ethers.provider.send('evm_mine', [timestampBefore + 5000]);
    await expect(p12Factory.executeMint(gameCoinAddress, mintId)).to.be.revertedWith('this mint has been executed');
  });

  it('Should show change game developer successfully !', async function () {
    const gameId = '1101';
    await p12Factory.connect(admin).register(gameId, admin.address);
    expect(await p12Factory.allGames('1101')).to.be.equal(admin.address);
  });

  it('Should show withdraw gameCoin successfully', async function () {
    await p12Factory.connect(admin).withdraw(user.address, gameCoinAddress, 1n * 10n ** 18n);
    const P12V0ERC20 = await ethers.getContractFactory('P12V0ERC20');
    const p12V0ERC20 = await P12V0ERC20.attach(gameCoinAddress);

    expect(await p12V0ERC20.balanceOf(user.address)).to.be.equal(1n * 10n ** 18n);
  });
});
