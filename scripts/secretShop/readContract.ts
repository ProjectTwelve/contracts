import { ethers } from 'hardhat';

async function main() {
  const p12exchange = await ethers.getContractAt('SecretShopUpgradable', '0x2B1525d4BaBC614A4F309b1256650aB7602d780A');

  console.log(
    await p12exchange.inventoryStatus('0x8a6f8cbaec95b73225b6715d3901f8bdcbe072dcaa5a440215388597c1a8cf9e'),
    await p12exchange.inventoryStatus('0x175ef199cd0c11f9751e03f8a616fef80a88ff2b6d5ea0c20b73e63f7d83cd18'),
  );
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
