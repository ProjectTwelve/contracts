import { expect } from 'chai';
import { ethers } from 'hardhat';
import { P12AssetFactoryUpgradable, P12Asset, P12CoinFactoryUpgradeable } from '../../typechain';
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';
import { getContract } from '../../scripts/deploy';

describe('P12AssetFactoryUpgradable', function () {
  // admin: Who deploy factory contract
  let admin: SignerWithAddress;
  // developer1: Who have register a gameId on P12Factory
  let developer1: SignerWithAddress;
  // developer2: Who don't register a gameId on P12Factory
  let developer2: SignerWithAddress;
  // user1: not Used Now
  // let user1: SignerWithAddress;
  // p12factory: Register Game and create GameCoin
  let p12CoinFactory: P12CoinFactoryUpgradeable;
  //
  let p12AssetFactory: P12AssetFactoryUpgradable;
  let collectionAddr: string;
  let collection: P12Asset;
  let p12Dev: SignerWithAddress;

  this.beforeAll(async () => {
    // distribute account
    const accounts = await ethers.getSigners();
    admin = accounts[0];
    developer1 = accounts[1];
    developer2 = accounts[2];
    p12Dev = accounts[9];

    p12CoinFactory = await getContract<P12CoinFactoryUpgradeable>('P12CoinFactoryUpgradeable');

    // set dev
    await p12CoinFactory.setDev(p12Dev.address);
    // register game
    await p12CoinFactory.connect(p12Dev).register('gameId1', developer1.address);

    p12AssetFactory = await getContract<P12AssetFactoryUpgradable>('P12AssetFactoryUpgradable');
  });

  it('Should developer1 create collection successfully', async function () {
    const tx = await p12AssetFactory.connect(developer1).createCollection('gameId1', 'ipfs://');

    // await expect(p12AssetFactory.connect(developer1).createCollection('gameId1', 'ipfs://'))
    //   .to.emit(p12AssetFactory.address, 'CollectionCreated')
    //   .withArgs(collection.address, developer1.address);

    (await tx.wait()).events?.forEach((x) => {
      if (x.event === 'CollectionCreated') {
        collectionAddr = x.args?.collection;
      }
    });

    expect(collectionAddr).to.lengthOf(42);

    collection = await ethers.getContractAt('P12Asset', collectionAddr);
    expect(await collection.contractURI()).to.be.equal('ipfs://');
  });

  it('Should change contract uri successfully', async () => {
    await p12AssetFactory.connect(developer1).updateCollectionUri(collection.address, 'ar://');
    expect(await collection.contractURI()).to.be.equal('ar://');
  });

  it('Should developer2 create collection fail', async () => {
    await expect(p12AssetFactory.connect(developer2).createCollection('gameId1', 'ipfs://')).to.be.revertedWith(
      'P12AssetF: not game developer',
    );
  });

  it('Should developer1 create asset successfully', async () => {
    await expect(p12AssetFactory.connect(developer1).createAssetAndMint(collection.address, 10, 'ipfs://'))
      .to.emit(p12AssetFactory, 'SftCreated')
      .withArgs(collection.address, 0, 10);

    expect(await collection.balanceOf(developer1.address, 0)).to.be.equal(10);
    expect(await collection.uri(0)).to.be.equal('ipfs://');
  });

  it('Should developer1 create asset again successfully', async () => {
    await p12AssetFactory.connect(admin).pause();
    await expect(p12AssetFactory.connect(developer1).createAssetAndMint(collection.address, 10, 'ipfs://')).to.be.revertedWith(
      'Pausable: paused',
    );

    await p12AssetFactory.connect(admin).unpause();
    await expect(p12AssetFactory.connect(developer1).createAssetAndMint(collection.address, 10, 'ipfs://'))
      .to.emit(p12AssetFactory, 'SftCreated')
      .withArgs(collection.address, 1, 10);
  });

  it('Should developer1 update metadata uri successfully', async () => {
    await expect(p12AssetFactory.connect(developer1).updateSftUri(collection.address, 0, 'ar://'))
      .to.emit(collection, 'SetUri')
      .withArgs(0, 'ar://');

    expect(await collection.uri(0)).to.be.equal('ar://');

    await expect(p12AssetFactory.connect(developer2).updateSftUri(collection.address, 0, 'ar://')).to.be.revertedWith(
      'P12AssetF: not game developer',
    );
  });
});
