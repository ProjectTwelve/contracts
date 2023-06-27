import { expect } from 'chai';
import { ethers } from 'hardhat';
import { P12AssetDemo, ERC721Demo, P12Asset } from '../../typechain-types';
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';
import { utils } from 'ethers';
import { genSalt } from './utils';
import { fixtureAll, EconomyContract, ExternalContract } from '../../scripts/deploy';

describe('SecretShopUpgradable', function () {
  let developer: SignerWithAddress;
  let user1: SignerWithAddress;
  let user2: SignerWithAddress;
  let passerby: SignerWithAddress;
  let recipient: SignerWithAddress;
  let p12asset: P12AssetDemo;
  let erc721demo: ERC721Demo;
  let core: EconomyContract & ExternalContract;

  const ERC721DataType = 'tuple(uint256 salt, address token, uint256 tokenId)[]';
  const ERC1155DataType = 'tuple(uint256 salt, address token, uint256 tokenId, uint256 amount)[]';

  const EIP721TypeEncoded = ethers.utils.ParamType.from({
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
  });

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
    [developer, user1, user2, recipient, passerby] = await ethers.getSigners();

    core = await fixtureAll();

    // grant role

    // mint p12Token
    await core.p12Token.mint(user1.address, 100n * 10n ** 18n);
    await core.p12Token.mint(user2.address, 100n * 10n ** 18n);

    // deploy ERC721
    const ERC721DemoF = await ethers.getContractFactory('ERC721Demo');
    erc721demo = (await ERC721DemoF.deploy()) as ERC721Demo;

    // mint ERC721
    await erc721demo.safeMint(user1.address, 0, []);
    expect(await erc721demo.ownerOf(0)).to.be.equal(user1.address);

    // deploy ERC1155
    const P12AssetDemoF = await ethers.getContractFactory('P12AssetDemo');
    p12asset = (await P12AssetDemoF.deploy()) as P12Asset;

    // mint ERC1155
    await p12asset.mint(user2.address, 0, 1, []);
    expect(await p12asset.balanceOf(user2.address, 0)).to.be.equal(1);

    // update EIP-712 verifyingContract address
    domain.verifyingContract = core.p12SecretShop.address;
  });

  it('should transfer ownership successfully', async () => {
    await p12asset.transferOwnership(Buffer.from(ethers.utils.randomBytes(20)).toString('hex'), false);

    await expect(p12asset.connect(passerby).claimOwnership()).to.be.revertedWith('NoPermission');

    await p12asset.transferOwnership(passerby.address, false);

    await expect(p12asset.connect(passerby).mint(passerby.address, 3, 1, '0x')).to.be.revertedWith('NoPermission');

    await p12asset.connect(passerby).claimOwnership();
    await p12asset.connect(passerby).mint(passerby.address, 3, 1, '0x');
    expect(await p12asset.balanceOf(passerby.address, 3)).to.be.equal(1);
  });

  it('Should Delegator transfer token successfully', async function () {
    // approve
    await p12asset.connect(user1).setApprovalForAll(core.erc1155delegate.address, true);
    const erc1155Data = [
      {
        salt: genSalt(),
        token: p12asset.address,
        tokenId: BigInt(0),
        amount: BigInt(1),
      },
    ];
    const dd = utils.defaultAbiCoder.encode([ERC1155DataType], [erc1155Data]);

    const dc = await core.erc1155delegate.DELEGATION_CALLER();
    await expect(core.erc1155delegate.executeSell(user1.address, user2.address, dd)).to.be.revertedWith(
      `AccessControl: account ${developer.address.toLowerCase()} is missing role ${dc}`,
    );
  });

  it('should update fee cap successfully', async function () {
    expect(await core.p12SecretShop.feeCapPct()).to.equal(10n ** 5n);

    // update feeCap
    await core.p12SecretShop.connect(developer).updateFeeCap(11n ** 5n);

    expect(await core.p12SecretShop.feeCapPct()).to.equal(11n ** 5n);
  });

  it('should change delegates successfully', async function () {
    expect(await core.p12SecretShop.delegates(core.erc1155delegate.address)).to.equal(true);

    // delete and then add
    await core.p12SecretShop.updateDelegates([], [core.erc1155delegate.address]);
    expect(await core.p12SecretShop.delegates(core.erc1155delegate.address)).to.equal(false);
    await core.p12SecretShop.updateDelegates([core.erc1155delegate.address], []);
    expect(await core.p12SecretShop.delegates(core.erc1155delegate.address)).to.equal(true);
  });

  it('Should sell erc1155 successfully', async function () {
    // prepare for tx erc1155Data
    const erc1155Data = [
      {
        salt: genSalt(),
        token: p12asset.address,
        tokenId: BigInt(0),
        amount: BigInt(1),
      },
    ];

    const orderInfo = {
      salt: genSalt(),
      user: user2.address,
      network: BigInt(44102),
      intent: BigInt(1),
      delegateType: BigInt(1),
      deadline: BigInt(new Date().getTime() + 100),
      currency: core.p12Token.address,
    };

    const items = [
      {
        price: 10n * 10n ** 18n,
        data: utils.defaultAbiCoder.encode([ERC1155DataType], [erc1155Data]),
      },
    ];

    const signature = await user2._signTypedData(domain, types, {
      ...orderInfo,
      length: items.length,
      items: items,
    });

    const Order = {
      ...orderInfo,
      items: items,
      r: '0x' + signature.slice(2, 66),
      s: '0x' + signature.slice(66, 130),
      v: '0x' + signature.slice(130, 132),
      signVersion: '0x01',
    };

    // verify signature
    expect(await core.p12SecretShop.verifyOrderSignature(Order)).to.be.equal(true);
    const fakeV = Order.v === '0x1b' ? '0x1c' : '0x1b';
    expect(await core.p12SecretShop.verifyOrderSignature({ ...Order, v: fakeV })).to.be.equal(false);

    const itemHash = utils.keccak256(
      '0x' + utils.defaultAbiCoder.encode([EIP721TypeEncoded], [{ ...orderInfo, item: items[0] }]).slice(66),
    );

    const SettleShared = {
      salt: genSalt(),
      user: user1.address,
      deadline: BigInt(new Date().getTime() + 100),
      canFail: false,
    };

    const SettleDetail = {
      op: 1n,
      orderIdx: 0n,
      itemIdx: 0n,
      price: 10n * 10n ** 18n,
      itemHash: itemHash,
      executionDelegate: core.erc1155delegate.address,
      fees: [{ percentage: 10000n, to: recipient.address }],
    };

    // Buyer approve coin
    await core.p12Token.connect(user1).approve(core.p12SecretShop.address, SettleDetail.price);

    // seller approve
    await p12asset.connect(user2).setApprovalForAll(core.erc1155delegate.address, true);

    // delete p12 from whitelist first and then add
    await core.p12SecretShop.connect(developer).updateCurrencies([], [core.p12Token.address]);

    // not allowed currency should fail
    await expect(
      core.p12SecretShop.connect(user1).run({
        orders: [Order],
        details: [SettleDetail],
        shared: SettleShared,
      }),
    ).to.be.revertedWith('NotWhiteCurrency');

    await core.p12SecretShop.connect(developer).updateCurrencies([core.p12Token.address, ethers.constants.AddressZero], []);

    // wrong sig version should fail
    await expect(
      core.p12SecretShop.connect(user1).run({
        orders: [{ ...Order, signVersion: '0x02' }],
        details: [SettleDetail],
        shared: SettleShared,
      }),
    ).to.be.revertedWith('SignatureVersionNotMatch');

    // run order
    await core.p12SecretShop.connect(user1).run({
      orders: [Order],
      details: [SettleDetail],
      shared: SettleShared,
    });

    // run order but allow failure
    await expect(
      core.p12SecretShop.connect(user1).run({
        orders: [Order],
        details: [SettleDetail],
        shared: { ...SettleShared, canFail: true },
      }),
    )
      .to.emit(core.p12SecretShop, 'EvFailure')
      .withArgs(0, core.p12SecretShop.interface.encodeErrorResult('ItemNotListed', [SettleDetail.itemHash]));

    expect(await p12asset.balanceOf(user1.address, 0)).to.be.equal(1);
    expect(await p12asset.balanceOf(user2.address, 0)).to.be.equal(0);
    expect(await core.p12Token.balanceOf(user1.address)).to.be.equal(90n * 10n ** 18n);
    expect(await core.p12Token.balanceOf(user2.address)).to.be.equal(1099n * 10n ** 17n);
    expect(await core.p12Token.balanceOf(recipient.address)).to.be.equal(1n * 10n ** 17n);
  });

  it('Should sell erc721 successfully', async () => {
    // prepare for erc721Data
    const erc721Data = [
      {
        salt: genSalt(),
        token: erc721demo.address,
        tokenId: BigInt(0),
      },
    ];

    const orderInfo = {
      salt: genSalt(),
      user: user1.address,
      network: BigInt(44102),
      intent: BigInt(1),
      delegateType: BigInt(2),
      deadline: BigInt(new Date().getTime() + 100),
      currency: core.p12Token.address,
    };

    const items = [
      {
        price: 10n * 10n ** 18n,
        data: utils.defaultAbiCoder.encode([ERC721DataType], [erc721Data]),
      },
    ];

    const signature = await user1._signTypedData(domain, types, {
      ...orderInfo,
      length: items.length,
      items: items,
    });

    const Order = {
      ...orderInfo,
      items: items,
      r: '0x' + signature.slice(2, 66),
      s: '0x' + signature.slice(66, 130),
      v: '0x' + signature.slice(130, 132),
      signVersion: '0x01',
    };

    const itemHash = utils.keccak256(
      '0x' + utils.defaultAbiCoder.encode([EIP721TypeEncoded], [{ ...orderInfo, item: items[0] }]).slice(66),
    );

    const SettleShared = {
      salt: genSalt(),
      user: user2.address,
      deadline: BigInt(new Date().getTime() + 100),
      canFail: false,
    };

    const SettleDetail = {
      op: 1n,
      orderIdx: 0n,
      itemIdx: 0n,
      price: 10n * 10n ** 18n,
      itemHash: itemHash,
      executionDelegate: core.erc721delegate.address,
      fees: [],
    };

    // Buyer approve coin
    await core.p12Token.connect(user2).approve(core.p12SecretShop.address, SettleDetail.price);

    // seller approve
    await erc721demo.connect(user1).setApprovalForAll(core.erc721delegate.address, true);

    // run order
    await core.p12SecretShop.connect(user2).run({
      orders: [Order],
      details: [SettleDetail],
      shared: SettleShared,
    });

    expect(await erc721demo.ownerOf(0)).to.be.equal(user2.address);

    expect(await core.p12Token.balanceOf(user1.address)).to.be.equal(100n * 10n ** 18n);
    expect(await core.p12Token.balanceOf(user2.address)).to.be.equal(999n * 10n ** 17n);
  });

  it('Should sell via native token successfully', async () => {
    // prepare for tx erc1155Data
    const erc1155Data = [
      {
        salt: genSalt(),
        token: p12asset.address,
        tokenId: BigInt(0),
        amount: BigInt(1),
      },
    ];

    const orderInfo = {
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
        data: utils.defaultAbiCoder.encode([ERC1155DataType], [erc1155Data]),
      },
    ];

    const signature = await user1._signTypedData(domain, types, {
      ...orderInfo,
      length: items.length,
      items: items,
    });

    const Order = {
      ...orderInfo,
      items: items,
      r: '0x' + signature.slice(2, 66),
      s: '0x' + signature.slice(66, 130),
      v: '0x' + signature.slice(130, 132),
      signVersion: '0x01',
    };

    const itemHash = utils.keccak256(
      '0x' + utils.defaultAbiCoder.encode([EIP721TypeEncoded], [{ ...orderInfo, item: items[0] }]).slice(66),
    );

    const SettleShared = {
      salt: genSalt(),
      user: user2.address,
      deadline: BigInt(new Date().getTime() + 100),
      canFail: true,
    };

    const SettleDetail = {
      op: 1n,
      orderIdx: 0n,
      itemIdx: 0n,
      price: 1n * 10n ** 18n,
      itemHash: itemHash,
      executionDelegate: core.erc1155delegate.address,
      fees: [],
    };

    // seller approve
    await p12asset.connect(user1).setApprovalForAll(core.erc1155delegate.address, true);

    const user1BalanceBefore = await user1.getBalance();
    const user2BalanceBefore = await user2.getBalance();

    // run order
    await core.p12SecretShop.connect(user2).run(
      {
        orders: [Order],
        details: [SettleDetail],
        shared: SettleShared,
      },
      { value: ethers.utils.parseEther('7.0') },
    );

    // run order but allow failure
    await expect(
      core.p12SecretShop.connect(user2).run(
        {
          orders: [Order],
          details: [SettleDetail],
          shared: { ...SettleShared, canFail: true },
        },
        { value: ethers.utils.parseEther('4.0') },
      ),
    )
      .to.emit(core.p12SecretShop, 'EvFailure')
      .withArgs(0, core.p12SecretShop.interface.encodeErrorResult('ItemNotListed', [SettleDetail.itemHash]));

    // disallow native token, which cause a failure
    await core.p12SecretShop.updateCurrencies([], [ethers.constants.AddressZero]);
    await expect(
      core.p12SecretShop.connect(user2).run(
        {
          orders: [Order],
          details: [SettleDetail],
          shared: { ...SettleShared, canFail: true },
        },
        { value: ethers.utils.parseEther('4.0') },
      ),
    )
      .to.emit(core.p12SecretShop, 'EvFailure')
      .withArgs(0, core.p12SecretShop.interface.encodeErrorResult('NotWhiteCurrency'));

    expect(await ethers.provider.getBalance(core.p12SecretShop.address)).to.be.equal(0);
    expect(await user1.getBalance()).to.be.equal(user1BalanceBefore.add(ethers.utils.parseEther('1')));
    expect(await user2.getBalance()).to.be.lte(user2BalanceBefore.sub(ethers.utils.parseEther('1'))); // due to gas
    expect(await user2.getBalance()).to.be.gte(user2BalanceBefore.sub(ethers.utils.parseEther('1.1')));

    expect(await p12asset.balanceOf(user1.address, 0)).to.be.equal(0);
    expect(await p12asset.balanceOf(user2.address, 0)).to.be.equal(1);
  });

  it('should cancel order successfully', async () => {
    const erc1155Data = [
      {
        salt: genSalt(),
        token: p12asset.address,
        tokenId: BigInt(0),
        amount: BigInt(1),
      },
    ];

    const domain = {
      name: 'P12 SecretShop',
      version: '1.0.0',
      chainId: 44102,
      verifyingContract: core.p12SecretShop.address,
    };

    const orderInfo = {
      salt: genSalt(),
      user: user1.address,
      network: BigInt(44102),
      intent: BigInt(1),
      delegateType: BigInt(1),
      deadline: BigInt(new Date().getTime() + 100),
      currency: core.p12Token.address,
    };

    const items = [
      {
        price: 10n * 10n ** 18n,
        data: utils.defaultAbiCoder.encode([ERC1155DataType], [erc1155Data]),
      },
    ];

    const signature = await user1._signTypedData(domain, types, {
      ...orderInfo,
      length: items.length,
      items: items,
    });

    const Order = {
      ...orderInfo,
      items: items,
      r: '0x' + signature.slice(2, 66),
      s: '0x' + signature.slice(66, 130),
      v: '0x' + signature.slice(130, 132),
      signVersion: '0x01',
    };

    const itemHash = utils.keccak256(
      '0x' + utils.defaultAbiCoder.encode([EIP721TypeEncoded], [{ ...orderInfo, item: items[0] }]).slice(66),
    );

    const SettleShared = {
      salt: genSalt(),
      user: user2.address,
      deadline: BigInt(new Date().getTime() + 100),
      canFail: false,
    };

    const SettleDetail = {
      op: 1n,
      orderIdx: 0n,
      itemIdx: 0n,
      price: 10n * 10n ** 18n,
      itemHash: itemHash,
      executionDelegate: core.erc1155delegate.address,
      fees: [],
    };

    // Buyer approve coin
    await core.p12Token.connect(user2).approve(core.p12SecretShop.address, SettleDetail.price);

    // seller approve
    await p12asset.connect(user1).setApprovalForAll(core.erc1155delegate.address, true);

    // other cancel
    await expect(
      core.p12SecretShop.connect(user2).run({
        orders: [Order],
        details: [{ ...SettleDetail, op: 3n }],
        shared: { ...SettleShared, user: user2.address },
      }),
    ).to.be.revertedWith('SenderNotMatch');

    // seller cancel
    await (await ethers.getContractAt('SecretShopUpgradable', core.p12SecretShop.address)).connect(user1).run({
      orders: [Order],
      details: [{ ...SettleDetail, op: 3n }],
      shared: { ...SettleShared, user: user1.address },
    });

    await expect(
      core.p12SecretShop.connect(user2).run({
        orders: [Order],
        details: [SettleDetail],
        shared: SettleShared,
      }),
    )
      .to.be.revertedWith('ItemNotListed')
      .withArgs(SettleDetail.itemHash);

    expect(await p12asset.balanceOf(user1.address, 0)).to.be.equal(0);
    expect(await p12asset.balanceOf(user2.address, 0)).to.be.equal(1);
    expect(await core.p12Token.balanceOf(user1.address)).to.be.equal(100n * 10n ** 18n);
    expect(await core.p12Token.balanceOf(user2.address)).to.be.equal(999n * 10n ** 17n);
    expect(await core.p12Token.balanceOf(recipient.address)).to.be.equal(1n * 10n ** 17n);

    // check pauseable
    await core.p12SecretShop.connect(developer).pause();

    await expect(
      core.p12SecretShop.connect(user2).run({
        orders: [Order],
        details: [SettleDetail],
        shared: SettleShared,
      }),
    ).to.be.revertedWith('Pausable: paused');

    await core.p12SecretShop.connect(developer).unpause();

    await expect(
      core.p12SecretShop.connect(user2).run({
        orders: [Order],
        details: [SettleDetail],
        shared: SettleShared,
      }),
    )
      .to.be.revertedWith('ItemNotListed')
      .withArgs(SettleDetail.itemHash);
  });

  it('Should seller accept buyer buying erc1155 successfully', async function () {
    // prepare for tx erc1155Data
    const erc1155Data = [
      {
        salt: genSalt(),
        token: p12asset.address,
        tokenId: BigInt(0),
        amount: BigInt(1),
      },
    ];

    const orderInfo = {
      salt: genSalt(),
      user: user1.address,
      network: BigInt(44102),
      intent: BigInt(2),
      delegateType: BigInt(1),
      deadline: BigInt(new Date().getTime() + 100),
      currency: core.p12Token.address,
    };

    const items = [
      {
        price: 10n * 10n ** 18n,
        data: utils.defaultAbiCoder.encode([ERC1155DataType], [erc1155Data]),
      },
    ];

    const signature = await user1._signTypedData(domain, types, {
      ...orderInfo,
      length: items.length,
      items: items,
    });

    const Order = {
      ...orderInfo,
      items: items,
      r: '0x' + signature.slice(2, 66),
      s: '0x' + signature.slice(66, 130),
      v: '0x' + signature.slice(130, 132),
      signVersion: '0x01',
    };

    const itemHash = utils.keccak256(
      '0x' + utils.defaultAbiCoder.encode([EIP721TypeEncoded], [{ ...orderInfo, item: items[0] }]).slice(66),
    );

    const SettleShared = {
      salt: genSalt(),
      user: user2.address,
      deadline: BigInt(new Date().getTime() + 100),
      canFail: false,
    };

    const SettleDetail = {
      op: 2n,
      orderIdx: 0n,
      itemIdx: 0n,
      price: 10n * 10n ** 18n,
      itemHash: itemHash,
      executionDelegate: core.erc1155delegate.address,
      fees: [{ percentage: 10000n, to: recipient.address }],
    };

    // Buyer approve coin
    await core.p12Token.connect(user1).approve(core.p12SecretShop.address, SettleDetail.price);

    // seller approve
    await p12asset.connect(user2).setApprovalForAll(core.erc1155delegate.address, true);

    await core.p12SecretShop.connect(developer).updateCurrencies([core.p12Token.address, ethers.constants.AddressZero], []);

    // wrong sig version should fail
    await expect(
      core.p12SecretShop.connect(user2).run({
        orders: [{ ...Order, signVersion: '0x02' }],
        details: [SettleDetail],
        shared: SettleShared,
      }),
    ).to.be.revertedWith('SignatureVersionNotMatch');

    // run order
    await core.p12SecretShop.connect(user2).run({
      orders: [Order],
      details: [SettleDetail],
      shared: SettleShared,
    });

    // run order but allow failure
    await expect(
      core.p12SecretShop.connect(user2).run({
        orders: [Order],
        details: [SettleDetail],
        shared: { ...SettleShared, canFail: true },
      }),
    )
      .to.emit(core.p12SecretShop, 'EvFailure')
      .withArgs(0, core.p12SecretShop.interface.encodeErrorResult('ItemNotListed', [SettleDetail.itemHash]));

    expect(await p12asset.balanceOf(user1.address, 0)).to.be.equal(1);
    expect(await p12asset.balanceOf(user2.address, 0)).to.be.equal(0);
    expect(await core.p12Token.balanceOf(user1.address)).to.be.equal(90n * 10n ** 18n);
    expect(await core.p12Token.balanceOf(user2.address)).to.be.equal(1098n * 10n ** 17n);
    expect(await core.p12Token.balanceOf(recipient.address)).to.be.equal(2n * 10n ** 17n);

    // Should upgrade successfully
    const SecretShopAlterF = await ethers.getContractFactory('SecretShopUpgradableAlter');

    const newImplementation = await SecretShopAlterF.deploy();

    await core.p12SecretShop.upgradeTo(newImplementation.address);

    core.p12SecretShop = await ethers.getContractAt('SecretShopUpgradableAlter', core.p12SecretShop.address);
    // trigger revert failure log
    // run order but allow failure
    await expect(
      core.p12SecretShop.connect(user2).run({
        orders: [Order],
        details: [SettleDetail],
        shared: { ...SettleShared, canFail: true },
      }),
    )
      .to.emit(core.p12SecretShop, 'EvFailure')
      .withArgs(0, '0x');
  });
});
