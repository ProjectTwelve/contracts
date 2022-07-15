import { ethers, upgrades } from 'hardhat';
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';
import { expect } from 'chai';
import { deployAll, EconomyContract, ExternalContract } from '../../scripts/deploy';

describe('p12V0Factory', function () {
  let admin: SignerWithAddress;
  let p12Dev: SignerWithAddress;
  let gameDeveloper: SignerWithAddress;
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
    gameDeveloper = accounts[2];
    user = accounts[3];
    p12Dev = accounts[8];
    test = accounts[9];
    core = await deployAll();
    await core.p12V0Factory.setDev(p12Dev.address);
  });
  it('Should pausable effective', async () => {
    await core.p12V0Factory.pause();
    expect(core.p12V0Factory.create('', '', '', '', 0n, 0n)).to.be.revertedWith('Pausable: paused');
    expect(core.p12V0Factory.queueMintCoin('', '', 0n)).to.be.revertedWith('Pausable: paused');
    expect(core.p12V0Factory.executeMintCoin('', '')).to.be.revertedWith('Pausable: paused');
    await core.p12V0Factory.unpause();
  });

  it('Should show gameDeveloper register successfully', async function () {
    const gameId = '1101';
    await core.p12V0Factory.connect(p12Dev).register(gameId, gameDeveloper.address);
    expect(await core.p12V0Factory.allGames('1101')).to.be.equal(gameDeveloper.address);
  });
  it('should show register fail by test account', async function () {
    const gameId2 = '1102';
    await expect(core.p12V0Factory.connect(test).register(gameId2, gameDeveloper.address)).to.be.revertedWith(
      'P12Factory: caller must be dev',
    );
  });
  it('Give gameDeveloper p12 and approve p12 token to p12V0factory', async function () {
    await core.p12Token.connect(admin).transfer(gameDeveloper.address, BigInt(3) * 10n ** 18n);
    expect(await core.p12Token.balanceOf(gameDeveloper.address)).to.be.equal(3n * 10n ** 18n);
    await core.p12Token.connect(gameDeveloper).approve(core.p12V0Factory.address, 3n * 10n ** 18n);
  });
  it('Should show gameCoin create successfully!', async function () {
    const name = 'GameCoin';
    const symbol = 'GC';
    const gameId = '1101';
    const gameCoinIconUrl =
      'https://images.weserv.nl/?url=https://i0.hdslb.com/bfs/article/87c5b43b19d4065f837f54637d3932e680af9c9b.jpg';
    const amountGameCoin = BigInt(10) * BigInt(10) ** 18n;
    const amountP12 = BigInt(1) * BigInt(10) ** 18n;

    await core.p12Token.connect(gameDeveloper).approve(core.p12V0Factory.address, amountP12);
    const createInfo = await core.p12V0Factory
      .connect(gameDeveloper)
      .create(name, symbol, gameId, gameCoinIconUrl, amountGameCoin, amountP12);

    (await createInfo.wait()).events!.forEach((x) => {
      if (x.event === 'CreateGameCoin') {
        gameCoinAddress = x.args!.gameCoinAddress;
      }
    });
  });

  it('Should show set delay variable successfully! ', async function () {
    await core.p12V0Factory.connect(admin).setDelayK(1);
    await core.p12V0Factory.connect(admin).setDelayB(1);
    expect(await core.p12V0Factory.delayK()).to.be.equal(1);
    expect(await core.p12V0Factory.delayB()).to.be.equal(1);
  });

  // it("Check gameCoin mint fee", async function () {
  //   const price = await core.p12V0Factory.getMintFee(
  //     gameCoinAddress,
  //     BigInt(30) * BigInt(10) ** 18n
  //   );
  //   console.log("check gameCoin mint fee", price);
  // });

  it('Check gameCoin mint delay time', async function () {
    await core.p12V0Factory.getMintDelay(gameCoinAddress, BigInt(5) * BigInt(10) ** 18n);
  });
  it('Should show declare mint successfully!', async function () {
    const amountP12 = BigInt(6) * BigInt(10) ** 17n;
    await core.p12Token.connect(gameDeveloper).approve(core.p12V0Factory.address, amountP12);
    const tx = await core.p12V0Factory
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
    await core.p12V0Factory.executeMintCoin(gameCoinAddress, mintId);
  });
  it('Should show duplicate mint fail!', async function () {
    const blockNumBefore = await ethers.provider.getBlockNumber();
    const blockBefore = await ethers.provider.getBlock(blockNumBefore);
    const timestampBefore = blockBefore.timestamp;
    await ethers.provider.send('evm_mine', [timestampBefore + 5000]);
    await expect(core.p12V0Factory.executeMintCoin(gameCoinAddress, mintId)).to.be.revertedWith('this mint has been executed');
  });

  it('Should show change game gameDeveloper successfully !', async function () {
    const gameId = '1101';
    await core.p12V0Factory.connect(p12Dev).register(gameId, admin.address);
    expect(await core.p12V0Factory.allGames('1101')).to.be.equal(admin.address);
  });

  it('Should show withdraw gameCoin successfully', async function () {
    await core.p12V0Factory.connect(admin).withdraw(user.address, gameCoinAddress, 1n * 10n ** 18n);
    const P12V0ERC20 = await ethers.getContractFactory('P12V0ERC20');
    const p12V0ERC20 = await P12V0ERC20.attach(gameCoinAddress);

    expect(await p12V0ERC20.balanceOf(user.address)).to.be.equal(1n * 10n ** 18n);
  });
  it('should transfer ownership successfully', async () => {
    await expect(core.p12V0Factory.transferOwnership(ethers.constants.AddressZero, false)).to.be.revertedWith(
      'SafeOwnable: new owner is zero',
    );

    await expect(core.p12V0Factory.connect(admin2).claimOwnership()).to.be.revertedWith('SafeOwnable: caller != pending');

    await core.p12V0Factory.transferOwnership(Buffer.from(ethers.utils.randomBytes(20)).toString('hex'), false);
    await core.p12V0Factory.transferOwnership(admin2.address, false);

    await expect(
      core.p12V0Factory.connect(admin2).upgradeTo(Buffer.from(ethers.utils.randomBytes(20)).toString('hex')),
    ).to.be.revertedWith('SafeOwnable: caller not the owner');

    await core.p12V0Factory.connect(admin2).claimOwnership();
    await core.p12V0Factory.connect(admin2).transferOwnership(admin.address, false);
    await core.p12V0Factory.claimOwnership();
  });
  it('Should contract upgrade successfully', async function () {
    const p12FactoryAlterF = await ethers.getContractFactory('P12V0FactoryUpgradeableAlter');

    await upgrades.upgradeProxy(core.p12V0Factory.address, p12FactoryAlterF);
    const p12FactoryAlter = await ethers.getContractAt('P12V0FactoryUpgradeableAlter', core.p12V0Factory.address);

    await p12FactoryAlter.callWhiteBlack();
  });
});
