import { expect } from 'chai';
import { Contract } from 'ethers';
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';
import { ethers, upgrades } from 'hardhat';

describe('GaugeControllerUpgradeable', function () {
  let p12: Contract;
  let votingEscrow: Contract;
  let admin: SignerWithAddress;
  let user: SignerWithAddress;
  let gaugeController: Contract;

  this.beforeAll(async function () {
    // hardhat test accounts
    const accounts = await ethers.getSigners();
    admin = accounts[0];
    user = accounts[2];
  });
  // deploy p12 token
  it('Should show p12 token deploy successfully!', async function () {
    // deploy p12token
    const ERC20 = await ethers.getContractFactory('P12Token');
    p12 = await ERC20.deploy('ProjectTwelve', 'P12', 1000n * 10n ** 18n);
    expect(await p12.balanceOf(admin.address)).to.be.equal(1000n * 10n ** 18n);

    await p12.transfer(user.address, 300n * 10n ** 18n);
    expect(await p12.balanceOf(user.address)).to.be.equal(300n * 10n ** 18n);
  });

  // deploy votingEscrow
  it('should show deploy votingEscrow successfully', async function () {
    const VotingEscrow = await ethers.getContractFactory('VotingEscrow');
    votingEscrow = await VotingEscrow.deploy(p12.address, 'VeP12', 'veP12');
  });

  // lock p12
  it('it show create locker successfully', async function () {
    const value = 200n * 10n ** 18n;
    await p12.approve(votingEscrow.address, value);
    await votingEscrow.createLock(value, 1684976703);
    const unlockTime = Math.floor(1684976703 / (86400 * 7)) * (86400 * 7);
    const slope = value / BigInt(365 * 86400 * 4);
    const timestamp = (await ethers.provider.getBlock(await ethers.provider.getBlockNumber())).timestamp;
    const bias = slope * BigInt(unlockTime - timestamp);
    expect(await votingEscrow.balanceOf(admin.address)).to.be.equal(bias);

    await p12.connect(user).approve(votingEscrow.address, 300n * 10n ** 18n);
    await votingEscrow.connect(user).createLock(300n * 10n ** 18n, 1684976703);
  });
  // deploy GaugeController
  it('show GaugeController deploy successfully', async function () {
    const GaugeController = await ethers.getContractFactory('GaugeControllerUpgradeable');
    gaugeController = await upgrades.deployProxy(GaugeController, [admin.address, votingEscrow.address], { kind: 'uups' });
  });

  // add type and gauge
  it('show add type and gauge successfully', async function () {
    await gaugeController.addType('liquidity', 1n * 10n ** 18n);
    await gaugeController.addGauge(user.address, 0, 1);
    await gaugeController.addGauge(admin.address, 0, 1);
    expect(await gaugeController.getGaugeTypes(user.address)).to.be.equal(0);
  });

  it('show type weight', async function () {
    const weight = await gaugeController.getTypeWeight(0);
    expect(weight).to.be.equal(1n * 10n ** 18n);
  });
  it('show gauge weight', async function () {
    const weight = await gaugeController.getGaugeWeight(user.address);
    expect(weight).to.be.equal(1);
  });

  it('show change gauge weight successfully', async function () {
    await gaugeController.changeGaugeWeight(user.address, 100);
    const weight = await gaugeController.getGaugeWeight(user.address);
    expect(weight).to.be.equal(100);
  });

  it('show total weight', async function () {
    const weight = await gaugeController.getTotalWeight();
    expect(weight).to.be.equal(101n * 10n ** 18n);
  });
  it('show change type  weight successfully', async function () {
    await gaugeController.changeTypeWeight(0, 1n * 10n ** 16n);
    const weight = await gaugeController.getTypeWeight(0);
    expect(weight).to.be.equal(1n * 10n ** 16n);
  });

  it('show gauge relative weight successfully', async function () {
    let timestampBefore = (await ethers.provider.getBlock(await ethers.provider.getBlockNumber())).timestamp;
    await ethers.provider.send('evm_mine', [timestampBefore + 86400 * 7]);
    timestampBefore = (await ethers.provider.getBlock(await ethers.provider.getBlockNumber())).timestamp;
    await gaugeController.gaugeRelativeWeightWrite(admin.address, timestampBefore);
  });

  it('Should pausable effective', async function () {
    await gaugeController.pause();
    await expect(gaugeController.voteForGaugeWeights(user.address, 400)).to.be.revertedWith('Pausable: paused');
    await gaugeController.unpause();
  });

  it('show checkpoint successfully', async function () {
    await gaugeController.checkpoint();
  });

  it('show get weights sum per type successfully', async function () {
    expect(await gaugeController.getWeightsSumPerType(0)).to.be.equal(101);
    await gaugeController.checkpointGauge(ethers.constants.AddressZero);
  });

  // change admin
  it('show change admin successfully', async function () {
    await gaugeController.commitTransferOwnership(user.address);
    await gaugeController.applyTransferOwnership();
    const addr = await gaugeController.admin();
    expect(addr).to.be.equal(user.address);
  });
});
