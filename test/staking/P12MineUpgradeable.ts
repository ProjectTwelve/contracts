import { expect } from 'chai';
import { ethers, upgrades } from 'hardhat';
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';
import { BigNumber, Contract, utils } from 'ethers';
import * as compiledUniswapFactory from '@uniswap/v2-core/build/UniswapV2Factory.json';
import * as compiledUniswapRouter from '@uniswap/v2-periphery/build/UniswapV2Router02.json';
import * as compiledWETH from 'canonical-weth/build/contracts/WETH9.json';
import * as compiledUniswapPair from '@uniswap/v2-core/build/UniswapV2Pair.json';

import { P12Token, GameCoin, P12MineUpgradeable } from '../../typechain';

describe('lpToken stake ', function () {
  let admin: SignerWithAddress;
  let user: SignerWithAddress;
  let user2: SignerWithAddress;
  let reward: P12Token;
  let p12Mine: P12MineUpgradeable;
  let weth: Contract;
  let uniswapV2Factory: Contract;
  let uniswapV2Router02: Contract;
  let gameCoin: GameCoin;
  let gameCoin2: GameCoin;
  let pair: Contract;
  let pair2: Contract;
  let gaugeController: Contract;
  let votingEscrow: Contract;
  let pairAddress: string;
  let liquidity: BigNumber;
  let liquidity2: BigNumber;
  let id: string;
  let total: BigNumber;
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
    await reward.transfer(user.address, 1000n * 10n ** 18n);
    await reward.transfer(user2.address, 1000n * 10n ** 18n);
  });

  // deploy gameCoin
  it('show gameCoin token deploy successfully', async function () {
    const GameCoin = await ethers.getContractFactory('GameCoin');
    gameCoin = await GameCoin.deploy('gameCoin', 'GC', 100000000n * 10n ** 18n);
    expect(await gameCoin.balanceOf(admin.address)).to.equal(100000000n * 10n ** 18n);
    await gameCoin.transfer(user.address, 1000n * 10n ** 18n);
    await gameCoin.transfer(user2.address, 1000n * 10n ** 18n);
  });

  // deploy gameCoin2
  it('show gameCoin2 token deploy successfully', async function () {
    const GameCoin2 = await ethers.getContractFactory('GameCoin');
    gameCoin2 = await GameCoin2.deploy('gameCoin2', 'GC2', 100000000n * 10n ** 18n);
    expect(await gameCoin2.balanceOf(admin.address)).to.equal(100000000n * 10n ** 18n);
    await gameCoin2.transfer(user.address, 1000n * 10n ** 18n);
    await gameCoin2.transfer(user2.address, 1000n * 10n ** 18n);
  });

  // deploy weth
  it('show weth deploy successfully', async function () {
    const WETH = new ethers.ContractFactory(compiledWETH.abi, compiledWETH.bytecode, admin);
    weth = await WETH.deploy();
  });
  // deploy factory
  it('show uniFactory deploy successfully', async function () {
    const UNISWAPV2FACTORY = new ethers.ContractFactory(
      compiledUniswapFactory.interface,
      compiledUniswapFactory.bytecode,
      admin,
    );
    uniswapV2Factory = await UNISWAPV2FACTORY.connect(admin).deploy(admin.address);
    /// / console.log("init-code", await uniswapV2Factory.INIT_CODE_PAIR_HASH());
  });
  // deploy uniRouter
  it('show uniRouter deploy successfully', async function () {
    const UNISWAPV2ROUTER = new ethers.ContractFactory(compiledUniswapRouter.abi, compiledUniswapRouter.bytecode, admin);
    uniswapV2Router02 = await UNISWAPV2ROUTER.connect(admin).deploy(uniswapV2Factory.address, weth.address);
  });
  // add liquidity
  it('show add liquidity successfully', async function () {
    // add liquidity by admin
    await gameCoin.connect(admin).approve(uniswapV2Router02.address, 100n * 10n ** 18n);
    await reward.connect(admin).approve(uniswapV2Router02.address, 10n * 10n ** 18n);
    await uniswapV2Router02
      .connect(admin)
      .addLiquidity(
        reward.address,
        gameCoin.address,
        10n * 10n ** 18n,
        100n * 10n ** 18n,
        10n * 10n ** 18n,
        100n * 10n ** 18n,
        admin.address,
        2647583680,
      );

    await gameCoin.connect(user).approve(uniswapV2Router02.address, 100n * 10n ** 18n);
    await reward.connect(user).approve(uniswapV2Router02.address, 10n * 10n ** 18n);
    await uniswapV2Router02
      .connect(user)
      .addLiquidity(
        reward.address,
        gameCoin.address,
        10n * 10n ** 18n,
        100n * 10n ** 18n,
        10n * 10n ** 18n,
        100n * 10n ** 18n,
        user.address,
        2647583680,
      );

    pairAddress = await uniswapV2Factory.getPair(reward.address, gameCoin.address);

    let Pair = new ethers.ContractFactory(compiledUniswapPair.interface, compiledUniswapPair.bytecode, admin);

    pair = Pair.attach(pairAddress);
    liquidity = await pair.balanceOf(user.address);
    await gameCoin.connect(user2).approve(uniswapV2Router02.address, 100n * 10n ** 18n);
    await reward.connect(user2).approve(uniswapV2Router02.address, 10n * 10n ** 18n);

    await uniswapV2Router02
      .connect(user2)
      .addLiquidity(
        reward.address,
        gameCoin.address,
        10n * 10n ** 18n,
        100n * 10n ** 18n,
        10n * 10n ** 18n,
        100n * 10n ** 18n,
        user2.address,
        2647583680,
      );

    liquidity2 = await pair.balanceOf(user2.address);

    // add gameCoin2 and p12
    await gameCoin2.connect(user).approve(uniswapV2Router02.address, 100n * 10n ** 18n);
    await reward.connect(user).approve(uniswapV2Router02.address, 10n * 10n ** 18n);

    await uniswapV2Router02
      .connect(user)
      .addLiquidity(
        reward.address,
        gameCoin2.address,
        10n * 10n ** 18n,
        100n * 10n ** 18n,
        10n * 10n ** 18n,
        100n * 10n ** 18n,
        user.address,
        2647583680,
      );
    const pairAddress2 = await uniswapV2Factory.getPair(reward.address, gameCoin2.address);
    Pair = new ethers.ContractFactory(compiledUniswapPair.interface, compiledUniswapPair.bytecode, admin);
    pair2 = Pair.attach(pairAddress2);
  });
  // deploy votingEscrow
  it('should show deploy votingEscrow successfully', async function () {
    const VotingEscrow = await ethers.getContractFactory('VotingEscrow');
    votingEscrow = await VotingEscrow.deploy(reward.address, 'VeP12', 'veP12');
  });

  // deploy GaugeController
  it('show GaugeController deploy successfully', async function () {
    const GaugeController = await ethers.getContractFactory('GaugeControllerUpgradeable');
    gaugeController = await upgrades.deployProxy(GaugeController, [admin.address, votingEscrow.address], { kind: 'uups' });
  });

  // deploy p12Mine
  it('show P12mine deploy successfully', async function () {
    const p12factory = admin.address;
    const delayK = 5;
    const delayB = 5;
    const P12Mine = await ethers.getContractFactory('P12MineUpgradeable');
    const p12MineAddr = await upgrades.deployProxy(
      P12Mine,
      [reward.address, p12factory, gaugeController.address, votingEscrow.address, delayK, delayB],
      {
        kind: 'uups',
      },
    );
    p12Mine = await ethers.getContractAt('P12MineUpgradeable', p12MineAddr.address);
  });

  it('should pausable effective', async () => {
    await p12Mine.pause();
    await expect(
      p12Mine.addLpTokenInfoForGameCreator(ethers.constants.AddressZero, 0n, ethers.constants.AddressZero),
    ).to.be.revertedWith('Pausable: paused');
    await expect(p12Mine.createPool(ethers.constants.AddressZero)).to.be.revertedWith('Pausable: paused');
    await expect(p12Mine.deposit(ethers.constants.AddressZero, 0n)).to.be.revertedWith('Pausable: paused');
    await expect(p12Mine.withdrawDelay(ethers.constants.AddressZero, 0n)).to.be.revertedWith('Pausable: paused');
    await expect(p12Mine.claim(ethers.constants.AddressZero)).to.be.revertedWith('Pausable: paused');
    await expect(p12Mine.claimAll()).to.be.revertedWith('Pausable: paused');
    await expect(
      p12Mine.withdraw(ethers.constants.AddressZero, ethers.constants.AddressZero, utils.randomBytes(32)),
    ).to.be.revertedWith('Pausable: paused');

    await p12Mine.unpause();
  });

  // transfer reward token to the P12RewardVault
  it('show transfer reward successfully', async function () {
    const P12RewardVault = await ethers.getContractFactory('P12RewardVault');
    const p12RewardVault = P12RewardVault.attach(await p12Mine.p12RewardVault());
    await reward.transfer(p12RewardVault.address, 100000000n * 10n ** 18n);

    expect(await reward.balanceOf(p12RewardVault.address)).to.be.equal(100000000n * 10n ** 18n);
  });

  //  try crate a new pool by no permission account
  it('show create a new pool fail', async function () {
    await expect(p12Mine.connect(user).createPool(gameCoin.address)).to.be.revertedWith('P12Mine: not p12factory or owner');
  });

  // add lpToken to stake pool
  it('show add lpToken successfully ', async function () {
    await p12Mine.connect(admin).createPool(pairAddress);
    expect(await p12Mine.lpTokenRegistry(pairAddress)).to.be.equal(1);
    await p12Mine.connect(admin).createPool(pair2.address);
    expect(await p12Mine.lpTokenRegistry(pairAddress)).to.be.equal(1);
  });

  // add type and gauge
  it('show add type and gauge successfully', async function () {
    await gaugeController.addType('liquidity', 1n * 10n ** 18n);
    await gaugeController.addGauge(pairAddress, 0, 0);
    await gaugeController.addGauge(pair2.address, 0, 0);
  });

  // create locker
  it('show create locker successfully', async function () {
    await reward.connect(user).approve(votingEscrow.address, 200n * 10n ** 18n);
    await votingEscrow.connect(user).createLock(200n * 10n ** 18n, 1716693857);
    await reward.connect(admin).approve(votingEscrow.address, 200n * 10n ** 18n);
    await votingEscrow.connect(admin).createLock(200n * 10n ** 18n, 1716693857);
  });
  // vote for gauge
  it('show vote for gauge successfully', async function () {
    await gaugeController.connect(user).voteForGaugeWeights(pairAddress, 1000);
    await gaugeController.connect(user).voteForGaugeWeights(pair2.address, 9000);
    await gaugeController.connect(admin).voteForGaugeWeights(pairAddress, 1000);
    const timestampBefore = (await ethers.provider.getBlock(await ethers.provider.getBlockNumber())).timestamp;
    await ethers.provider.send('evm_mine', [timestampBefore + 86400 * 10]);
    await gaugeController.connect(user).voteForGaugeWeights(pair2.address, 0);
    await gaugeController.connect(user).voteForGaugeWeights(pairAddress, 10000);
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

    await pair.connect(admin).approve(p12Mine.address, pair.balanceOf(admin.address));

    await p12Mine.connect(admin).deposit(pairAddress, pair.balanceOf(admin.address));
  });

  // add lpToken by factory
  it('show add lpToken successfully', async function () {
    await p12Mine.connect(admin).addLpTokenInfoForGameCreator(pairAddress, 0n, user.address);
  });

  // attempts to forge false information to obtain lpToken and rewards should fail
  it('should show that neither balanceOfLpToken nor balanceOfReward has changed ', async function () {
    const balanceOfLpToken = await p12Mine.getUserLpBalance(pairAddress, user.address);
    const balanceOfReward = await reward.balanceOf(user.address);
    await p12Mine
      .connect(user)
      .withdraw(user.address, pairAddress, '0x686a653b3b000000000000000000000000000000000000000000000000000000');
    expect(await reward.balanceOf(user.address)).to.be.above(balanceOfReward);
    expect(await p12Mine.getUserLpBalance(pairAddress, user.address)).to.be.equal(balanceOfLpToken);
  });

  // use a fake account to withdraw lpToken
  it('show withdraw lpToken fail', async function () {
    const balanceOfLpToken = await p12Mine.getUserLpBalance(pairAddress, admin.address);
    const balanceOfReward = await reward.balanceOf(admin.address);
    expect(
      p12Mine
        .connect(user)
        .withdraw(user.address, pairAddress, '0x686a653b3b000000000000000000000000000000000000000000000000000000'),
    ).to.be.revertedWith('P12Mine: can not withdraw');
    expect(await reward.balanceOf(admin.address)).to.be.equal(balanceOfReward);
    expect(await p12Mine.getUserLpBalance(pairAddress, admin.address)).to.be.equal(balanceOfLpToken);
  });

  // delay unStaking mining
  it('show  withdraw delay', async function () {
    const tx = await p12Mine.connect(user).withdrawDelay(pairAddress, liquidity);
    expect(await p12Mine.getUserLpBalance(pairAddress, user.address)).to.be.equal(liquidity);

    (await tx.wait()).events!.forEach((x) => {
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
  // try withdraw
  it('show withdraw fail', async function () {
    const timestampBefore = (await ethers.provider.getBlock(await ethers.provider.getBlockNumber())).timestamp;
    await ethers.provider.send('evm_mine', [timestampBefore + 1]);
    await expect(p12Mine.connect(user).withdraw(user.address, pairAddress, id)).to.be.revertedWith('P12Mine: can not withdraw');
  });

  it('show withdraw successfully', async function () {
    // time goes by
    const timestampBefore = (await ethers.provider.getBlock(await ethers.provider.getBlockNumber())).timestamp;
    await ethers.provider.send('evm_mine', [timestampBefore + 60]);
    await p12Mine.withdraw(user.address, pairAddress, id);
    expect(await p12Mine.getUserLpBalance(pairAddress, user.address)).to.be.equal(0);
    expect(await reward.balanceOf(user.address)).to.be.above(0);
  });

  // reset delayK and delayB
  it('show set delayB and delayK success', async function () {
    await p12Mine.setDelayK(120);
    await p12Mine.setDelayB(120);
    expect(await p12Mine.delayK()).to.be.equal(120);
    expect(await p12Mine.delayB()).to.be.equal(120);
  });

  // Staking Mining after reset delayK  delayB and reward
  it('show stake successfully', async function () {
    // use user account
    const liquidity = await pair.balanceOf(user.address);
    await pair.connect(user).approve(p12Mine.address, liquidity);
    await p12Mine.connect(user).deposit(pairAddress, liquidity);
    expect(await p12Mine.getUserLpBalance(pairAddress, user.address)).to.be.equal(liquidity);
  });

  // get pending reward
  it('show claim success', async function () {
    const balanceOfReward = await reward.balanceOf(user.address);
    const timestampBefore = (await ethers.provider.getBlock(await ethers.provider.getBlockNumber())).timestamp;
    await ethers.provider.send('evm_mine', [timestampBefore + 1200]);
    await p12Mine.connect(user).claim(pairAddress);
    expect(await reward.balanceOf(user.address)).to.be.above(balanceOfReward);
  });

  // staking more lpToken
  it('show stake more lpToken successfully', async function () {
    await gameCoin.connect(user).approve(uniswapV2Router02.address, 100n * 10n ** 18n);
    await reward.connect(user).approve(uniswapV2Router02.address, 10n * 10n ** 18n);
    await uniswapV2Router02
      .connect(user)
      .addLiquidity(
        reward.address,
        gameCoin.address,
        10n * 10n ** 18n,
        100n * 10n ** 18n,
        10n * 10n ** 18n,
        100n * 10n ** 18n,
        user.address,
        2647583680,
      );
    // use user account
    const liquidity3 = await pair.balanceOf(user.address);
    await pair.connect(user).approve(p12Mine.address, liquidity3);
    await p12Mine.connect(user).deposit(pairAddress, liquidity3);
    total = liquidity.add(liquidity3);
    expect(await p12Mine.getUserLpBalance(pairAddress, user.address)).to.be.equal(total);
  });

  // try withdraw
  it('show withdraw fail', async function () {
    await expect(p12Mine.connect(user).withdraw(user.address, pairAddress, id)).to.be.revertedWith('P12Mine: can not withdraw');
  });

  // delay unStaking mining
  it('show  withdraw delay', async function () {
    const tx = await p12Mine.connect(user).withdrawDelay(pairAddress, total);
    expect(await p12Mine.getUserLpBalance(pairAddress, user.address)).to.be.equal(total);

    (await tx.wait()).events!.forEach((x) => {
      if (x.event === 'WithdrawDelay') {
        id = x.args!.newWithdrawId;
      }
    });
    try {
      await p12Mine.withdraw(user.address, pairAddress, id);
    } catch (error) {
      expect(await p12Mine.getUserLpBalance(pairAddress, user.address)).to.be.equal(total);
    }
  });

  // claim  pending reward with fake account
  it('show claim nothing', async function () {
    const balanceOfReward = await reward.balanceOf(admin.address);
    await p12Mine.connect(admin).claim(pair.address);
    expect(await reward.balanceOf(admin.address)).to.be.equal(balanceOfReward);
  });

  // get pending reward by claimAll
  it('show claimAll successfully', async function () {
    const timestampBefore = (await ethers.provider.getBlock(await ethers.provider.getBlockNumber())).timestamp;
    await ethers.provider.send('evm_mine', [timestampBefore + 86400 * 7]);
    const balanceOfReward = await reward.balanceOf(user.address);
    await p12Mine.connect(user).claimAll();
    expect(await reward.balanceOf(user.address)).to.be.above(balanceOfReward);
  });

  it('show withdraw successfully', async function () {
    // time goes by
    const balanceOfReward = await reward.balanceOf(user.address);
    const timestampBefore = (await ethers.provider.getBlock(await ethers.provider.getBlockNumber())).timestamp;
    await ethers.provider.send('evm_mine', [timestampBefore + 600]);
    await p12Mine.withdraw(user.address, pairAddress, id);
    expect(await p12Mine.getUserLpBalance(pairAddress, user.address)).to.be.equal(0);
    expect(await reward.balanceOf(user.address)).to.be.above(balanceOfReward);
  });

  // staking an unregistered pool
  it('show staking fail', async function () {
    const balance = await reward.balanceOf(user.address);
    await reward.connect(user).approve(p12Mine.address, balance);
    await expect(p12Mine.connect(user).deposit(reward.address, balance)).to.be.revertedWith('P12Mine: LP Token Not Exist');
  });

  // try create an existing pool
  it('show create an existing pool fail', async function () {
    await expect(p12Mine.connect(admin).createPool(pairAddress)).to.be.revertedWith('P12Mine: LP Token Already Exist');
    expect(await p12Mine.lpTokenRegistry(pairAddress)).to.be.equal(1);
  });

  // get pool info
  it('show get pool info success', async function () {
    const len = await p12Mine.poolLength();
    expect(len).to.equal(2);
    const pid = await p12Mine.getPid(pairAddress);
    const tmp = await p12Mine.lpTokenRegistry(pairAddress);
    expect(pid).to.be.equal(tmp.sub(1));
  });

  // user checkpoint
  it('show checkpoint  success', async function () {
    await p12Mine.userCheckpoint(pairAddress);
  });
});
