import { ethers } from 'hardhat';

async function main() {
  const ERC20 = await ethers.getContractFactory('P12Token');
  const P12 = await ERC20.attach('0xd1190C53dFF162242EE5145cFb1C28dA75B921f3');
  // const owner = await ethers.getSigners();
  await P12.mint('0xF6BF8603D8ce7e094e06E49582a0A2eCCB0E7340', 50000000n * 10n ** 18n);
  // p12 address 0x2844B158Bcffc0aD7d881a982D464c0ce38d8086
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
