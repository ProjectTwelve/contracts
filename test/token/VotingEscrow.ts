import { expect } from 'chai';
import { ethers } from 'hardhat';
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';
import { fixtureAll, EconomyContract, ExternalContract } from '../../scripts/deploy';

describe('VotingEscrow', function () {
  let core: EconomyContract & ExternalContract;
  let test: SignerWithAddress;
  this.beforeAll(async function () {
    // hardhat test accounts
    const accounts = await ethers.getSigners();
    test = accounts[1];
    core = await fixtureAll();
  });
  it('transfer p12Token to test account successfully', async function () {
    await core.p12Token.transfer(test.address, 100n * 10n ** 18n);
    expect(await core.p12Token.balanceOf(test.address)).to.be.equal(100n * 10n ** 18n);
  });
  it('should create a locker successfully', async function () {
    await core.p12Token.connect(test).approve(core.votingEscrow.address, 100n * 10n ** 18n);
    core.votingEscrow.connect(test).createLock(100n * 10n ** 18n, 1689849796);
    expect((await core.votingEscrow.locked(test.address)).amount).to.be.equal(100n * 10n ** 18n);
  });
  it('withdraw p12Token Emergency successfully', async function () {
    await expect(core.votingEscrow.connect(test).expire()).to.be.revertedWith('SafeOwnable: caller not owner');
    await expect(core.votingEscrow.connect(test).withdraw()).to.be.revertedWith('VotingEscrow: condition not met');
    await core.votingEscrow.expire();
    await core.votingEscrow.connect(test).withdraw();
    expect(await core.p12Token.balanceOf(test.address)).to.be.equal(100n * 10n ** 18n);
    expect((await core.votingEscrow.locked(test.address)).amount).to.be.equal(0);
  });
});
