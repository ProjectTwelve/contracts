import { ethers } from 'hardhat';

async function main() {
  const developer = (await ethers.getSigners())[1];

  const p12AssetFactory = await ethers.getContractAt('P12AssetFactoryUpgradable', '0x839A28f16c5ebFA8E4693e9b068325477E7f268B');
  console.log('p12AssetFactory: ', p12AssetFactory.address);

  const p12factory = await ethers.getContractAt('P12V0FactoryStorage', '0x395FAbef71433280f85f79ad43f99E3cC040af5C');

  console.log(await p12factory.allGames('1001'));
  console.log(developer.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
