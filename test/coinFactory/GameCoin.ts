import { expect } from 'chai';
import { ethers } from 'hardhat';
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';
import { P12GameCoin } from '../../typechain-types';

const gameCoinIconUrl =
  'https://images.weserv.nl/?url=https://i0.hdslb.com/bfs/article/87c5b43b19d4065f837f54637d3932e680af9c9b.jpg';
const gameId = '1101';

describe('P12GameCoin', function () {
  let gameCoin: P12GameCoin;
  let owner: SignerWithAddress;
  let address1: SignerWithAddress;

  beforeEach(async function () {
    [owner, address1] = await ethers.getSigners();

    const P12GameCoin = await ethers.getContractFactory('P12GameCoin');
    gameCoin = (await P12GameCoin.deploy(
      owner.address,
      'testGameCoin001',
      'GC001',
      gameId,
      gameCoinIconUrl,
      200n * 10n ** 18n,
    )) as P12GameCoin;
    await gameCoin.connect(owner).deployed();
  });

  it('should view successfully', async () => {
    expect(await gameCoin.gameId()).to.be.equal('1101');
    expect(await gameCoin.gameCoinIconUrl()).to.be.equal(gameCoinIconUrl);
  });

  it('Should update token name successfully', async function () {
    await expect(gameCoin.setName('testGameCoin002'))
      .to.be.emit(gameCoin, 'NameUpdated')
      .withArgs('testGameCoin001', 'testGameCoin002');
    expect(await gameCoin.name()).to.be.equal('testGameCoin002');
  });

  it('Should update token symbol successfully', async function () {
    await expect(gameCoin.setSymbol('GC002')).to.be.emit(gameCoin, 'SymbolUpdated').withArgs('GC001', 'GC002');
    expect(await gameCoin.symbol()).to.be.equal('GC002');
  });

  it('Should update token icon url successfully', async function () {
    await expect(gameCoin.setGameCoinIconUrl('https://example.com'))
      .to.be.emit(gameCoin, 'IconUrlUpdated')
      .withArgs(gameCoinIconUrl, 'https://example.com');
    expect(await gameCoin.gameCoinIconUrl()).to.be.equal('https://example.com');
  });

  it('Should deploy with 10000 of supply for the owner of the contract', async function () {
    // console.log(await gameCoin.decimals());
    // console.log(await gameCoin.totalSupply());
  });

  it('transfer with game account', async function () {
    const userId = '123';
    const amount = 100n * 10n ** 18n;
    await expect(await gameCoin.connect(owner).transferWithAccount(address1.address, userId, amount))
      .to.emit(gameCoin, 'TransferWithAccount')
      .withArgs(address1.address, userId, amount);
    expect(await gameCoin.balanceOf(address1.address)).to.eq(amount);
  });
});
