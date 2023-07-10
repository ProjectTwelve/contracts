// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
import env, { ethers, upgrades } from 'hardhat';

async function main() {
  if (env.network.name === 'p12TestNet') {
    const developer = (await ethers.getSigners())[0];

    const p12coin = await ethers.getContractAt('P12Token', '0xeAc1F044C4b9B7069eF9F3eC05AC60Df76Fe6Cd0');
    console.log('P12 Coin: ', p12coin.address);
    const wethAddr = '0x0EE3F0848cA07E6342390C34FcC7Ea9D0217a47d';

    const SecretShopUpgradableF = await ethers.getContractFactory('SecretShopUpgradable');

    const secretShop = await upgrades.deployProxy(SecretShopUpgradableF, [10n ** 5n, wethAddr], {
      kind: 'uups',
    });
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
