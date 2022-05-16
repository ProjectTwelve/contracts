// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
import env, { ethers, upgrades } from 'hardhat';

async function main() {
  if (env.network.name === 'rinkeby') {
    const developer = (await ethers.getSigners())[0];
    console.log('developer: ', developer.address);

    const p12factoryAddr = '0xA2C44E2d4DEC9B9e9C1AA2e508eD645EE3AE8dF7';

    const P12AssetFactoryUpgradableF = await ethers.getContractFactory('P12AssetFactoryUpgradable');
    const p12AssetFactoryAddr = await upgrades.deployProxy(P12AssetFactoryUpgradableF, [p12factoryAddr], {
      kind: 'uups',
    });
    const p12AssetFactory = await ethers.getContractAt('P12AssetFactoryUpgradable', p12AssetFactoryAddr.address);
    console.log('p12AssetFactory proxy: ', p12AssetFactory.address);
  }
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
