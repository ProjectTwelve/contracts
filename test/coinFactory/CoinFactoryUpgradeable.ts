import { ethers, upgrades } from 'hardhat';
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';
import { expect } from 'chai';
import { deployAll, EconomyContract, ExternalContract } from '../../scripts/deploy';
import { Wallet } from 'ethers';

describe('P12CoinFactory', function () {
  let admin: SignerWithAddress;
  let p12Dev: SignerWithAddress;
  let gameDeveloper: Wallet;
  let admin2: SignerWithAddress;
  let user: SignerWithAddress;
  let mintId: string;
  let gameCoinAddress: string;
  let core: EconomyContract & ExternalContract;
  let test: SignerWithAddress;
  this.beforeAll(async function () {
    // hardhat test accounts
    const accounts = await ethers.getSigners();
    admin = accounts[0];
    admin2 = accounts[1];
    // gameDeveloper = accounts[2];
    user = accounts[3];
    p12Dev = accounts[8];
    test = accounts[9];
    core = await deployAll();
    await core.p12CoinFactory.setDev(p12Dev.address);
    const adminPrivateKey = 'cf53da8e2fab30a115e2f8eadc4b774b9ef025b3b9cde5342e9ad90b47d7dbc3';
    gameDeveloper = new ethers.Wallet(adminPrivateKey, ethers.provider);
    core.p12Token.connect(admin).transfer(gameDeveloper.address, 100n * 10n ** 18n);
    const tx = {
      to: gameDeveloper.address,
      // Convert currency unit from ether to wei
      value: 10n * 10n ** 18n,
    };
    await admin.sendTransaction(tx);
  });
  it('Should pausable effective', async () => {
    await core.p12CoinFactory.pause();
    expect(core.p12CoinFactory.create('', '', '', '', 0n, 0n)).to.be.revertedWith('Pausable: paused');
    expect(core.p12CoinFactory.queueMintCoin('', '', 0n)).to.be.revertedWith('Pausable: paused');
    expect(core.p12CoinFactory.executeMintCoin('', '')).to.be.revertedWith('Pausable: paused');
    await core.p12CoinFactory.unpause();
  });

  it('Should show gameDeveloper register successfully', async function () {
    const gameId = '1101';
    await core.p12CoinFactory.connect(p12Dev).register(gameId, gameDeveloper.address);
    expect(await core.p12CoinFactory.allGames('1101')).to.be.equal(gameDeveloper.address);
  });
  it('should show register fail by test account', async function () {
    const gameId2 = '1102';
    await expect(core.p12CoinFactory.connect(test).register(gameId2, gameDeveloper.address)).to.be.revertedWith(
      'P12Factory: caller must be dev',
    );
  });
  it('Give gameDeveloper p12 and approve p12 token to p12V0factory', async function () {
    await core.p12Token.connect(admin).transfer(gameDeveloper.address, BigInt(3) * 10n ** 18n);
    expect(await core.p12Token.balanceOf(gameDeveloper.address)).to.be.equal(3n * 10n ** 18n);
    await core.p12Token.connect(gameDeveloper).approve(core.p12CoinFactory.address, 3n * 10n ** 18n);
  });
  it('Should show gameCoin create successfully!', async function () {
    const name = 'GameCoin';
    const symbol = 'GC';
    const gameId = '1101';
    const gameCoinIconUrl =
      'https://images.weserv.nl/?url=https://i0.hdslb.com/bfs/article/87c5b43b19d4065f837f54637d3932e680af9c9b.jpg';
    const amountGameCoin = BigInt(10) * BigInt(10) ** 18n;
    const amountP12 = BigInt(1) * BigInt(10) ** 18n;

    await core.p12Token.connect(gameDeveloper).approve(core.p12CoinFactory.address, amountP12);
    const createInfo = await core.p12CoinFactory
      .connect(gameDeveloper)
      .create(name, symbol, gameId, gameCoinIconUrl, amountGameCoin, amountP12);

    (await createInfo.wait()).events!.forEach((x) => {
      if (x.event === 'CreateGameCoin') {
        gameCoinAddress = x.args!.gameCoinAddress;
      }
    });
  });

  it('Should show set delay variable successfully! ', async function () {
    await core.p12CoinFactory.connect(admin).setDelayK(1);
    await core.p12CoinFactory.connect(admin).setDelayB(1);
    expect(await core.p12CoinFactory.delayK()).to.be.equal(1);
    expect(await core.p12CoinFactory.delayB()).to.be.equal(1);
  });

  // it("Check gameCoin mint fee", async function () {
  //   const price = await core.p12CoinFactory.getMintFee(
  //     gameCoinAddress,
  //     BigInt(30) * BigInt(10) ** 18n
  //   );
  //   console.log("check gameCoin mint fee", price);
  // });

  it('Check gameCoin mint delay time', async function () {
    await core.p12CoinFactory.getMintDelay(gameCoinAddress, BigInt(5) * BigInt(10) ** 18n);
  });
  it('Should show declare mint successfully!', async function () {
    const amountP12 = BigInt(6) * BigInt(10) ** 17n;
    await core.p12Token.connect(gameDeveloper).approve(core.p12CoinFactory.address, amountP12);
    const tx = await core.p12CoinFactory
      .connect(gameDeveloper)
      .queueMintCoin('1101', gameCoinAddress, BigInt(5) * BigInt(10) ** 18n);
    (await tx.wait()).events!.forEach((x) => {
      if (x.event === 'QueueMintCoin') {
        mintId = x.args!.mintId;
      }
    });
  });

  it('Should show execute mint successfully!', async function () {
    const blockNumBefore = await ethers.provider.getBlockNumber();
    const blockBefore = await ethers.provider.getBlock(blockNumBefore);
    const timestampBefore = blockBefore.timestamp;
    await ethers.provider.send('evm_mine', [timestampBefore + 5000]);
    await core.p12CoinFactory.executeMintCoin(gameCoinAddress, mintId);
  });
  it('Should show duplicate mint fail!', async function () {
    const blockNumBefore = await ethers.provider.getBlockNumber();
    const blockBefore = await ethers.provider.getBlock(blockNumBefore);
    const timestampBefore = blockBefore.timestamp;
    await ethers.provider.send('evm_mine', [timestampBefore + 5000]);
    await expect(core.p12CoinFactory.executeMintCoin(gameCoinAddress, mintId)).to.be.revertedWith('P12Factory: mint executed');
  });

  it('Should show change game gameDeveloper successfully !', async function () {
    const gameId = '1101';
    await core.p12CoinFactory.connect(p12Dev).register(gameId, admin.address);
    expect(await core.p12CoinFactory.allGames('1101')).to.be.equal(admin.address);
  });

  it('Should show withdraw gameCoin successfully', async function () {
    await core.p12CoinFactory.connect(p12Dev).withdraw(user.address, gameCoinAddress, 1n * 10n ** 18n);
    const P12GameCoin = await ethers.getContractFactory('TestGameCoin');
    const gameCoin = P12GameCoin.attach(gameCoinAddress);

    expect(await gameCoin.balanceOf(user.address)).to.be.equal(1n * 10n ** 18n);
  });
  it('should transfer ownership successfully', async () => {
    await expect(core.p12CoinFactory.transferOwnership(ethers.constants.AddressZero, false)).to.be.revertedWith(
      'SafeOwnable: new owner is 0',
    );

    await expect(core.p12CoinFactory.connect(admin2).claimOwnership()).to.be.revertedWith('SafeOwnable: caller != pending');

    await core.p12CoinFactory.transferOwnership(Buffer.from(ethers.utils.randomBytes(20)).toString('hex'), false);
    await core.p12CoinFactory.transferOwnership(admin2.address, false);

    await expect(
      core.p12CoinFactory.connect(admin2).upgradeTo(Buffer.from(ethers.utils.randomBytes(20)).toString('hex')),
    ).to.be.revertedWith('SafeOwnable: caller not owner');

    await core.p12CoinFactory.connect(admin2).claimOwnership();
    await core.p12CoinFactory.connect(admin2).transferOwnership(admin.address, false);
    await core.p12CoinFactory.claimOwnership();
  });
  it('Should contract upgrade successfully', async function () {
    const p12FactoryAlterF = await ethers.getContractFactory('P12CoinFactoryUpgradeableAlter');

    await upgrades.upgradeProxy(core.p12CoinFactory.address, p12FactoryAlterF);
    const p12FactoryAlter = await ethers.getContractAt('P12CoinFactoryUpgradeableAlter', core.p12CoinFactory.address);

    await p12FactoryAlter.callWhiteBlack();
  });
});
