import { expect } from 'chai';
import { ethers } from 'hardhat';
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';
import { deployAll, EconomyContract, ExternalContract } from '../../scripts/deploy';
import { Contract } from 'ethers/lib/ethers';
import * as compiledUniswapPair from '@uniswap/v2-core/build/UniswapV2Pair.json';

describe('p12Mine', function () {
  let admin: SignerWithAddress;
  let developer: SignerWithAddress;
  let user: SignerWithAddress;
  let core: EconomyContract & ExternalContract;
  let p12RewardVault: Contract;
  let gameCoinAddress: string;
  let pair: Contract;
  let liquidity: number;
  let id: string;
  let p12Dev: SignerWithAddress;
  this.beforeAll(async function () {
    // hardhat test accounts
    const accounts = await ethers.getSigners();
    admin = accounts[0];
    p12Dev = accounts[9];
    developer = accounts[1];
    user = accounts[2];
    core = await deployAll();
    await core.p12V0Factory.setDev(p12Dev.address);
  });

  // pause
  it('show pause successfully', async function () {
    await core.p12Mine.pause();
    const testPairAddress = ethers.Wallet.createRandom().address;
    await expect(core.p12Mine.createPool(testPairAddress)).to.be.revertedWith('Pausable: paused');
    await core.p12Mine.unpause();
    await core.p12Mine.createPool(testPairAddress);
  });

  // transfer p12Token token to the P12RewardVault
  it('show transfer p12Token successfully', async function () {
    const P12RewardVault = await ethers.getContractFactory('P12RewardVault');
    p12RewardVault = P12RewardVault.attach(await core.p12Mine.p12RewardVault());
    await core.p12Token.mint(p12RewardVault.address, 100000000n * 10n ** 18n);
    expect(await core.p12Token.balanceOf(p12RewardVault.address)).to.be.equal(100000000n * 10n ** 18n);
  });

  it('Should show developer register successfully', async function () {
    const gameId = '1101';
    await core.p12V0Factory.connect(p12Dev).register(gameId, developer.address);
    expect(await core.p12V0Factory.allGames('1101')).to.be.equal(developer.address);
  });

  it('Give developer p12 and approve p12 token to p12V0factory', async function () {
    await core.p12Token.connect(admin).transfer(developer.address, BigInt(3) * 10n ** 18n);
    expect(await core.p12Token.balanceOf(developer.address)).to.be.equal(3n * 10n ** 18n);
    await core.p12Token.connect(developer).approve(core.p12V0Factory.address, 3n * 10n ** 18n);
  });

  it('Should show gameCoin create successfully!', async function () {
    const name = 'GameCoin';
    const symbol = 'GC';
    const gameId = '1101';
    const gameCoinIconUrl =
      'https://images.weserv.nl/?url=https://i0.hdslb.com/bfs/article/87c5b43b19d4065f837f54637d3932e680af9c9b.jpg';
    const amountGameCoin = BigInt(10) * BigInt(10) ** 18n;
    const amountP12 = BigInt(1) * BigInt(10) ** 18n;

    await core.p12Token.connect(developer).approve(core.p12V0Factory.address, amountP12);
    const createInfo = await core.p12V0Factory
      .connect(developer)
      .create(name, symbol, gameId, gameCoinIconUrl, amountGameCoin, amountP12);

    (await createInfo.wait()).events!.forEach((x) => {
      if (x.event === 'CreateGameCoin') {
        gameCoinAddress = x.args!.gameCoinAddress;
      }
    });
    const pairAddress = await core.uniswapFactory.getPair(core.p12Token.address, gameCoinAddress);
    const Pair = new ethers.ContractFactory(compiledUniswapPair.interface, compiledUniswapPair.bytecode, admin);
    pair = Pair.attach(pairAddress);
    liquidity = await pair.balanceOf(core.p12Mine.address);
  });
  // create locker
  it('show create locker successfully', async function () {
    await core.p12Token.connect(developer).approve(core.votingEscrow.address, 200n * 10n ** 18n);
    await core.votingEscrow.connect(developer).createLock(2n * 10n ** 18n, 1716693857);
    const timestampBefore = (await ethers.provider.getBlock(await ethers.provider.getBlockNumber())).timestamp;
    await ethers.provider.send('evm_mine', [timestampBefore + 10 * 86400]);
  });
  // get gauge type
  it('show gauge type', async function () {
    expect(await core.gaugeController.getGaugeTypes(pair.address)).to.be.equal(0);
  });
  // vote for gauge
  it('show vote for gauge successfully', async function () {
    await core.gaugeController.connect(developer).voteForGaugeWeights(pair.address, 5000);
    const timestampBefore = (await ethers.provider.getBlock(await ethers.provider.getBlockNumber())).timestamp;
    await ethers.provider.send('evm_mine', [timestampBefore + 86400 * 10]);
    expect(await core.gaugeController.getTypeWeight(0)).to.be.equal(1n * 10n ** 18n);
  });

  // claim p12Token
  it('show claim p12Token successfully', async function () {
    await core.p12Mine.connect(developer).checkpoint(await core.p12Mine.getPid(pair.address));
    expect(await core.p12Mine.getPid(pair.address)).to.be.equal(1);
    const balanceOf = await core.p12Token.balanceOf(developer.address);
    await core.p12Mine.connect(developer).claim(pair.address);
    expect(await core.p12Token.balanceOf(developer.address)).to.be.above(balanceOf);
  });

  // attempts to forge false information to obtain lpToken and p12Tokens should fail
  it('should show that neither balanceOfLpToken nor balanceOfReward has changed ', async function () {
    const balanceOfLpToken = await core.p12Mine.getUserLpBalance(pair.address, user.address);
    const balanceOfReward = await core.p12Token.balanceOf(user.address);
    await expect(
      core.p12Mine
        .connect(user)
        .executeWithdraw(pair.address, '0x686a653b3b000000000000000000000000000000000000000000000000000000'),
    ).to.be.revertedWith('P12Mine: caller not token owner');
    expect(await core.p12Token.balanceOf(user.address)).to.be.equal(balanceOfReward);
    expect(await core.p12Mine.getUserLpBalance(pair.address, user.address)).to.be.equal(balanceOfLpToken);
  });

  // delay unStaking mining
  it('show  withdraw delay', async function () {
    const tx = await core.p12Mine.connect(developer).queueWithdraw(pair.address, liquidity);
    expect(await core.p12Mine.getUserLpBalance(pair.address, developer.address)).to.be.equal(liquidity);

    (await tx.wait()).events!.forEach((x) => {
      if (x.event === 'QueueWithdraw') {
        id = x.args!.newWithdrawId;
      }
    });
  });
  // try withdraw
  it('show withdraw fail', async function () {
    const timestampBefore = (await ethers.provider.getBlock(await ethers.provider.getBlockNumber())).timestamp;
    await ethers.provider.send('evm_mine', [timestampBefore + 60]);
    await expect(core.p12Mine.connect(developer).executeWithdraw(pair.address, id)).to.be.revertedWith(
      'P12Mine: unlock time not reached',
    );
  });

  it('show withdraw successfully', async function () {
    // time goes by
    const timestampBefore = (await ethers.provider.getBlock(await ethers.provider.getBlockNumber())).timestamp;
    await ethers.provider.send('evm_mine', [timestampBefore + 60]);
    await core.p12Mine.connect(developer).executeWithdraw(pair.address, id);
    expect(await core.p12Mine.getUserLpBalance(pair.address, developer.address)).to.be.equal(0);
    expect(await core.p12Token.balanceOf(developer.address)).to.be.above(0);
  });

  // reset delayK and delayB
  it('show set delayB and delayK success', async function () {
    await core.p12Mine.setDelayK(120);
    await core.p12Mine.setDelayB(120);
    expect(await core.p12Mine.delayK()).to.be.equal(120);
    expect(await core.p12Mine.delayB()).to.be.equal(120);
  });

  // reset rate
  it('show set new rate successfully', async function () {
    await core.p12Mine.setRate(4n * 10n ** 18n);
    expect(await core.p12Mine.rate()).to.be.equal(4n * 10n ** 18n);
  });

  // Staking Mining after reset delayK  delayB and p12Token
  it('show stake successfully', async function () {
    // use developer account
    const liquidity = await pair.balanceOf(developer.address);
    await pair.connect(developer).approve(core.p12Mine.address, liquidity);
    await core.p12Mine.connect(developer).deposit(pair.address, liquidity.div(2));
    expect(await core.p12Mine.getUserLpBalance(pair.address, developer.address)).to.be.equal(liquidity.div(2));
    await core.p12Mine.connect(developer).deposit(pair.address, liquidity.div(2));
    expect(await core.p12Mine.getUserLpBalance(pair.address, developer.address)).to.be.equal(liquidity);
  });

  // get pending p12Token
  it('show claim success', async function () {
    const balanceOfReward = await core.p12Token.balanceOf(user.address);
    const timestampBefore = (await ethers.provider.getBlock(await ethers.provider.getBlockNumber())).timestamp;
    await ethers.provider.send('evm_mine', [timestampBefore + 1200]);
    await core.p12Mine.connect(developer).claim(pair.address);
    expect(await core.p12Token.balanceOf(developer.address)).to.be.above(balanceOfReward);
  });

  // try withdraw
  it('show withdraw fail', async function () {
    expect(core.p12Mine.executeWithdraw(pair.address, id)).to.be.revertedWith('P12Mine: can only be withdraw once');
  });

  // delay unStaking mining
  it('show  withdraw delay', async function () {
    const info = await core.p12Mine.userInfo(await core.p12Mine.getPid(pair.address), developer.address);
    const tx = await core.p12Mine.connect(developer).queueWithdraw(pair.address, info.amount);
    expect(await core.p12Mine.getUserLpBalance(pair.address, developer.address)).to.be.equal(info.amount);

    (await tx.wait()).events!.forEach((x) => {
      if (x.event === 'QueueWithdraw') {
        id = x.args!.newWithdrawId;
      }
    });
  });

  // claim  pending p12Token with fake account
  it('show claim nothing', async function () {
    const balanceOfReward = await core.p12Token.balanceOf(admin.address);
    await expect(core.p12Mine.connect(admin).claim(pair.address)).to.be.revertedWith('P12Mine: no staked token');
    expect(await core.p12Token.balanceOf(admin.address)).to.be.equal(balanceOfReward);
  });

  // get pending p12Token by claimAll
  it('show claimAll successfully', async function () {
    const timestampBefore = (await ethers.provider.getBlock(await ethers.provider.getBlockNumber())).timestamp;
    await ethers.provider.send('evm_mine', [timestampBefore + 86400 * 7]);
    const balanceOfReward = await core.p12Token.balanceOf(developer.address);
    await core.p12Mine.connect(developer).claimAll();
    expect(await core.p12Token.balanceOf(developer.address)).to.be.above(balanceOfReward);
  });

  it('show withdraw successfully', async function () {
    // time goes by
    const balanceOf = await core.p12Token.balanceOf(developer.address);
    const timestampBefore = (await ethers.provider.getBlock(await ethers.provider.getBlockNumber())).timestamp;
    await ethers.provider.send('evm_mine', [timestampBefore + 600]);
    await core.p12Mine.connect(developer).executeWithdraw(pair.address, id);
    expect(await core.p12Mine.getUserLpBalance(pair.address, developer.address)).to.be.equal(0);
    expect(await core.p12Token.balanceOf(developer.address)).to.be.above(balanceOf);
  });

  // staking an unregistered pool
  it('show staking fail', async function () {
    const balance = await core.p12Token.balanceOf(user.address);
    await core.p12Token.connect(user).approve(core.p12Mine.address, balance);
    await expect(core.p12Mine.connect(user).deposit(core.p12Token.address, balance)).to.be.revertedWith(
      'P12Mine: LP Token Not Exist',
    );
  });

  // try create an existing pool
  it('show create an existing pool fail', async function () {
    const before = await core.p12Mine.poolLength();
    await expect(core.p12Mine.connect(admin).createPool(pair.address)).to.be.revertedWith('P12Mine: LP Token Already Exist');
    expect(await core.p12Mine.lpTokenRegistry(pair.address)).to.be.equal(before);
  });

  // get pool info
  it('show get pool info success', async function () {
    const len = await core.p12Mine.poolLength();
    expect(len).to.equal(2);
    const pid = await core.p12Mine.getPid(pair.address);
    const tmp = await core.p12Mine.lpTokenRegistry(pair.address);
    expect(pid).to.be.equal(tmp.sub(1));
  });

  // update checkpoint
  it('show checkpoint  success', async function () {
    await core.p12Mine.checkpoint(0);
  });

  // update checkpoint all
  it('show checkpoint  success', async function () {
    await core.p12Mine.checkpointAll();
  });

  // withdraw p12token Emergency by admin
  it('show withdraw p12token Emergency successfully', async function () {
    await expect(core.p12Mine.withdrawEmergency()).to.be.revertedWith('no emergency now');
    await core.p12Mine.emergency();
    await expect(core.p12Mine.withdrawEmergency()).to.be.revertedWith('P12Mine: not unlocked yet');
    const balanceOf = await core.p12Token.balanceOf(p12RewardVault.address);
    const balanceOfAdmin = await core.p12Token.balanceOf(admin.address);
    const timestampBefore = (await ethers.provider.getBlock(await ethers.provider.getBlockNumber())).timestamp;
    await ethers.provider.send('evm_mine', [timestampBefore + 86400]);
    await core.p12Mine.withdrawEmergency();
    expect(await core.p12Token.balanceOf(admin.address)).be.be.equal(balanceOf.add(balanceOfAdmin));
    await expect(core.p12Mine.emergency()).to.be.revertedWith('P12Mine: already exists');
  });

  // withdraw lpTokens Emergency
  it('show withdraw lpTokens Emergency successfully', async function () {
    await expect(core.p12Mine.withdrawLpTokenEmergency(pair.address)).to.be.revertedWith('P12Mine: without any lpToken');
    const balanceOf = await pair.balanceOf(developer.address);
    await pair.connect(developer).approve(core.p12Mine.address, balanceOf);
    await core.p12Mine.connect(developer).deposit(pair.address, balanceOf);
    expect(await core.p12Mine.getUserLpBalance(pair.address, developer.address)).to.be.equal(balanceOf);
    await core.p12Mine.connect(developer).withdrawLpTokenEmergency(pair.address);
    expect(await pair.balanceOf(developer.address)).to.be.equal(balanceOf);
    expect(await core.p12Mine.getUserLpBalance(pair.address, developer.address)).to.be.equal(0);

    await pair.connect(developer).approve(core.p12Mine.address, balanceOf);
    await core.p12Mine.connect(developer).deposit(pair.address, balanceOf);
    expect(await core.p12Mine.getUserLpBalance(pair.address, developer.address)).to.be.equal(balanceOf);
    await core.p12Mine.connect(developer).withdrawAllLpTokenEmergency();
    expect(await pair.balanceOf(developer.address)).to.be.equal(balanceOf);
    expect(await core.p12Mine.getUserLpBalance(pair.address, developer.address)).to.be.equal(0);
  });
});
