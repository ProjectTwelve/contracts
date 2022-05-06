import { expect } from 'chai';
import { ethers, upgrades } from 'hardhat';
import { SecretShopUpgradable, P12AssetDemo, ERC1155Delegate, P12Token } from '../../typechain';
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';
import { Contract, utils } from 'ethers';
import * as compiledWETH from 'canonical-weth/build/contracts/WETH9.json';
import { Salt } from './utils';

describe('SecretShopUpgradable', function () {
  let secretShopForDeploy: Contract;
  let secretShop: SecretShopUpgradable;
  let developer: SignerWithAddress;
  let user1: SignerWithAddress;
  let user2: SignerWithAddress;
  let recipient: SignerWithAddress;
  let weth: Contract;
  let p12coin: P12Token;
  let p12asset: P12AssetDemo;
  let erc1155delegate: ERC1155Delegate;

  const types = {
    OrderItem: [
      { name: 'price', type: 'uint256' },
      { name: 'data', type: 'bytes' },
    ],
    Order: [
      { name: 'salt', type: 'uint256' },
      { name: 'user', type: 'address' },
      { name: 'network', type: 'uint256' },
      { name: 'intent', type: 'uint256' },
      { name: 'delegateType', type: 'uint256' },
      { name: 'deadline', type: 'uint256' },
      { name: 'currency', type: 'address' },
      { name: 'length', type: 'uint256' },
      { name: 'items', type: 'OrderItem[]' },
    ],
  };

  // EIP-712 domain
  const domain = {
    name: 'P12 SecretShop',
    version: '1.0.0',
    chainId: 44102,
    verifyingContract: '',
  };

  this.beforeAll(async () => {
    // distribute account
    const accounts = await ethers.getSigners();
    developer = accounts[0];
    user1 = accounts[1];
    user2 = accounts[2];
    recipient = accounts[3];

    // deploy WETH
    const WETH = new ethers.ContractFactory(compiledWETH.abi, compiledWETH.bytecode, developer);
    weth = await WETH.deploy();

    // deploy p12 coin
    const P12CoinF = await ethers.getContractFactory('P12Token');
    p12coin = await P12CoinF.deploy('Project Twelve', 'P12', 0n);

    // mint p12 Coin
    await p12coin.mint(user1.address, 100n * 10n ** 18n);
    await p12coin.mint(user2.address, 100n * 10n ** 18n);
    expect(await p12coin.balanceOf(user1.address)).to.be.equal(100n * 10n ** 18n);
    expect(await p12coin.balanceOf(user2.address)).to.be.equal(100n * 10n ** 18n);

    // deploy ERC1155
    const P12AssetDemoF = await ethers.getContractFactory('P12AssetDemo');
    p12asset = await P12AssetDemoF.deploy();

    // mint ERC1155
    await p12asset.mint(user1.address, 0, 1, []);
    expect(await p12asset.balanceOf(user1.address, 0)).to.be.equal(1);

    // mint this tokenId just for transfer to Delegator
    await p12asset.mint(user1.address, 1, 2, []);
    expect(await p12asset.balanceOf(user1.address, 1)).to.be.equal(2);
  });

  it('Should SecretShopUpgradable Deploy successfully', async function () {
    const SecretShopUpgradableF = await ethers.getContractFactory('SecretShopUpgradable');
    secretShopForDeploy = await upgrades.deployProxy(SecretShopUpgradableF, [10n ** 5n, weth.address], {
      kind: 'uups',
    });

    secretShop = await ethers.getContractAt('SecretShopUpgradable', secretShopForDeploy.address);

    // update EIP-712 verifyingContract address
    domain.verifyingContract = secretShop.address;
  });

  it('Should ERC1155 Delegate Deploy successfully', async function () {
    const ERC1155DelegateF = await ethers.getContractFactory('ERC1155Delegate');
    erc1155delegate = await ERC1155DelegateF.deploy();

    expect(await erc1155delegate.delegateType()).to.be.equal(1);

    // trigger on received
    await p12asset.connect(user1).safeTransferFrom(user1.address, erc1155delegate.address, 1, 1, []);
    await p12asset.connect(user1).safeBatchTransferFrom(user1.address, erc1155delegate.address, [1], [1], []);
    expect(await p12asset.balanceOf(user1.address, 1)).to.be.equal(0);
    expect(await p12asset.balanceOf(erc1155delegate.address, 1)).to.be.equal(2);

    // Give Role to exchange contract
    await erc1155delegate.grantRole(await erc1155delegate.DELEGATION_CALLER(), secretShop.address);

    // Give Role to developer
    await erc1155delegate.grantRole(await erc1155delegate.DELEGATION_CALLER(), developer.address);
    await erc1155delegate.grantRole(await erc1155delegate.PAUSABLE_CALLER(), developer.address);
  });

  it('Should Delegator transfer token successfully', async function () {
    // approve
    await p12asset.connect(user1).setApprovalForAll(erc1155delegate.address, true);

    const data = [
      {
        salt: new Salt().value,
        token: p12asset.address,
        tokenId: BigInt(0),
        amount: BigInt(1),
      },
    ];

    const dd = utils.defaultAbiCoder.encode(['tuple(uint256 salt, address token, uint256 tokenId, uint256 amount)[]'], [data]);

    // should Pausable effective

    await erc1155delegate.pause();
    await expect(erc1155delegate.executeSell(user1.address, user2.address, dd)).to.be.revertedWith('Pausable: paused');
    await erc1155delegate.unpause();

    await erc1155delegate.executeSell(user1.address, user2.address, dd);
    expect(await p12asset.balanceOf(user1.address, 0)).to.be.equal(0);
    expect(await p12asset.balanceOf(user2.address, 0)).to.be.equal(1);
  });

  it('should update fee cap successfully', async function () {
    expect(await secretShop.feeCapPct()).to.equal(10n ** 5n);

    // update feeCap
    await secretShop.connect(developer).updateFeeCap(11n ** 5n);

    expect(await secretShop.feeCapPct()).to.equal(11n ** 5n);
  });

  it('should change delegates successfully', async function () {
    expect(await secretShop.delegates(erc1155delegate.address)).to.equal(false);

    // Add delegate
    await secretShop.updateDelegates([erc1155delegate.address], []);
    expect(await secretShop.delegates(erc1155delegate.address)).to.equal(true);

    // delete and then add
    await secretShop.updateDelegates([], [erc1155delegate.address]);
    expect(await secretShop.delegates(erc1155delegate.address)).to.equal(false);
    await secretShop.updateDelegates([erc1155delegate.address], []);
    expect(await secretShop.delegates(erc1155delegate.address)).to.equal(true);
  });

  it('Should sell successfully', async function () {
    // prepare for tx data
    const data = [
      {
        salt: new Salt().value,
        token: p12asset.address,
        tokenId: BigInt(0),
        amount: BigInt(1),
      },
    ];

    const orderPreInfo = {
      salt: new Salt().value,
      user: user2.address,
      network: BigInt(44102),
      intent: BigInt(1),
      delegateType: BigInt(1),
      deadline: BigInt(new Date().getTime() + 100),
      currency: p12coin.address,
    };

    const items = [
      {
        price: 10n * 10n ** 18n,
        data: utils.defaultAbiCoder.encode(['tuple(uint256 salt, address token, uint256 tokenId, uint256 amount)[]'], [data]),
      },
    ];

    const signature = await user2._signTypedData(domain, types, {
      ...orderPreInfo,
      length: items.length,
      items: items,
    });

    const Order = {
      ...orderPreInfo,
      items: items,
      r: '0x' + signature.slice(2, 66),
      s: '0x' + signature.slice(66, 130),
      v: '0x' + signature.slice(130, 132),
      signVersion: '0x01',
    };

    const itemHash = utils.keccak256(
      '0x' +
        utils.defaultAbiCoder
          .encode(
            [
              ethers.utils.ParamType.from({
                type: 'tuple',
                name: 'order',
                components: [
                  { name: 'salt', type: 'uint256' },
                  { name: 'user', type: 'address' },
                  { name: 'network', type: 'uint256' },
                  { name: 'intent', type: 'uint256' },
                  { name: 'delegateType', type: 'uint256' },
                  { name: 'deadline', type: 'uint256' },
                  { name: 'currency', type: 'address' },
                  {
                    name: 'item',
                    type: 'tuple',
                    components: [
                      { name: 'price', type: 'uint256' },
                      { name: 'data', type: 'bytes' },
                    ],
                  },
                ],
              }),
            ],
            [{ ...orderPreInfo, item: items[0] }],
          )
          .slice(66),
    );

    const SettleShared = {
      salt: new Salt().value,
      user: user1.address,
      deadline: BigInt(new Date().getTime() + 100),
      amountToEth: 0n,
      canFail: false,
    };

    const SettleDetail = {
      op: 1n,
      orderIdx: 0n,
      itemIdx: 0n,
      price: 10n * 10n ** 18n,
      itemHash: itemHash,
      executionDelegate: erc1155delegate.address,
      fees: [{ percentage: 10000n, to: recipient.address }],
    };

    // Buyer approve coin
    await p12coin.connect(user1).approve(secretShop.address, SettleDetail.price);

    // seller approve
    await p12asset.connect(user2).setApprovalForAll(erc1155delegate.address, true);

    // not allowed currency should fail
    await expect(
      secretShop.connect(user1).run({
        orders: [Order],
        details: [SettleDetail],
        shared: SettleShared,
      }),
    ).to.be.revertedWith('SecretShop: wrong currency');

    await secretShop.connect(developer).updateCurrencies([p12coin.address, ethers.constants.AddressZero], []);

    // wrong op should fail
    await expect(
      secretShop.connect(user1).run({
        orders: [Order],
        details: [{ ...SettleDetail, op: 2n }],
        shared: SettleShared,
      }),
    ).to.be.revertedWith('SecretShop: unknown op');

    // wrong sig version should fail
    await expect(
      secretShop.connect(user1).run({
        orders: [{ ...Order, signVersion: '0x02' }],
        details: [SettleDetail],
        shared: SettleShared,
      }),
    ).to.be.revertedWith('SecretShop: wrong sig version');

    // run order
    await secretShop.connect(user1).run({
      orders: [Order],
      details: [SettleDetail],
      shared: SettleShared,
    });

    // run order but allow failure
    await expect(
      secretShop.connect(user1).run({
        orders: [Order],
        details: [SettleDetail],
        shared: { ...SettleShared, canFail: true },
      }),
    )
      .to.emit(secretShop, 'EvFailure')
      .withArgs(0, utils.hexValue(utils.toUtf8Bytes('SecretShop: sold or canceled')));

    expect(await p12asset.balanceOf(user1.address, 0)).to.be.equal(1);
    expect(await p12asset.balanceOf(user2.address, 0)).to.be.equal(0);
    expect(await p12coin.balanceOf(user1.address)).to.be.equal(90n * 10n ** 18n);
    expect(await p12coin.balanceOf(user2.address)).to.be.equal(1099n * 10n ** 17n);
    expect(await p12coin.balanceOf(recipient.address)).to.be.equal(1n * 10n ** 17n);
  });

  it('Should sell use native token successfully', async () => {
    // prepare for tx data
    const data = [
      {
        salt: new Salt().value,
        token: p12asset.address,
        tokenId: BigInt(0),
        amount: BigInt(1),
      },
    ];

    const orderPreInfo = {
      salt: BigInt(0),
      user: user1.address,
      network: BigInt(44102),
      intent: BigInt(1),
      delegateType: BigInt(1),
      deadline: BigInt(new Date().getTime() + 100),
      // use eth
      currency: ethers.constants.AddressZero,
    };

    const items = [
      {
        price: 1n * 10n ** 18n,
        data: utils.defaultAbiCoder.encode(['tuple(uint256 salt, address token, uint256 tokenId, uint256 amount)[]'], [data]),
      },
    ];

    const signature = await user1._signTypedData(domain, types, {
      ...orderPreInfo,
      length: items.length,
      items: items,
    });

    const Order = {
      ...orderPreInfo,
      items: items,
      r: '0x' + signature.slice(2, 66),
      s: '0x' + signature.slice(66, 130),
      v: '0x' + signature.slice(130, 132),
      signVersion: '0x01',
    };

    const itemHash = utils.keccak256(
      '0x' +
        utils.defaultAbiCoder
          .encode(
            [
              ethers.utils.ParamType.from({
                type: 'tuple',
                name: 'order',
                components: [
                  { name: 'salt', type: 'uint256' },
                  { name: 'user', type: 'address' },
                  { name: 'network', type: 'uint256' },
                  { name: 'intent', type: 'uint256' },
                  { name: 'delegateType', type: 'uint256' },
                  { name: 'deadline', type: 'uint256' },
                  { name: 'currency', type: 'address' },
                  {
                    name: 'item',
                    type: 'tuple',
                    components: [
                      { name: 'price', type: 'uint256' },
                      { name: 'data', type: 'bytes' },
                    ],
                  },
                ],
              }),
            ],
            [{ ...orderPreInfo, item: items[0] }],
          )
          .slice(66),
    );

    const SettleShared = {
      salt: new Salt().value,
      user: user2.address,
      deadline: BigInt(new Date().getTime() + 100),
      amountToEth: 2n,
      canFail: true,
    };

    const SettleDetail = {
      op: 1n,
      orderIdx: 0n,
      itemIdx: 0n,
      price: 1n * 10n ** 18n,
      itemHash: itemHash,
      executionDelegate: erc1155delegate.address,
      fees: [],
    };

    // seller approve
    await p12asset.connect(user1).setApprovalForAll(erc1155delegate.address, true);

    const user1BalanceBefore = await user1.getBalance();
    const user2BalanceBefore = await user2.getBalance();

    // run order
    await secretShop.connect(user2).run(
      {
        orders: [Order],
        details: [SettleDetail],
        shared: SettleShared,
      },
      { value: ethers.utils.parseEther('1.0') },
    );

    // run order but allow failure
    await expect(
      secretShop.connect(user2).run(
        {
          orders: [Order],
          details: [SettleDetail],
          shared: { ...SettleShared, canFail: true },
        },
        { value: ethers.utils.parseEther('2.0') },
      ),
    )
      .to.emit(secretShop, 'EvFailure')
      .withArgs(0, utils.hexValue(utils.toUtf8Bytes('SecretShop: sold or canceled')));

    // disallow native token, which cause a failure
    await secretShop.updateCurrencies([], [ethers.constants.AddressZero]);
    await expect(
      secretShop.connect(user2).run(
        {
          orders: [Order],
          details: [SettleDetail],
          shared: { ...SettleShared, canFail: true },
        },
        { value: ethers.utils.parseEther('2.0') },
      ),
    )
      .to.emit(secretShop, 'EvFailure')
      .withArgs(0, utils.hexValue(utils.toUtf8Bytes('SecretShop: wrong currency')));

    expect(await user1.getBalance()).to.be.equal(user1BalanceBefore.add(ethers.utils.parseEther('1')));
    expect(await user2.getBalance()).to.be.lte(user2BalanceBefore.sub(ethers.utils.parseEther('1'))); // due to gas
  });

  it('should cancel order successfully', async () => {
    const data = [
      {
        salt: new Salt().value,
        token: p12asset.address,
        tokenId: BigInt(0),
        amount: BigInt(1),
      },
    ];

    const domain = {
      name: 'P12 SecretShop',
      version: '1.0.0',
      chainId: 44102,
      verifyingContract: secretShop.address,
    };

    const orderPreInfo = {
      salt: new Salt().value,
      user: user1.address,
      network: BigInt(44102),
      intent: BigInt(1),
      delegateType: BigInt(1),
      deadline: BigInt(new Date().getTime() + 100),
      currency: p12coin.address,
    };

    const items = [
      {
        price: 10n * 10n ** 18n,
        data: utils.defaultAbiCoder.encode(['tuple(uint256 salt, address token, uint256 tokenId, uint256 amount)[]'], [data]),
      },
    ];

    const signature = await user1._signTypedData(domain, types, {
      ...orderPreInfo,
      length: items.length,
      items: items,
    });

    const Order = {
      ...orderPreInfo,
      items: items,
      r: '0x' + signature.slice(2, 66),
      s: '0x' + signature.slice(66, 130),
      v: '0x' + signature.slice(130, 132),
      signVersion: '0x01',
    };

    const itemHash = utils.keccak256(
      '0x' +
        utils.defaultAbiCoder
          .encode(
            [
              ethers.utils.ParamType.from({
                type: 'tuple',
                name: 'order',
                components: [
                  { name: 'salt', type: 'uint256' },
                  { name: 'user', type: 'address' },
                  { name: 'network', type: 'uint256' },
                  { name: 'intent', type: 'uint256' },
                  { name: 'delegateType', type: 'uint256' },
                  { name: 'deadline', type: 'uint256' },
                  { name: 'currency', type: 'address' },
                  {
                    name: 'item',
                    type: 'tuple',
                    components: [
                      { name: 'price', type: 'uint256' },
                      { name: 'data', type: 'bytes' },
                    ],
                  },
                ],
              }),
            ],
            [{ ...orderPreInfo, item: items[0] }],
          )
          .slice(66),
    );

    const SettleShared = {
      salt: new Salt().value,
      user: user2.address,
      deadline: BigInt(new Date().getTime() + 100),
      amountToEth: 0n,
      canFail: false,
    };

    const SettleDetail = {
      op: 1n,
      orderIdx: 0n,
      itemIdx: 0n,
      price: 10n * 10n ** 18n,
      itemHash: itemHash,
      executionDelegate: erc1155delegate.address,
      fees: [],
    };

    // Buyer approve coin
    await p12coin.connect(user2).approve(secretShop.address, SettleDetail.price);

    // seller approve
    await p12asset.connect(user1).setApprovalForAll(erc1155delegate.address, true);

    // other cancel
    await expect(
      secretShop.connect(user2).run({
        orders: [Order],
        details: [{ ...SettleDetail, op: 3n }],
        shared: { ...SettleShared, user: user2.address },
      }),
    ).to.be.revertedWith('SecretShop: no permit cancel');

    // seller cancel
    await (await ethers.getContractAt('SecretShopUpgradable', secretShop.address)).connect(user1).run({
      orders: [Order],
      details: [{ ...SettleDetail, op: 3n }],
      shared: { ...SettleShared, user: user1.address },
    });

    await expect(
      secretShop.connect(user2).run({
        orders: [Order],
        details: [SettleDetail],
        shared: SettleShared,
      }),
    ).to.be.revertedWith('SecretShop: sold or canceled');

    expect(await p12asset.balanceOf(user1.address, 0)).to.be.equal(0);
    expect(await p12asset.balanceOf(user2.address, 0)).to.be.equal(1);
    expect(await p12coin.balanceOf(user1.address)).to.be.equal(90n * 10n ** 18n);
    expect(await p12coin.balanceOf(user2.address)).to.be.equal(1099n * 10n ** 17n);
    expect(await p12coin.balanceOf(recipient.address)).to.be.equal(1n * 10n ** 17n);

    // check pauseable
    await secretShop.connect(developer).pause();

    await expect(
      secretShop.connect(user2).run({
        orders: [Order],
        details: [SettleDetail],
        shared: SettleShared,
      }),
    ).to.be.revertedWith('Pausable: paused');

    await secretShop.connect(developer).unpause();

    await expect(
      secretShop.connect(user2).run({
        orders: [Order],
        details: [SettleDetail],
        shared: SettleShared,
      }),
    ).to.be.revertedWith('SecretShop: sold or canceled');

    // Should upgrade successfully
    const SecretShopAlterF = await ethers.getContractFactory('SecretShopUpgradableAlternative');

    const secretShopAlter = await upgrades.upgradeProxy(secretShop.address, SecretShopAlterF);

    await secretShopAlter.setName('Project Twelve');
    expect(await secretShopAlter.getName()).to.be.equal('Project Twelve');

    // trigger revert failure log
    // run order but allow failure
    await expect(
      secretShopAlter.connect(user2).run({
        orders: [Order],
        details: [SettleDetail],
        shared: { ...SettleShared, canFail: true },
      }),
    )
      .to.emit(secretShopAlter, 'EvFailure')
      .withArgs(0, '0x');
  });
});
