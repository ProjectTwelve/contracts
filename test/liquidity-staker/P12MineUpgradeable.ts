import { expect } from 'chai';
import { ethers, upgrades } from 'hardhat';
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';
import { time } from 'console';
import { Contract } from 'ethers';
import { resolve } from 'dns';

describe('lpToken stake ', function () {
  let admin: SignerWithAddress;
  let user: SignerWithAddress;
  const startBlock = 1;
  let reward: any;
  let p12Mine: any;
  let id: any;
  let weth: any;
  let uniswapV2Factory: any;
  let router: any;
  let bitCoin: any;
  let pair: any;
  let pairAddress: any;
  let user2: any;
  let liquidity: any;
  let liquidity2: any;
  let rewardAmount: any;
  // accounts info
  it('should use the correct account ', async function () {
    [admin, user, user2] = await ethers.getSigners();
    expect(await admin.address).to.be.equal('0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266');
    expect(await user.address).to.be.equal('0x70997970C51812dc3A010C7d01b50e0d17dc79C8');
  });

  // deploy reward token contract
  it('show rewards token deploy successfully', async function () {
    const Reward = await ethers.getContractFactory('P12Token');
    reward = await Reward.deploy('rewards token', 'RT', 1000000000n * 10n ** 18n);
    expect(await reward.balanceOf(admin.address)).to.equal(1000000000n * 10n ** 18n);
    await reward.transfer(user.address, 10n * 10n ** 18n);
    await reward.transfer(user2.address, 10n * 10n ** 18n);
  });

  // deploy bitCoin
  it('show bitCoin token deploy successfully', async function () {
    const BitCoin = await ethers.getContractFactory('BitCoin');
    bitCoin = await BitCoin.deploy('bitcoin', 'BC', 100000000n * 10n ** 18n);
    expect(await bitCoin.balanceOf(admin.address)).to.equal(100000000n * 10n ** 18n);
    await bitCoin.transfer(user.address, 100n * 10n ** 18n);
    await bitCoin.transfer(user2.address, 100n * 10n ** 18n);
  });

  // deploy weth
  it('show weth deploy successfully', async function () {
    const WETH = await ethers.getContractFactory('WETH9');
    weth = await WETH.deploy();
  });
  // deploy factory
  it('show uniFactory deploy successfully', async function () {
    const UniswapV2Factory = await ethers.getContractFactory('UniswapV2Factory');
    uniswapV2Factory = await UniswapV2Factory.deploy(admin.address);
    //// console.log("init-code", await uniswapV2Factory.INIT_CODE_PAIR_HASH());
  });
  // deploy uniRouter
  it('show uniRouter deploy successfully', async function () {
    const Router = await ethers.getContractFactory('UniswapV2Router02');
    router = await Router.deploy(uniswapV2Factory.address, weth.address);
  });
  // add liquidity
  it('show add liquidity successfully', async function () {
    await bitCoin.connect(user).approve(router.address, 100n * 10n ** 18n);
    await reward.connect(user).approve(router.address, 10n * 10n ** 18n);
    await router
      .connect(user)
      .addLiquidity(
        reward.address,
        bitCoin.address,
        10n * 10n ** 18n,
        100n * 10n ** 18n,
        10n * 10n ** 18n,
        100n * 10n ** 18n,
        user.address,
        2647583680,
      );

    pairAddress = await uniswapV2Factory.getPair(reward.address, bitCoin.address);

    const Pair = await ethers.getContractFactory('UniswapV2Pair');
    pair = await Pair.attach(pairAddress);
    liquidity = await pair.balanceOf(user.address);

    await bitCoin.connect(user2).approve(router.address, 100n * 10n ** 18n);
    await reward.connect(user2).approve(router.address, 10n * 10n ** 18n);

    await router
      .connect(user2)
      .addLiquidity(
        reward.address,
        bitCoin.address,
        10n * 10n ** 18n,
        100n * 10n ** 18n,
        10n * 10n ** 18n,
        100n * 10n ** 18n,
        user2.address,
        2647583680,
      );

    liquidity2 = await pair.balanceOf(user2.address);
  });
  // deploy p12Mine
  it('show P12mine deploy successfully', async function () {
    const p12factory = admin.address;
    const delayK = 5;
    const delayB = 5;
    const P12Mine = await ethers.getContractFactory('P12MineUpgradeable');
    p12Mine = await upgrades.deployProxy(P12Mine, [reward.address, p12factory, startBlock, delayK, delayB], { kind: 'uups' });
  });

  // transfer reward token to the P12RewardVault
  it('show transfer reward successfully', async function () {
    const P12RewardVault = await ethers.getContractFactory('P12RewardVault');
    const p12RewardVault = await P12RewardVault.attach(await p12Mine.p12RewardVault());
    await reward.transfer(p12RewardVault.address, 100000000n * 10n ** 18n);

    expect(await reward.balanceOf(p12RewardVault.address)).to.be.equal(100000000n * 10n ** 18n);
  });

  // set reward for each block
  it('show set rewardPerBlock successfully', async function () {
    await p12Mine.setReward(10n * 10n ** 18n, false);
    expect(await p12Mine.p12PerBlock()).to.be.equal(10n * 10n ** 18n);
  });

  // add lpToken to stake pool
  it('show add lpToken successfully ', async function () {
    await p12Mine.connect(admin).createPool(pairAddress, false);
    expect(await p12Mine.lpTokenRegistry(pairAddress)).to.be.equal(1);
  });

  // Staking Mining
  it('show stake successfully', async function () {
    // use user account
    await pair.connect(user).approve(p12Mine.address, liquidity);

    await p12Mine.connect(user).deposit(pairAddress, liquidity);
    expect(await p12Mine.getUserLpBalance(pairAddress, user.address)).to.be.equal(liquidity);

    await pair.connect(user2).approve(p12Mine.address, liquidity2);

    await p12Mine.connect(user2).deposit(pairAddress, liquidity2);
    expect(await p12Mine.getUserLpBalance(pairAddress, user2.address)).to.be.equal(liquidity2);
  });

  // delay unStaking mining
  it('show  withdraw delay', async function () {
    const tx = await p12Mine.connect(user).withdrawDelay(pairAddress, liquidity);
    expect(await p12Mine.getUserLpBalance(pairAddress, user.address)).to.be.equal(liquidity);

    (await tx.wait()).events!.forEach((x: { event: string; args: any }) => {
      if (x.event === 'WithdrawDelay') {
        id = x.args!.newWithdrawId;
      }
    });
    try {
      await p12Mine.withdraw(user.address, pairAddress, id);
    } catch (error) {
      expect(await p12Mine.getUserLpBalance(pairAddress, user.address)).to.be.equal(liquidity);
    }
  });
  it('show withdraw successfully', async function () {
    // time goes by
    const timestampBefore = (await ethers.provider.getBlock(await ethers.provider.getBlockNumber())).timestamp;
    await ethers.provider.send('evm_mine', [timestampBefore + 60]);
    await p12Mine.withdraw(user.address, pairAddress, id);
    expect(await p12Mine.getUserLpBalance(pairAddress, user.address)).to.be.equal(0);
    expect(await reward.balanceOf(user.address)).to.be.above(0);
  });
});
