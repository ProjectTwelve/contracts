// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
import { ethers, upgrades } from 'hardhat';

async function main() {
  const developer = (await ethers.getSigners())[0];
  console.log('developer: ', developer.address);

  const p12factoryAddr = '0x395FAbef71433280f85f79ad43f99E3cC040af5C';

  const P12AssetFactoryUpgradableF = await ethers.getContractFactory('P12AssetFactoryUpgradable');
  const p12AssetFactoryAddr = await upgrades.deployProxy(P12AssetFactoryUpgradableF, [p12factoryAddr], {
    kind: 'uups',
  });
  const p12AssetFactory = await ethers.getContractAt('P12AssetFactoryUpgradable', p12AssetFactoryAddr.address);
  console.log('p12AssetFactory: ', p12AssetFactory.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
