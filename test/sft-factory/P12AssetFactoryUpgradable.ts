import { expect } from 'chai';
import { ethers, upgrades } from 'hardhat';
import { P12AssetFactoryUpgradable, P12V0FactoryTem, P12Asset } from '../../typechain';
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';
import { Contract } from 'ethers';

describe('P12ExchangeUpgradable', function () {
  // admin: Who deploy factory contract
  let admin: SignerWithAddress;
  // developer1: Who have register a gameId on P12Factory
  let developer1: SignerWithAddress;
  // developer2: Who don't register a gameId on P12Factory
  let developer2: SignerWithAddress;
  // user1: not Used Now
  let user1: SignerWithAddress;
  // p12factory: Register Game and create GameCoin
  let p12factory: P12V0FactoryTem;
  //
  let p12AssetFactoryAddr: Contract;
  let p12AssetFactory: P12AssetFactoryUpgradable;
  let collectionAddr: string;
  let collection: P12Asset;
  let tokenId1: BigInt;
  let amount1: BigInt;
  let tokenId2: BigInt;
  let amount2: BigInt;

  this.beforeAll(async () => {
    // distribute account
    const accounts = await ethers.getSigners();
    admin = accounts[0];
    developer1 = accounts[1];
    developer2 = accounts[2];
    user1 = accounts[3];

    // // deploy p12 coin
    // const P12CoinF = await ethers.getContractFactory("P12Coin");
    // p12coin = await P12CoinF.deploy();

    // // mint p12 Coin
    // await p12coin.mint(user1.address, 100n * 10n ** 18n);
    // await p12coin.mint(user2.address, 100n * 10n ** 18n);
    // expect(await p12coin.balanceOf(user1.address)).to.be.equal(
    //   100n * 10n ** 18n
    // );
    // expect(await p12coin.balanceOf(user2.address)).to.be.equal(
    //   100n * 10n ** 18n
    // );

    // deploy p12factory
    const p12factoryF = await ethers.getContractFactory('P12V0FactoryTem');
    p12factory = await p12factoryF.deploy();

    // register game
    await p12factory.register('gameId1', developer1.address);
  });

  it('Should P12AssetFactoryUpgradable Deploy successfully', async function () {
    const P12AssetFactoryUpgradableF = await ethers.getContractFactory('P12AssetFactoryUpgradable');
    p12AssetFactoryAddr = await upgrades.deployProxy(P12AssetFactoryUpgradableF, [p12factory.address], {
      kind: 'uups',
    });
    p12AssetFactory = await ethers.getContractAt('P12AssetFactoryUpgradable', p12AssetFactoryAddr.address);
  });

  it('Should developer1 create collection successfully', async function () {
    const tx = await p12AssetFactory.connect(developer1).createCollection('gameId1', 'ipfs://');
    (await tx.wait()).events?.forEach((x) => {
      if (x.event === 'CollectionCreated') {
        collectionAddr = x.args?.collection;
      }
    });

    expect(collectionAddr).to.lengthOf(42);

    collection = await ethers.getContractAt('P12Asset', collectionAddr);
  });

  it('Should developer2 create collection fail', async () => {
    await expect(p12AssetFactory.connect(developer2).createCollection('gameId1', 'ipfs://')).to.be.revertedWith(
      'P12Asset: not game developer',
    );
  });

  it('Should developer1 create asset successfully', async () => {
    const tx = await p12AssetFactory.connect(developer1).createAssetAndMint(collection.address, 10, 'ipfs://');

    const event = (await tx.wait()).events?.find((event) => event.event === 'SftCreated')!;

    tokenId1 = event.args?.tokenId;
    amount1 = event.args?.amount;

    expect(tokenId1).to.be.equal(0);
    expect(amount1).to.be.equal(10);
    expect(await collection.balanceOf(developer1.address, 0)).to.be.equal(10);
  });

  it('Should developer1 create asset again successfully', async () => {
    const tx = await p12AssetFactory.connect(developer1).createAssetAndMint(collection.address, 10, 'ipfs://');

    const event = (await tx.wait()).events?.find((event) => event.event === 'SftCreated')!;

    tokenId2 = event.args?.tokenId;
    amount2 = event.args?.amount;

    expect(tokenId2).to.be.equal(1);
    expect(amount2).to.be.equal(10);
  });

  it('Should upgrade successfully', async () => {
    const P12AssetFactoryAlter = await ethers.getContractFactory('P12AssetFactoryUpgradableAlternative');

    const p12ExchangeAlter = await upgrades.upgradeProxy(p12AssetFactory.address, P12AssetFactoryAlter);

    await p12ExchangeAlter.setName('Project Twelve');
    expect(await p12ExchangeAlter.getName()).to.be.equal('Project Twelve');
  });
});
