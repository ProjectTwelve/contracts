import { expect } from 'chai';
import { ethers } from 'hardhat';
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';
import { Contract, Wallet } from 'ethers/lib/ethers';

describe('sceneSimulation', function () {
  let user0: SignerWithAddress;
  let user1: SignerWithAddress;
  let user2: SignerWithAddress;
  let nextWeekTime: number;
  // eslint-disable-next-line no-unused-vars
  let nextOPTime: number;
  let votingEscrow: Contract;
  let coinFactoryUpgradeable: Contract;
  let gaugeController: Contract;
  let p12Token: Contract;
  let adminWallet: Wallet;
  let devWallet: Wallet;
  let pool0: String;
  let pool1: String;
  let pool2: String;
  this.beforeAll(async function () {
    // hardhat test accounts
    const accounts = await ethers.getSigners();
    user0 = accounts[0];
    user1 = accounts[1];
    user2 = accounts[2];

    const votingEscrowAddr = '0xA7f7dee4E7a86b96dB09DAcBBbB13Da911462B20';
    const coinFactoryUpgradeableAddr = '0x2695eF03c7ea6A1F55463ee4b47E4E3DBCBcd6d1';
    const gaugeControllerAddr = '0x92Ef99Db92b04C34D55b1C1537166dbeF130068e';
    const p12TokenAddr = '0xeAc1F044C4b9B7069eF9F3eC05AC60Df76Fe6Cd0';

    const P12Token = await ethers.getContractFactory('P12Token');
    p12Token = await P12Token.attach(p12TokenAddr);

    const VotingEscrow = await ethers.getContractFactory('VotingEscrow');
    votingEscrow = await VotingEscrow.attach(votingEscrowAddr);

    const CoinFactoryUpgradeable = await ethers.getContractFactory('P12CoinFactoryUpgradeable');
    coinFactoryUpgradeable = await CoinFactoryUpgradeable.attach(coinFactoryUpgradeableAddr);

    const GaugeController = await ethers.getContractFactory('GaugeControllerUpgradeable');
    gaugeController = await GaugeController.attach(gaugeControllerAddr);

    const adminPrivatekey = 'cf53da8e2fab30a115e2f8eadc4b774b9ef025b3b9cde5342e9ad90b47d7dbc3';
    adminWallet = new ethers.Wallet(adminPrivatekey, ethers.provider);

    const devPrivatekey = 'ea207f84c92e99e8b2c71a7e6b95598fc513b6af9eedbd22d470577a194fbda4';
    devWallet = new ethers.Wallet(devPrivatekey, ethers.provider);

    // mint p12token to user
    await p12Token.connect(adminWallet).mint(user2.address, 100n * 10n ** 18n);

    // create staking pool by adminWallet
    await coinFactoryUpgradeable.connect(devWallet).register('1100', adminWallet.address);
    let name = 'GameCoin0';
    let symbol = 'GC0';
    let gameId = '1100';
    const gameCoinIconUrl =
      'https://images.weserv.nl/?url=https://i0.hdslb.com/bfs/article/87c5b43b19d4065f837f54637d3932e680af9c9b.jpg';
    const amountGameCoin = BigInt(10) * BigInt(10) ** 18n;
    const amountP12 = BigInt(1) * BigInt(10) ** 18n;

    await p12Token.connect(adminWallet).approve(coinFactoryUpgradeable.address, amountP12);
    await coinFactoryUpgradeable.connect(adminWallet).create(name, symbol, gameId, gameCoinIconUrl, amountGameCoin, amountP12);

    await coinFactoryUpgradeable.connect(devWallet).register('1101', adminWallet.address);
    name = 'GameCoin1';
    symbol = 'GC1';
    gameId = '1101';
    await p12Token.connect(adminWallet).approve(coinFactoryUpgradeable.address, amountP12);
    await coinFactoryUpgradeable.connect(adminWallet).create(name, symbol, gameId, gameCoinIconUrl, amountGameCoin, amountP12);

    await coinFactoryUpgradeable.connect(devWallet).register('1102', adminWallet.address);
    name = 'GameCoin2';
    symbol = 'GC2';
    gameId = '1102';

    await p12Token.connect(adminWallet).approve(coinFactoryUpgradeable.address, amountP12);
    await coinFactoryUpgradeable.connect(adminWallet).create(name, symbol, gameId, gameCoinIconUrl, amountGameCoin, amountP12);

    pool0 = await gaugeController.gauges(0);
    pool1 = await gaugeController.gauges(1);
    pool2 = await gaugeController.gauges(2);
  });
  it('show init info', async function () {
    const timestamp = (await ethers.provider.getBlock(await ethers.provider.getBlockNumber())).timestamp;
    console.log('pool0 weight is:', ethers.utils.formatEther(await gaugeController.gaugeRelativeWeight(pool0, timestamp)));
    console.log('pool1 weight is:', ethers.utils.formatEther(await gaugeController.gaugeRelativeWeight(pool1, timestamp)));
    console.log('pool2 weight is:', ethers.utils.formatEther(await gaugeController.gaugeRelativeWeight(pool2, timestamp)));
    console.log('-------------------------');
    console.log('user0 balanceOf veP12', await votingEscrow.balanceOf(user0.address));
    console.log('user0 lockInfo', await votingEscrow.locked(user0.address));
    console.log('user1 balanceOf veP12', await votingEscrow.balanceOf(user1.address));
    console.log('user1 lockInfo', await votingEscrow.locked(user1.address));
    console.log('user2 balanceOf veP12', await votingEscrow.balanceOf(user2.address));
    console.log('user2 lockInfo', await votingEscrow.locked(user2.address));
    console.log('-------------------------');
    console.log('user0 vote pool0 info', await gaugeController.voteUserSlopes(user0.address, pool0));
    console.log('user0 vote pool1 info', await gaugeController.voteUserSlopes(user0.address, pool1));
    console.log('user0 vote pool2 info', await gaugeController.voteUserSlopes(user0.address, pool2));
    console.log('user1 vote pool0 info', await gaugeController.voteUserSlopes(user1.address, pool0));
    console.log('user1 vote pool1 info', await gaugeController.voteUserSlopes(user1.address, pool1));
    console.log('user1 vote pool2 info', await gaugeController.voteUserSlopes(user1.address, pool2));
    console.log('user2 vote pool0 info', await gaugeController.voteUserSlopes(user2.address, pool0));
    console.log('user2 vote pool1 info', await gaugeController.voteUserSlopes(user2.address, pool1));
    console.log('user2 vote pool2 info', await gaugeController.voteUserSlopes(user2.address, pool2));
    console.log('-------------------------');
  });
  it('should lock p12 vote successfully ', async function () {
    const timestamp = (await ethers.provider.getBlock(await ethers.provider.getBlockNumber())).timestamp;
    // user0 lock
    await p12Token.connect(user0).approve(votingEscrow.address, 20n * 10n ** 18n);
    votingEscrow.connect(user0).createLock(20n * 10n ** 18n, timestamp + 365 * 86400);
    console.log('user0 balanceOf veP12', await votingEscrow.balanceOf(user0.address));
    console.log('user0 lockInfo', await votingEscrow.locked(user0.address));
    console.log('-------------------------');
    // user1 lock
    await p12Token.connect(user1).approve(votingEscrow.address, 20n * 10n ** 18n);
    votingEscrow.connect(user1).createLock(20n * 10n ** 18n, timestamp + 604800 * 2 + 5000);
    console.log('user1 balanceOf veP12', await votingEscrow.balanceOf(user1.address));
    console.log('user1 lockInfo', await votingEscrow.locked(user1.address));
    console.log('-------------------------');
    // user2 lock
    await p12Token.connect(user2).approve(votingEscrow.address, 20n * 10n ** 18n);
    votingEscrow.connect(user2).createLock(20n * 10n ** 18n, timestamp + 365 * 86400);
    console.log('user2 balanceOf veP12', await votingEscrow.balanceOf(user2.address));
    console.log('user2 lockInfo', await votingEscrow.locked(user2.address));
    console.log('-------------------------');

    // user0 vote
    await gaugeController.connect(user0).voteForGaugeWeights(pool0, 3000);
    await gaugeController.connect(user0).voteForGaugeWeights(pool1, 4000);
    await gaugeController.connect(user0).voteForGaugeWeights(pool2, 1000);
    console.log('user0 vote pool0 info', await gaugeController.voteUserSlopes(user0.address, pool0));
    console.log('user0 vote pool1 info', await gaugeController.voteUserSlopes(user0.address, pool1));
    console.log('user0 vote pool2 info', await gaugeController.voteUserSlopes(user0.address, pool2));
    console.log('-------------------------');
    // user1 vote
    await gaugeController.connect(user1).voteForGaugeWeights(pool0, 3000);
    await gaugeController.connect(user1).voteForGaugeWeights(pool1, 4000);
    console.log('user1 vote pool0 info', await gaugeController.voteUserSlopes(user1.address, pool0));
    console.log('user1 vote pool1 info', await gaugeController.voteUserSlopes(user1.address, pool1));
    console.log('-------------------------');
    // user2 vote
    await gaugeController.connect(user2).voteForGaugeWeights(pool0, 4000);
    await gaugeController.connect(user2).voteForGaugeWeights(pool1, 6000);
    console.log('user2 vote pool0 info', await gaugeController.voteUserSlopes(user2.address, pool0));
    console.log('user2 vote pool1 info', await gaugeController.voteUserSlopes(user2.address, pool1));
    console.log('-------------------------');
    const week = 86400 * 7;
    nextWeekTime = Math.floor((timestamp + week) / week) * 86400 * 7;
    nextOPTime = timestamp + 86400 * 10;
    console.log('nextWeekTime', nextWeekTime);
    console.log('nextOPTime', timestamp + 86400 * 10);
  });
  // Fast forward to the weight update time point
  it('show gauge weight info and lock ', async function () {
    await ethers.provider.send('evm_mine', [nextWeekTime]);
    // const timestamp = (await ethers.provider.getBlock(await ethers.provider.getBlockNumber())).timestamp;
    console.log('pool0 weight is:', ethers.utils.formatEther(await gaugeController.gaugeRelativeWeight(pool0, nextWeekTime)));
    console.log('pool1 weight is:', ethers.utils.formatEther(await gaugeController.gaugeRelativeWeight(pool1, nextWeekTime)));
    console.log('pool2 weight is:', ethers.utils.formatEther(await gaugeController.gaugeRelativeWeight(pool2, nextWeekTime)));
    console.log('-------------------------');

    // user0 try vote
    await expect(gaugeController.connect(user0).voteForGaugeWeights(pool0, 2000)).to.be.revertedWith(
      'GC: Cannot vote so often',
    );

    // user2 add lock
    await p12Token.connect(user2).approve(votingEscrow.address, 20n * 10n ** 18n);
    await votingEscrow.connect(user2).increaseAmount(20n * 10n ** 18n);

    // user1 try vote
    await expect(gaugeController.connect(user2).voteForGaugeWeights(pool1, 2000)).to.be.revertedWith(
      'GC: Cannot vote so often',
    );
  });
  // Fast forward to the weight update time point (two week)
  it('show gauge weight info and vote ', async function () {
    let timestamp = (await ethers.provider.getBlock(await ethers.provider.getBlockNumber())).timestamp;
    // if nextWeekTime > current timestamp and need to Fast forward to the nextWeekTime point
    const time = nextWeekTime > timestamp ? nextWeekTime : timestamp;
    if (nextWeekTime > timestamp) {
      await ethers.provider.send('evm_mine', [nextWeekTime]);
    }
    console.log('nextWeekTime', nextWeekTime);
    console.log('timestamp', timestamp);
    console.log('pool0 weight is:', ethers.utils.formatEther(await gaugeController.gaugeRelativeWeight(pool0, time)));
    console.log('pool1 weight is:', ethers.utils.formatEther(await gaugeController.gaugeRelativeWeight(pool1, time)));
    console.log('pool2 weight is:', ethers.utils.formatEther(await gaugeController.gaugeRelativeWeight(pool2, time)));
    console.log('-------------------------');

    // fast forward to right time point and vote
    // user0 vote
    const last1 = Number(await gaugeController.lastUserVote(user0.address, pool0));
    await ethers.provider.send('evm_mine', [last1 + 10 * 86400]);

    await gaugeController.connect(user0).voteForGaugeWeights(pool0, 2000);
    console.log('user0 vote pool0 info', await gaugeController.voteUserSlopes(user0.address, pool0));
    console.log('-------------------------');
    const last2 = Number(await gaugeController.lastUserVote(user0.address, pool1));
    timestamp = (await ethers.provider.getBlock(await ethers.provider.getBlockNumber())).timestamp;
    if (last2 + 10 * 86400 > timestamp) {
      await ethers.provider.send('evm_mine', [last2 + 10 * 86400]);
    }
    await gaugeController.connect(user0).voteForGaugeWeights(pool1, 0);
    console.log('user0 vote pool1 info', await gaugeController.voteUserSlopes(user0.address, pool1));
    console.log('-------------------------');

    // user2 vote
    timestamp = (await ethers.provider.getBlock(await ethers.provider.getBlockNumber())).timestamp;
    const last3 = Number(await gaugeController.lastUserVote(user2.address, pool0));
    if (last3 + 10 * 86400 > timestamp) {
      await ethers.provider.send('evm_mine', [last3 + 10 * 86400]);
    }
    await gaugeController.connect(user2).voteForGaugeWeights(pool0, 3000);
    console.log('user2 vote pool1 info', await gaugeController.voteUserSlopes(user0.address, pool1));
    console.log('-------------------------');
    timestamp = (await ethers.provider.getBlock(await ethers.provider.getBlockNumber())).timestamp;
    const last4 = Number(await gaugeController.lastUserVote(user2.address, pool1));
    if (last4 + 10 * 86400 > timestamp) {
      await ethers.provider.send('evm_mine', [last4 + 10 * 86400]);
    }
    await gaugeController.connect(user2).voteForGaugeWeights(pool1, 7000);
    console.log('user2 vote pool1 info', await gaugeController.voteUserSlopes(user2.address, pool1));
    console.log('-------------------------');
    const week = 86400 * 7;
    nextWeekTime = Math.floor((nextWeekTime + week) / week) * 86400 * 7;
    console.log('nextWeekTime', nextWeekTime);
    timestamp = (await ethers.provider.getBlock(await ethers.provider.getBlockNumber())).timestamp;
    console.log('timestamp is', timestamp);
    nextOPTime = timestamp + 10 * 86400;
  });
  // Fast forward to the weight update time point (3 weeks)
  it('show gauge weight info and vote', async function () {
    let timestamp = (await ethers.provider.getBlock(await ethers.provider.getBlockNumber())).timestamp;
    // if nextWeekTime > current timestamp and need to Fast forward to the nextWeekTime point
    const time = nextWeekTime > timestamp ? nextWeekTime : timestamp;
    if (nextWeekTime > timestamp) {
      await ethers.provider.send('evm_mine', [nextWeekTime]);
    }
    console.log('nextWeekTime', nextWeekTime);
    console.log('timestamp', timestamp);
    console.log('pool0 weight is:', ethers.utils.formatEther(await gaugeController.gaugeRelativeWeight(pool0, time)));
    console.log('pool1 weight is:', ethers.utils.formatEther(await gaugeController.gaugeRelativeWeight(pool1, time)));
    console.log('pool2 weight is:', ethers.utils.formatEther(await gaugeController.gaugeRelativeWeight(pool2, time)));
    console.log('-------------------------');

    // user0 lock
    await p12Token.connect(user0).approve(votingEscrow.address, 20n * 10n ** 18n);
    await votingEscrow.connect(user0).increaseUnlockTime(nextWeekTime + 365 * 86400);
    console.log('user0 balanceOf veP12', await votingEscrow.balanceOf(user0.address));
    console.log('user0 lockInfo', await votingEscrow.locked(user0.address));
    console.log('-------------------------');

    // user0 vote
    const lastTime = Number(await gaugeController.lastUserVote(user0.address, pool2));
    timestamp = (await ethers.provider.getBlock(await ethers.provider.getBlockNumber())).timestamp;
    if (lastTime + 10 * 86400 > timestamp) {
      await ethers.provider.send('evm_mine', [lastTime + 10 * 86400]);
    }
    await gaugeController.connect(user0).voteForGaugeWeights(pool2, 7500);
    console.log('user0 vote pool2 info', await gaugeController.voteUserSlopes(user0.address, pool2));
    console.log('-------------------------');

    // check user1 lock info
    console.log('user1 lock info', await votingEscrow.locked(user1.address));
    timestamp = (await ethers.provider.getBlock(await ethers.provider.getBlockNumber())).timestamp;
    if ((await votingEscrow.locked(user1.address).end) > timestamp) {
      await ethers.provider.send('evm_mine', [await votingEscrow.locked(user1.address).end]);
    }
    console.log('user1 veP12 balanceOf', await votingEscrow.balanceOf(user1.address));
  });
});
