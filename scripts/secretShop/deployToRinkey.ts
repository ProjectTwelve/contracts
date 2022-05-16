// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
import env, { ethers, upgrades } from 'hardhat';

async function main() {
  if (env.network.name === 'rinkeby') {
    const developer = (await ethers.getSigners())[0];

    const p12coin = await ethers.getContractAt('P12Token', '0x2844B158Bcffc0aD7d881a982D464c0ce38d8086');
    const wethAddr = '0xc778417e063141139fce010982780140aa0cd5ab';

    const SecretShopUpgradableF = await ethers.getContractFactory('SecretShopUpgradable');

    const secretShop = await upgrades.deployProxy(SecretShopUpgradableF, [10n ** 5n, wethAddr], {
      kind: 'uups',
    });

    console.log('SecretShop Proxy', secretShop.address);
    const ERC1155DelegateF = await ethers.getContractFactory('ERC1155Delegate');
    const erc1155delegate = await ERC1155DelegateF.deploy();
    // Give delegate role to exchange contract
    await erc1155delegate.grantRole(await erc1155delegate.DELEGATION_CALLER(), secretShop.address);
    // Give pausable Role to developer
    await erc1155delegate.grantRole(await erc1155delegate.PAUSABLE_CALLER(), developer.address);
    // Add delegate
    await (
      await ethers.getContractAt('SecretShopUpgradable', secretShop.address)
    ).updateDelegates([erc1155delegate.address], []);
    // Add WhiteList
    await (await ethers.getContractAt('SecretShopUpgradable', secretShop.address)).updateCurrencies([p12coin.address], []);
  }
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
