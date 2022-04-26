import { expect } from 'chai';
import { ethers } from 'hardhat';
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';
import { P12V0ERC20 } from '../../typechain';

const gameCoinIconUrl =
  'https://images.weserv.nl/?url=https://i0.hdslb.com/bfs/article/87c5b43b19d4065f837f54637d3932e680af9c9b.jpg';
const gameId = '1101';

describe('P12V0ERC20', function () {
  let gameCoin: P12V0ERC20;
  let owner: SignerWithAddress;
  let address1: SignerWithAddress;

  beforeEach(async function () {
    const P12V0ERC20 = await ethers.getContractFactory('P12V0ERC20');
    gameCoin = await P12V0ERC20.deploy('testGameCoin001', 'GC001', gameId, gameCoinIconUrl, 200n * 10n ** 18n);
    await gameCoin.connect(owner).deployed();

    [owner, address1] = await ethers.getSigners();
  });

  it('should view successfully', async () => {
    expect(await gameCoin.gameId()).to.be.equal('1101');
    expect(await gameCoin.gameCoinIconUrl()).to.be.equal(gameCoinIconUrl);
  });

  it('Should deploy success', async function () {
    // console.log('success!');
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
