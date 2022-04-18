// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
import { ethers, upgrades } from 'hardhat';

async function main() {
  const developer = (await ethers.getSigners())[1];

  const p12AssetFactoryAddr = '0x839A28f16c5ebFA8E4693e9b068325477E7f268B';

  const p12AssetFactory = await ethers.getContractAt('P12AssetFactoryUpgradable', p12AssetFactoryAddr);

  /* cSpell:disable */
  await p12AssetFactory.connect(developer).createCollection('1001', 'ipfs://QmU9qevD5dbj4Mpret5ZqYL2FWh8yov2tZmAFgRNBkBjCA');
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
