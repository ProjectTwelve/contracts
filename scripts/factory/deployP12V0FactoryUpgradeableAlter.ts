import { ethers } from 'hardhat';

async function main() {
  // this for rinkeby test
  const P12factory = await ethers.getContractFactory('P12V0FactoryUpgradeableAlter');
  const p12factory = await P12factory.deploy();
  console.log('P12factory address : ', p12factory.address);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
