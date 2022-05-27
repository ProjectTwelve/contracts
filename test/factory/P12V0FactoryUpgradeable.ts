import { ethers, upgrades } from 'hardhat';
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';
import { expect } from 'chai';
import { P12Token, P12V0FactoryUpgradeable } from '../../typechain';
import * as compiledUniswapFactory from '@uniswap/v2-core/build/UniswapV2Factory.json';
import * as compiledUniswapRouter from '@uniswap/v2-periphery/build/UniswapV2Router02.json';
import * as compiledWETH from 'canonical-weth/build/contracts/WETH9.json';
import { Contract } from 'ethers';

describe('P12Factory', function () {
  let admin: SignerWithAddress;
  let developer: SignerWithAddress;
  let user: SignerWithAddress;
  let uniswapV2Router02: Contract;
  let p12: P12Token;
  let uniswapV2Factory: Contract;
  let p12Factory: P12V0FactoryUpgradeable;
  let gameCoinAddress: string;
  let mintId: string;
  // eslint-disable-next-line no-unused-vars
  let mintId2: string;
  let p12MineUpgradeable: Contract;
  let votingEscrow: Contract;
  let gaugeController: Contract;

  this.beforeAll(async function () {
    // hardhat test accounts
    const accounts = await ethers.getSigners();
    admin = accounts[0];
    developer = accounts[1];
    user = accounts[2];

    // deploy uniswap
    const UNISWAPV2ROUTER = new ethers.ContractFactory(compiledUniswapRouter.abi, compiledUniswapRouter.bytecode, admin);
    const UNISWAPV2FACTORY = new ethers.ContractFactory(
      compiledUniswapFactory.interface,
      compiledUniswapFactory.bytecode,
      admin,
    );
    const WETH = new ethers.ContractFactory(compiledWETH.abi, compiledWETH.bytecode, admin);
    uniswapV2Factory = await UNISWAPV2FACTORY.connect(admin).deploy(admin.address);

    const weth = await WETH.deploy();

    uniswapV2Router02 = await UNISWAPV2ROUTER.connect(admin).deploy(uniswapV2Factory.address, weth.address);
  });
  it('Should show p12 token deploy successfully!', async function () {
    // deploy p12token
    const ERC20 = await ethers.getContractFactory('P12Token');
    p12 = await ERC20.connect(admin).deploy('ProjectTwelve', 'P12', 1000n * 10n ** 18n);
    expect(await p12.balanceOf(admin.address)).to.be.equal(1000n * 10n ** 18n);
  });

  it('Should show P12Factory contract deploy successful!', async function () {
    const P12FACTORY = await ethers.getContractFactory('P12V0FactoryUpgradeable');
    const p12FactoryAddr = await upgrades.deployProxy(
      P12FACTORY,
      [p12.address, uniswapV2Factory.address, uniswapV2Router02.address, 3600, ethers.utils.randomBytes(32)],
      {
        kind: 'uups',
      },
    );
    p12Factory = await ethers.getContractAt('P12V0FactoryUpgradeable', p12FactoryAddr.address);
    expect(await p12Factory.owner()).to.be.equal(admin.address);
  });
  // deploy votingEscrow
  it('should show deploy votingEscrow successfully', async function () {
    const VotingEscrow = await ethers.getContractFactory('VotingEscrow');
    votingEscrow = await VotingEscrow.deploy(p12.address, 'VeP12', 'veP12');
  });

  // deploy GaugeController
  it('show GaugeController deploy successfully', async function () {
    const GaugeController = await ethers.getContractFactory('GaugeControllerUpgradeable');
    gaugeController = await upgrades.deployProxy(GaugeController, [admin.address, votingEscrow.address], { kind: 'uups' });
  });

  // deploy P12Mine
  it('show deploy p12mine successfully', async function () {
    const p12factory = p12Factory.address;
    const delayK = 5;
    const delayB = 5;
    const P12Mine = await ethers.getContractFactory('P12MineUpgradeable');
    p12MineUpgradeable = await upgrades.deployProxy(
      P12Mine,
      [p12.address, p12factory, gaugeController.address, votingEscrow.address, delayK, delayB],
      {
        kind: 'uups',
      },
    );
  });
  it('set some info to p12Factory', async function () {
    await p12Factory.setP12Mine(p12MineUpgradeable.address);
    expect(await p12Factory.p12mine()).to.be.equal(p12MineUpgradeable.address);
  });

  it('Should pausable effective', async () => {
    await p12Factory.pause();

    expect(p12Factory.create('', '', '', '', 0n, 0n)).to.be.revertedWith('Pausable: paused');
    expect(p12Factory.declareMintCoin('', '', 0n)).to.be.revertedWith('Pausable: paused');
    expect(p12Factory.executeMint('', '')).to.be.revertedWith('Pausable: paused');

    await p12Factory.unpause();
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

    (await createInfo.wait()).events!.forEach((x) => {
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
    (await tx.wait()).events!.forEach((x) => {
      if (x.event === 'DeclareMint') {
        mintId = x.args!.mintId;
      }
    });
  });

  it('Should show declare mint successfully!', async function () {
    const amountP12 = BigInt(6) * BigInt(10) ** 17n;

    await p12.connect(developer).approve(p12Factory.address, amountP12);
    const tx = await p12Factory.connect(developer).declareMintCoin('1101', gameCoinAddress, BigInt(5) * BigInt(10) ** 18n);
    (await tx.wait()).events!.forEach((x) => {
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
  it('Should contract upgrade successfully', async function () {
    const p12FactoryAlterF = await ethers.getContractFactory('P12V0FactoryUpgradeableAlter');

    await upgrades.upgradeProxy(p12Factory.address, p12FactoryAlterF);

    const p12FactoryAlter = await ethers.getContractAt('P12V0FactoryUpgradeableAlter', p12Factory.address);

    await p12FactoryAlter.callWhiteBlack();
  });
});
