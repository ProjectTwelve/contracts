import { ethers } from 'hardhat';
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';
import { expect } from 'chai';
import { fixtureAll, EconomyContract, ExternalContract } from '../../scripts/deploy';
import { P12CoinFactoryUpgradeableAlter, P12GameCoin } from '../../typechain-types';
import { randomAddress } from '../../tools/utils';
import { randomBytes } from 'crypto';

describe('P12CoinFactory', function () {
  let admin: SignerWithAddress;
  let p12Dev: SignerWithAddress;
  let gameDeveloper: SignerWithAddress;
  let admin2: SignerWithAddress;
  let user: SignerWithAddress;
  let mintId: string;
  let gameCoinAddress: string;
  let gameCoin: P12GameCoin;
  let core: EconomyContract & ExternalContract;
  let test: SignerWithAddress;
  this.beforeAll(async function () {
    // hardhat test accounts
    const accounts = await ethers.getSigners();
    admin = accounts[0];
    admin2 = accounts[1];
    gameDeveloper = accounts[2];
    user = accounts[3];
    p12Dev = accounts[8];
    test = accounts[9];
    core = await fixtureAll();
    await core.p12CoinFactory.setDev(p12Dev.address);
  });
  it('Should pausable effective', async () => {
    await core.p12CoinFactory.pause();
    await expect(core.p12CoinFactory.create('', '', '', '', 0n, 0n)).to.be.revertedWith('Pausable: paused');
    await expect(core.p12CoinFactory.queueMintCoin('', randomAddress(), 0n)).to.be.revertedWith('Pausable: paused');
    await expect(core.p12CoinFactory.executeMintCoin(randomAddress(), randomBytes(32))).to.be.revertedWith('Pausable: paused');
    await core.p12CoinFactory.unpause();
  });

  it('Should show gameDeveloper register successfully', async function () {
    const gameId = '1101';
    await core.p12CoinFactory.connect(p12Dev).register(gameId, gameDeveloper.address);
    expect(await core.p12CoinFactory.allGames('1101')).to.be.equal(gameDeveloper.address);
  });
  it('should show register fail by test account', async function () {
    const gameId2 = '1102';
    await expect(core.p12CoinFactory.connect(test).register(gameId2, gameDeveloper.address)).to.be.revertedWith('NotP12Dev');
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
    gameCoin = await ethers.getContractAt('P12GameCoin', gameCoinAddress);
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
    await core.p12CoinFactory.getMintDelay(gameCoin.address, BigInt(5) * BigInt(10) ** 18n);
  });
  it('Should show declare mint successfully!', async function () {
    const amountP12 = BigInt(6) * BigInt(10) ** 17n;
    await core.p12Token.connect(gameDeveloper).approve(core.p12CoinFactory.address, amountP12);
    const tx = await core.p12CoinFactory
      .connect(gameDeveloper)
      .queueMintCoin('1101', gameCoin.address, BigInt(5) * BigInt(10) ** 18n);
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
    await core.p12CoinFactory.executeMintCoin(gameCoin.address, mintId);
  });
  it('Should show duplicate mint fail!', async function () {
    const blockNumBefore = await ethers.provider.getBlockNumber();
    const blockBefore = await ethers.provider.getBlock(blockNumBefore);
    const timestampBefore = blockBefore.timestamp;
    await ethers.provider.send('evm_mine', [timestampBefore + 5000]);
    await expect(core.p12CoinFactory.executeMintCoin(gameCoin.address, mintId))
      .to.be.revertedWith('ExecutedMint')
      .withArgs(mintId);
  });

  it('Should show change game gameDeveloper successfully !', async function () {
    const gameId = '1101';
    await core.p12CoinFactory.connect(p12Dev).register(gameId, admin.address);
    expect(await core.p12CoinFactory.allGames('1101')).to.be.equal(admin.address);
  });

  it('Should show withdraw gameCoin successfully', async function () {
    await core.p12CoinFactory.connect(p12Dev).withdraw(user.address, gameCoin.address, 1n * 10n ** 18n);

    expect(await gameCoin.balanceOf(user.address)).to.be.equal(1n * 10n ** 18n);
  });
  it('should transfer ownership successfully', async () => {
    await expect(core.p12CoinFactory.transferOwnership(ethers.constants.AddressZero, false)).to.be.revertedWith(
      'ZeroAddressSet',
    );

    await expect(core.p12CoinFactory.connect(admin2).claimOwnership()).to.be.revertedWith('NoPermission');

    await core.p12CoinFactory.transferOwnership(Buffer.from(ethers.utils.randomBytes(20)).toString('hex'), false);
    await core.p12CoinFactory.transferOwnership(admin2.address, false);

    await expect(
      core.p12CoinFactory.connect(admin2).upgradeTo(Buffer.from(ethers.utils.randomBytes(20)).toString('hex')),
    ).to.be.revertedWith('NoPermission');

    await core.p12CoinFactory.connect(admin2).claimOwnership();
    await core.p12CoinFactory.connect(admin2).transferOwnership(admin.address, false);
    await core.p12CoinFactory.claimOwnership();
  });
  it('Should update token name, symbol, iconUrl successfully', async function () {
    await expect(core.p12CoinFactory.setTokenName(gameCoin.address, 'NewGameCoin'))
      .to.be.emit(gameCoin, 'NameUpdated')
      .withArgs('GameCoin', 'NewGameCoin');
    expect(await gameCoin.name()).to.be.equal('NewGameCoin');

    await expect(core.p12CoinFactory.setTokenSymbol(gameCoin.address, 'NGC'))
      .to.be.emit(gameCoin, 'SymbolUpdated')
      .withArgs('GC', 'NGC');
    expect(await gameCoin.symbol()).to.be.equal('NGC');

    await expect(core.p12CoinFactory.setTokenIconUrl(gameCoin.address, 'https://example.com'))
      .to.emit(gameCoin, 'IconUrlUpdated')
      .withArgs(
        'https://images.weserv.nl/?url=https://i0.hdslb.com/bfs/article/87c5b43b19d4065f837f54637d3932e680af9c9b.jpg',
        'https://example.com',
      );
    expect(await gameCoin.gameCoinIconUrl()).to.be.equal('https://example.com');
  });
  it('Should contract upgrade successfully', async function () {
    const p12FactoryAlterF = await ethers.getContractFactory('P12CoinFactoryUpgradeableAlter');

    const newImplementation = await p12FactoryAlterF.deploy();

    core.p12CoinFactory.upgradeTo(newImplementation.address);
    const p12FactoryAlter = await ethers.getContractAt<P12CoinFactoryUpgradeableAlter>(
      'P12CoinFactoryUpgradeableAlter',
      core.p12CoinFactory.address,
    );

    await p12FactoryAlter.callWhiteBlack();
  });
});
