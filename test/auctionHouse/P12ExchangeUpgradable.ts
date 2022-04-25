import { expect } from 'chai';
import { ethers, upgrades } from 'hardhat';
import { AuctionHouseUpgradable, P12AssetDemo, ERC1155Delegate, P12Token } from '../../typechain';
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';
import { Contract, utils } from 'ethers';
import * as compiledWETH from 'canonical-weth/build/contracts/WETH9.json';

describe('AuctionHouseUpgradable', function () {
  let p12exchange: Contract;
  let developer: SignerWithAddress;
  let user1: SignerWithAddress;
  let user2: SignerWithAddress;
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
      { name: 'dataMask', type: 'bytes' },
      { name: 'length', type: 'uint256' },
      { name: 'items', type: 'OrderItem[]' },
    ],
  };

  this.beforeAll(async () => {
    // distribute account
    const accounts = await ethers.getSigners();
    developer = accounts[0];
    user1 = accounts[1];
    user2 = accounts[2];

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
    p12asset.mint(user1.address, 0, 1, []);
    expect(await p12asset.balanceOf(user1.address, 0)).to.be.equal(1);
  });

  it('Should AuctionHouseUpgradable Deploy successfully', async function () {
    const AuctionHouseUpgradableF = await ethers.getContractFactory('AuctionHouseUpgradable');
    p12exchange = await upgrades.deployProxy(AuctionHouseUpgradableF, [0, weth.address], {
      kind: 'uups',
    });
  });
  it('Should ERC1155 Delegate Deploy successfully', async function () {
    const ERC1155DelegateF = await ethers.getContractFactory('ERC1155Delegate');
    erc1155delegate = await ERC1155DelegateF.deploy();
    // Give Role to exchange contract
    await erc1155delegate.grantRole(await erc1155delegate.DELEGATION_CALLER(), p12exchange.address);

    // Give Role to developer
    await erc1155delegate.grantRole(await erc1155delegate.DELEGATION_CALLER(), developer.address);

    // Add delegate
    await (
      await ethers.getContractAt('AuctionHouseUpgradable', p12exchange.address)
    ).updateDelegates([erc1155delegate.address], []);
  });
  it('Should Delegator transfer token successfully', async function () {
    // approve
    await p12asset.connect(user1).setApprovalForAll(erc1155delegate.address, true);

    const data = [
      {
        token: p12asset.address,
        tokenId: BigInt(0),
        amount: BigInt(1),
        salt: 0n,
      },
    ];

    const dd = utils.defaultAbiCoder.encode(['tuple(address token, uint256 tokenId, uint256 amount, uint256 salt)[]'], [data]);

    await erc1155delegate.executeSell(user1.address, user2.address, dd);

    expect(await p12asset.balanceOf(user1.address, 0)).to.be.equal(0);
    expect(await p12asset.balanceOf(user2.address, 0)).to.be.equal(1);
  });

  it('Should sell successfully', async function () {
    const data = [
      {
        token: p12asset.address,
        tokenId: BigInt(0),
        amount: BigInt(1),
        salt: 0n,
      },
    ];

    const domain = {
      name: 'P12 AuctionHouse',
      version: '1.0.0',
      chainId: 44102,
      verifyingContract: p12exchange.address,
    };

    const orderPreInfo = {
      salt: BigInt(0),
      user: user2.address,
      network: BigInt(44102),
      intent: BigInt(1),
      delegateType: BigInt(1),
      deadline: BigInt(new Date().getTime() + 100),
      currency: p12coin.address,
      dataMask: '0x0000000000000000000000000000000000000000000000000000000000000000',
    };

    const items = [
      {
        price: 10n * 10n ** 18n,
        data: utils.defaultAbiCoder.encode(['tuple(address token, uint256 tokenId, uint256 amount, uint256 salt)[]'], [data]),
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
                  { name: 'dataMask', type: 'bytes' },
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
      salt: 0n,
      user: user1.address,
      deadline: BigInt(new Date().getTime() + 100),
      amountToEth: 0n,
      amountToWeth: 0n,
      canFail: false,
    };

    const SettleDetail = {
      op: 1n,
      orderIdx: 0n,
      itemIdx: 0n,
      price: 10n * 10n ** 18n,
      itemHash: itemHash,
      executionDelegate: erc1155delegate.address,
      dataReplacement: '0x0000000000000000000000000000000000000000000000000000000000000000',
      fees: [],
    };

    // Buyer approve coin
    await p12coin.connect(user1).approve(p12exchange.address, SettleDetail.price);

    // seller approve
    await p12asset.connect(user2).setApprovalForAll(erc1155delegate.address, true);

    await (await ethers.getContractAt('AuctionHouseUpgradable', p12exchange.address)).connect(user1).run({
      orders: [Order],
      details: [SettleDetail],
      shared: SettleShared,
    });

    expect(await p12asset.balanceOf(user1.address, 0)).to.be.equal(1);
    expect(await p12asset.balanceOf(user2.address, 0)).to.be.equal(0);
    expect(await p12coin.balanceOf(user1.address)).to.be.equal(90n * 10n ** 18n);
    expect(await p12coin.balanceOf(user2.address)).to.be.equal(110n * 10n ** 18n);
  });
  it('should cancel order successfully', async () => {
    const data = [
      {
        token: p12asset.address,
        tokenId: BigInt(0),
        amount: BigInt(1),
        salt: 1n,
      },
    ];

    const domain = {
      name: 'P12 AuctionHouse',
      version: '1.0.0',
      chainId: 44102,
      verifyingContract: p12exchange.address,
    };

    const orderPreInfo = {
      salt: BigInt(0),
      user: user1.address,
      network: BigInt(44102),
      intent: BigInt(1),
      delegateType: BigInt(1),
      deadline: BigInt(new Date().getTime() + 100),
      currency: p12coin.address,
      dataMask: '0x0000000000000000000000000000000000000000000000000000000000000000',
    };

    const items = [
      {
        price: 10n * 10n ** 18n,
        data: utils.defaultAbiCoder.encode(['tuple(address token, uint256 tokenId, uint256 amount, uint256 salt)[]'], [data]),
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
                  { name: 'dataMask', type: 'bytes' },
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
      salt: 0n,
      user: user2.address,
      deadline: BigInt(new Date().getTime() + 100),
      amountToEth: 0n,
      amountToWeth: 0n,
      canFail: false,
    };

    const SettleDetail = {
      op: 1n,
      orderIdx: 0n,
      itemIdx: 0n,
      price: 10n * 10n ** 18n,
      itemHash: itemHash,
      executionDelegate: erc1155delegate.address,
      dataReplacement: '0x0000000000000000000000000000000000000000000000000000000000000000',
      fees: [],
    };

    // Buyer approve coin
    await p12coin.connect(user2).approve(p12exchange.address, SettleDetail.price);

    // seller approve
    await p12asset.connect(user1).setApprovalForAll(erc1155delegate.address, true);

    // other cancel
    expect(
      (await ethers.getContractAt('AuctionHouseUpgradable', p12exchange.address)).connect(user2).run({
        orders: [Order],
        details: [{ ...SettleDetail, op: 3n }],
        shared: { ...SettleShared, user: user2.address },
      }),
    ).to.be.revertedWith('AuctionHouse: no permit to cancel');

    // seller cancel
    await (await ethers.getContractAt('AuctionHouseUpgradable', p12exchange.address)).connect(user1).run({
      orders: [Order],
      details: [{ ...SettleDetail, op: 3n }],
      shared: { ...SettleShared, user: user1.address },
    });

    expect(
      (await ethers.getContractAt('AuctionHouseUpgradable', p12exchange.address)).connect(user2).run({
        orders: [Order],
        details: [SettleDetail],
        shared: SettleShared,
      }),
    ).to.be.revertedWith('AuctionHouse: this item sold or canceled');

    expect(await p12asset.balanceOf(user1.address, 0)).to.be.equal(1);
    expect(await p12asset.balanceOf(user2.address, 0)).to.be.equal(0);
    expect(await p12coin.balanceOf(user1.address)).to.be.equal(90n * 10n ** 18n);
    expect(await p12coin.balanceOf(user2.address)).to.be.equal(110n * 10n ** 18n);
  });

  it('Should upgrade successfully', async () => {
    const AuctionHouseAlter = await ethers.getContractFactory('AuctionHouseUpgradableAlternative');

    const p12ExchangeAlter = await upgrades.upgradeProxy(p12exchange.address, AuctionHouseAlter);

    await p12ExchangeAlter.setName('Project Twelve');
    expect(await p12ExchangeAlter.getName()).to.be.equal('Project Twelve');
  });
});
