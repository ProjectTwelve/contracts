import { expect } from 'chai';
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';
import { ethers } from 'hardhat';
import { deployAll, EconomyContract, ExternalContract } from '../../scripts/deploy';

describe('gaugeController', function () {
  let admin: SignerWithAddress;
  let user: SignerWithAddress;
  let core: EconomyContract & ExternalContract;
  let testGaugeAddress: string;
  this.beforeAll(async function () {
    // hardhat test accounts
    const accounts = await ethers.getSigners();
    admin = accounts[0];
    user = accounts[2];
    core = await deployAll();
  });

  it('show add gauge successfully', async function () {
    testGaugeAddress = ethers.Wallet.createRandom().address;
    await core.gaugeController.addGauge(testGaugeAddress, 0, 0);
  });

  it('show type weight', async function () {
    const weight = await core.gaugeController.getTypeWeight(0);
    expect(weight).to.be.equal(1n * 10n ** 18n);
  });
  it('show gauge weight', async function () {
    const testGaugeAddress = ethers.Wallet.createRandom().address;
    const weight = await core.gaugeController.getGaugeWeight(testGaugeAddress);
    expect(weight).to.be.equal(0);
  });

  it('show change gauge weight successfully', async function () {
    await core.gaugeController.changeGaugeWeight(user.address, 100);
    const weight = await core.gaugeController.getGaugeWeight(user.address);
    expect(weight).to.be.equal(100);
  });

  it('show total weight', async function () {
    const weight = await core.gaugeController.getTotalWeight();
    expect(weight).to.be.equal(0n * 10n ** 18n);
  });
  it('show change type  weight successfully', async function () {
    await core.gaugeController.changeTypeWeight(0, 1n * 10n ** 16n);
    const weight = await core.gaugeController.getTypeWeight(0);
    expect(weight).to.be.equal(1n * 10n ** 16n);
  });

  it('show gauge relative weight successfully', async function () {
    let timestampBefore = (await ethers.provider.getBlock(await ethers.provider.getBlockNumber())).timestamp;
    await ethers.provider.send('evm_mine', [timestampBefore + 86400 * 7]);
    timestampBefore = (await ethers.provider.getBlock(await ethers.provider.getBlockNumber())).timestamp;
    await core.gaugeController.gaugeRelativeWeightWrite(admin.address, timestampBefore);
  });

  it('Should pausable effective', async function () {
    await core.gaugeController.pause();
    await expect(core.gaugeController.voteForGaugeWeights(user.address, 400)).to.be.revertedWith('Pausable: paused');
    await core.gaugeController.unpause();
  });

  it('show checkpoint successfully', async function () {
    await core.gaugeController.checkpoint();
  });

  it('show get weights sum per type successfully', async function () {
    expect(await core.gaugeController.getWeightsSumPerType(0)).to.be.equal(0);
    await core.gaugeController.checkpointGauge(testGaugeAddress);
    expect(await core.gaugeController.getWeightsSumPerType(0)).to.be.equal(0);
  });

  // change admin
  it('show change admin successfully', async function () {
    await core.gaugeController.transferOwnership(user.address, true);
    const addr = await core.gaugeController.owner();
    expect(addr).to.be.equal(user.address);
  });
});
