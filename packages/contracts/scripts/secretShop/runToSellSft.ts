// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
import { ethers } from 'hardhat';
import { utils } from 'ethers';

async function main() {
  const p12coin = await ethers.getContractAt('P12Coin', '0xeAc1F044C4b9B7069eF9F3eC05AC60Df76Fe6Cd0');
  const weth = await ethers.getContractAt('WETH9', '0x0EE3F0848cA07E6342390C34FcC7Ea9D0217a47d');
  console.log('weth: ', weth.address);

  const p12asset = await ethers.getContractAt('P12AssetDemo', '0x4944655508A93A6Be7FfF9e6eF82cFb36630052F');

  const p12exchange = await ethers.getContractAt('SecretShopUpgradable', '0x2B1525d4BaBC614A4F309b1256650aB7602d780A');

  const erc1155delegate = await ethers.getContractAt('ERC1155Delegate', '0x2004560E5ad60298640F7Fe20Fabe4B82A622592');

  // user1 is seller user2 is buyer
  const [user1, user2] = await ethers.getSigners();

  const data = [
    {
      token: p12asset.address,
      tokenId: BigInt(0),
      amount: BigInt(1),
      salt: BigInt(Date.now()),
    },
  ];

  const domain = {
    name: 'P12 SecretShop',
    version: '1.0.0',
    chainId: 44010,
    verifyingContract: p12exchange.address,
  };

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

  const orderPreInfo = {
    salt: BigInt(Date.now()),
    user: user1.address,
    network: BigInt(44010),
    intent: BigInt(1),
    delegateType: BigInt(1),
    deadline: 1648656000n,
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
    salt: BigInt(Date.now()),
    user: user2.address,
    deadline: 1648656000n,
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

  await (await ethers.getContractAt('SecretShopUpgradable', p12exchange.address)).connect(user2).run({
    orders: [Order],
    details: [SettleDetail],
    shared: SettleShared,
    r: '0x0000000000000000000000000000000000000000000000000000000000000000',
    s: '0x0000000000000000000000000000000000000000000000000000000000000000',
    v: '0x00',
  });
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
